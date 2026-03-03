#!/bin/bash
#==============================================================================
# full-setup.sh — Zero-touch Alpine Linux + MSP430 toolchain setup
#
# Runs entirely on macOS.  No interactive steps after launch.
# Total runtime: approximately 30 minutes.
#
# What it does:
#   Phase 1 (~10 min) — alpine-install.exp boots QEMU with the Alpine ISO and
#                        drives setup-alpine to install Alpine on the VM disk.
#   Phase 2 (~20 min) — Boots the installed VM, SSHes in, and runs the
#                        MSP430 toolchain setup scripts.
#
# Usage:
#   cd ~/Documents/msp430-dev-vm
#   chmod +x vm-setup/full-setup.sh vm-setup/alpine-install.exp
#   ./vm-setup/full-setup.sh
#==============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VM_DIR="$REPO_ROOT/vm"

QEMU=/opt/homebrew/bin/qemu-system-aarch64
DISK="$VM_DIR/msp430-dev.img"
ISO="$VM_DIR/alpine-virt-3.23.0-aarch64.iso"
UEFI_CODE=/opt/homebrew/share/qemu/edk2-aarch64-code.fd
UEFI_VARS_ORIG="$VM_DIR/efi_vars.fd"

# Temp files — cleaned up at exit
UEFI_VARS_TMP=/tmp/msp430-efi-vars.fd
SSH_KEY=/tmp/msp430-key
QEMU_PID_FILE=/tmp/msp430-qemu.pid

# SSH / VM settings
SSH_PORT=2222
ROOT_PASS=alpine123

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}WARN:${NC} $*"; }
error() { echo -e "${RED}ERROR:${NC} $*" >&2; exit 1; }
step()  { echo -e "\n${BOLD}[$1]${NC} $2"; }

# ---------------------------------------------------------------------------
# Cleanup on exit
# ---------------------------------------------------------------------------
cleanup() {
    local exit_code=$?
    if [ -f "$QEMU_PID_FILE" ]; then
        local pid
        pid=$(cat "$QEMU_PID_FILE" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            info "Stopping QEMU (PID $pid)..."
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$QEMU_PID_FILE"
    fi
    rm -f "$SSH_KEY" "${SSH_KEY}.pub" /tmp/inject-key.exp 2>/dev/null || true
    if [ $exit_code -ne 0 ]; then
        # On failure, clean up the temp EFI vars (not yet saved back to Data/).
        rm -f "$UEFI_VARS_TMP" 2>/dev/null || true
        echo -e "\n${RED}Setup failed.${NC} Check the output above for details."
    fi
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Step 0: Preflight checks
# ---------------------------------------------------------------------------
step "0/9" "Preflight checks"

[ -x "$QEMU" ] \
    || error "QEMU not found at $QEMU\n       Install with: brew install qemu"
[ -x /usr/bin/expect ] \
    || error "/usr/bin/expect not found (should be built into macOS)"
command -v ssh       >/dev/null || error "ssh not found"
command -v scp       >/dev/null || error "scp not found"
command -v ssh-keygen >/dev/null || error "ssh-keygen not found"
[ -f "$DISK" ]          || error "Disk image not found:\n  $DISK"
[ -f "$ISO" ]           || error "Alpine ISO not found:\n  $ISO"
[ -f "$UEFI_CODE" ]     || error "UEFI firmware not found:\n  $UEFI_CODE"
[ -f "$UEFI_VARS_ORIG" ] || error "EFI vars not found:\n  $UEFI_VARS_ORIG"
[ -f "$SCRIPT_DIR/alpine-install.exp" ] \
    || error "alpine-install.exp not found in $SCRIPT_DIR"
[ -f "$SCRIPT_DIR/vm-setup.sh" ] \
    || error "vm-setup.sh not found in $SCRIPT_DIR"
[ -f "$SCRIPT_DIR/install-msp430-support.sh" ] \
    || error "install-msp430-support.sh not found in $SCRIPT_DIR"

# Warn if port is already occupied (stale QEMU instance)
if /usr/bin/nc -z 127.0.0.1 $SSH_PORT 2>/dev/null; then
    warn "Port $SSH_PORT is already in use."
    warn "Kill any running QEMU with:  lsof -ti:$SSH_PORT | xargs kill"
    error "Cannot proceed while port $SSH_PORT is occupied."
fi

info "All prerequisites satisfied."
echo "  Disk      : $DISK"
echo "  ISO       : $ISO"
echo "  QEMU      : $QEMU"

# ---------------------------------------------------------------------------
# Step 1: Create a working copy of efi_vars.fd
#
# We use a copy so the original is untouched if anything fails.  Alpine's
# GRUB installer will write its boot entry into the copy during phase 1.
# After phase 2 completes successfully, we copy it back.
# ---------------------------------------------------------------------------
step "1/9" "Copying EFI vars to temp location"
cp "$UEFI_VARS_ORIG" "$UEFI_VARS_TMP"
info "EFI vars ready at $UEFI_VARS_TMP"

# ---------------------------------------------------------------------------
# Step 2: Phase 1 — Alpine Linux installation (alpine-install.exp)
# ---------------------------------------------------------------------------
step "2/9" "Phase 1 — Alpine Linux installation (~10 min)"
echo "  The expect script drives setup-alpine interactively."
echo "  QEMU console output is shown below."
echo ""

/usr/bin/expect "$SCRIPT_DIR/alpine-install.exp" "$UEFI_VARS_TMP" "$DISK" "$ISO"
info "Phase 1 complete."

# ---------------------------------------------------------------------------
# Step 3: Generate temporary SSH keypair
# ---------------------------------------------------------------------------
step "3/9" "Generating temporary SSH keypair"
rm -f "$SSH_KEY" "${SSH_KEY}.pub"
ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "msp430-setup-temp" -q
info "Keypair created: $SSH_KEY"

# ---------------------------------------------------------------------------
# Step 4: Boot VM (no ISO) in background
# ---------------------------------------------------------------------------
step "4/9" "Starting installed VM (no ISO)"

QEMU_COMMON=(
    -machine "virt,highmem=on"
    -accel hvf
    -cpu host
    -smp 2
    -m 2048
    -drive "if=pflash,format=raw,readonly=on,file=$UEFI_CODE"
    -drive "if=pflash,format=raw,file=$UEFI_VARS_TMP"
    -drive "file=$DISK,if=virtio,format=raw"
    -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22"
    -device "virtio-net-pci,netdev=net0"
    -display none
    -serial null
    -monitor none
)

# Redirect QEMU output to a log file — we communicate via SSH in phase 2,
# not the serial console, so serial can be silenced to avoid interleaving.
"$QEMU" "${QEMU_COMMON[@]}" > /tmp/msp430-qemu-boot.log 2>&1 &
QEMU_PID=$!
echo "$QEMU_PID" > "$QEMU_PID_FILE"
info "QEMU started in background (PID $QEMU_PID)"

# ---------------------------------------------------------------------------
# Step 5: Poll SSH until available (up to 3 minutes)
# ---------------------------------------------------------------------------
step "5/9" "Waiting for Alpine to boot and SSH to start"
echo -n "  "
for i in $(seq 1 36); do
    if /usr/bin/nc -z 127.0.0.1 $SSH_PORT 2>/dev/null; then
        echo ""
        break
    fi
    echo -n "."
    if [ "$i" -eq 36 ]; then
        echo ""
        error "SSH did not become available within 3 minutes."
    fi
    sleep 5
done
# Give sshd a moment to fully initialize after the port opens
sleep 3
info "SSH is accepting connections on port $SSH_PORT"

# ---------------------------------------------------------------------------
# Step 6: Inject SSH public key via password authentication
#
# Uses expect to handle the password prompt.  After this step, all
# subsequent SSH/SCP commands use key-based auth (no password needed).
# ---------------------------------------------------------------------------
step "6/9" "Injecting SSH public key"

# Write the expect script using a QUOTED heredoc so bash does NOT expand
# variables inside it.  All runtime values are passed as argv arguments,
# preventing any Tcl injection via the password or path values.
cat > /tmp/inject-key.exp << 'EXPECT_SCRIPT'
#!/usr/bin/expect -f
# Args: ssh_port  root_pass  pub_key_path
set ssh_port    [lindex $argv 0]
set root_pass   [lindex $argv 1]
set pub_key     [lindex $argv 2]
set timeout 30

# Step A: SCP the public key file to the VM
spawn scp -P $ssh_port \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    $pub_key root@127.0.0.1:/tmp/setup_key.pub
expect {
    -re {[Pp]assword: } { send "$root_pass\r"; exp_continue }
    eof                 { }
    timeout             { puts "WARN: SCP timed out"; exit 1 }
}

# Step B: Install the key on the VM via SSH
spawn ssh -p $ssh_port \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    root@127.0.0.1 \
    {mkdir -p /root/.ssh && chmod 700 /root/.ssh && cat /tmp/setup_key.pub >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && rm /tmp/setup_key.pub && echo "Key installed."}
expect {
    -re {[Pp]assword: } { send "$root_pass\r"; exp_continue }
    "Key installed."    { }
    eof                 { }
    timeout             { puts "WARN: SSH key install timed out"; exit 1 }
}
EXPECT_SCRIPT

chmod +x /tmp/inject-key.exp
/usr/bin/expect /tmp/inject-key.exp "$SSH_PORT" "$ROOT_PASS" "${SSH_KEY}.pub"
rm -f /tmp/inject-key.exp

# Verify key auth works
SSH_OPTS=(
    -p "$SSH_PORT"
    -i "$SSH_KEY"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o BatchMode=yes
    -o ConnectTimeout=10
)
if ! ssh "${SSH_OPTS[@]}" root@127.0.0.1 "echo 'Key auth OK'" 2>/dev/null; then
    error "Key-based SSH authentication failed. Check VM console output."
fi
info "SSH key authentication confirmed."

# ---------------------------------------------------------------------------
# Step 7: Upload setup scripts to VM
# ---------------------------------------------------------------------------
step "7/9" "Uploading setup scripts to VM"

SCP_OPTS=(
    -P "$SSH_PORT"
    -i "$SSH_KEY"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o BatchMode=yes
)
scp "${SCP_OPTS[@]}" \
    "$SCRIPT_DIR/vm-setup.sh" \
    "$SCRIPT_DIR/install-msp430-support.sh" \
    root@127.0.0.1:/tmp/

info "Scripts uploaded."

# ---------------------------------------------------------------------------
# Helper: SSH function with keep-alive (for long-running commands)
# ---------------------------------------------------------------------------
SSH_OPTS_LONG=(
    -p "$SSH_PORT"
    -i "$SSH_KEY"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o BatchMode=yes
    -o ServerAliveInterval=30
    -o ServerAliveCountMax=60
)

run_ssh() {
    ssh "${SSH_OPTS_LONG[@]}" root@127.0.0.1 "$@"
}

# ---------------------------------------------------------------------------
# Step 8a: Run vm-setup.sh (~15 min)
#   - Enables Alpine community repo
#   - Installs gcc-msp430, msp430-libc, binutils-msp430 (from community)
#   - Builds mspdebug from source
#   - Creates 'dev' user with passwordless sudo
#   - Configures USB udev rules
# ---------------------------------------------------------------------------
step "8a/9" "Running vm-setup.sh (~15 min)"
echo "  This installs the MSP430 GCC toolchain and builds mspdebug."
echo "  Progress is shown below."
echo ""

run_ssh "sh /tmp/vm-setup.sh"
info "vm-setup.sh complete."

# ---------------------------------------------------------------------------
# Step 8b: Run install-msp430-support.sh (<1 min)
#   - Writes linker scripts for msp430g2552, g2553, g2452, g2512, etc.
#   - Writes devices.csv so msp430-elf-gcc knows the MCU parameters
# ---------------------------------------------------------------------------
step "8b/9" "Running install-msp430-support.sh"
run_ssh "sh /tmp/install-msp430-support.sh"
info "install-msp430-support.sh complete."

# ---------------------------------------------------------------------------
# Step 9: Power off VM
# ---------------------------------------------------------------------------
step "9/9" "Powering off VM"

# poweroff causes SSH to disconnect immediately — that's expected
run_ssh "poweroff" || true

# Wait for QEMU to exit (up to 30 seconds)
info "Waiting for QEMU to exit..."
for i in $(seq 1 30); do
    if ! kill -0 "$QEMU_PID" 2>/dev/null; then
        break
    fi
    sleep 1
done

# If still running, wait properly
wait "$QEMU_PID" 2>/dev/null || true
rm -f "$QEMU_PID_FILE"

# ---------------------------------------------------------------------------
# Save updated EFI vars (now contains Alpine's GRUB boot entry)
# ---------------------------------------------------------------------------
if [ -f "$UEFI_VARS_TMP" ]; then
    cp "$UEFI_VARS_TMP" "$UEFI_VARS_ORIG"
    info "EFI vars saved with Alpine boot entry."
    rm -f "$UEFI_VARS_TMP"
fi

# ---------------------------------------------------------------------------
# Done!
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  Setup complete! Alpine + MSP430 toolchain installed.   ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Verify the toolchain works:"
echo ""
echo "  # Boot the VM:"
cat << 'VERIFY'
  VM=~/Documents/msp430-dev-vm/vm
  /opt/homebrew/bin/qemu-system-aarch64 \
    -machine virt,highmem=on -accel hvf -cpu host -smp 2 -m 2048 \
    -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd \
    -drive if=pflash,format=raw,file="$VM/efi_vars.fd" \
    -drive file="$VM/msp430-dev.img",if=virtio,format=raw \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 -nographic &

  # SSH in (password: alpine123, or use your own key):
  ssh -p 2222 -o StrictHostKeyChecking=no dev@127.0.0.1

  # Inside the VM:
  msp430-elf-gcc --version
  mspdebug --version
VERIFY
echo ""
echo "Next steps:"
echo "  1. Sync course files to VM:"
echo "     rsync -av ~/Documents/msp430-dev-vm/course/ dev@<vm-ip>:~/course/"
echo "  2. Flash firmware (requires LaunchPad USB passthrough):"
echo "     See CLAUDE.md — run setup-flash.sh inside the VM"
echo ""
