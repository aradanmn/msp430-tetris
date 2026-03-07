#!/bin/bash
#==============================================================================
# vm.sh — Start, stop, and check status of the MSP430 dev VM
#
# Usage:
#   ./vm.sh start          # boot VM in background
#   ./vm.sh start --usb    # boot with LaunchPad USB passthrough (needs sudo)
#   ./vm.sh stop           # graceful shutdown via SSH, then kill QEMU
#   ./vm.sh status         # show whether VM is running and SSH is reachable
#   ./vm.sh ssh            # open SSH session to the VM
#==============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
VM_DIR="$REPO_ROOT/vm"

QEMU=/opt/homebrew/bin/qemu-system-aarch64
DISK="$VM_DIR/msp430-dev.img"
UEFI_CODE=/opt/homebrew/share/qemu/edk2-aarch64-code.fd
UEFI_VARS="$VM_DIR/efi_vars.fd"
PID_FILE=/tmp/msp430-qemu.pid
UEFI_VARS_RUN=/tmp/msp430-efi-vars-run.fd
SERIAL_LOG=/tmp/vm-serial.log
SSH_PORT=5022
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=3 -o BatchMode=yes"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

#------------------------------------------------------------------------------
# Helpers
#------------------------------------------------------------------------------
vm_pid() {
    # First try PID file
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null || true)
        if [ -n "$pid" ] && ps -p "$pid" >/dev/null 2>&1; then
            echo "$pid"
            return 0
        fi
    fi
    # Fallback: find qemu process by our disk image path
    local pid
    pid=$(pgrep -f "msp430-dev.img" 2>/dev/null | head -1 || true)
    if [ -n "$pid" ]; then
        echo "$pid"
        return 0
    fi
    return 1
}

ssh_reachable() {
    # nc -z only checks if the TCP port is open, but QEMU's NAT forwarding
    # opens the host port immediately — before the guest's sshd is ready.
    # Use an actual SSH connection attempt to confirm sshd is responding.
    ssh $SSH_OPTS -p "$SSH_PORT" dev@127.0.0.1 "true" 2>/dev/null
}

wait_for_ssh() {
    local max_wait=120 elapsed=0
    printf "Waiting for SSH"
    while [ $elapsed -lt $max_wait ]; do
        if ssh_reachable; then
            echo -e " ${GREEN}ready${NC}"
            return 0
        fi
        printf "."
        sleep 3
        elapsed=$((elapsed + 3))
    done
    echo -e " ${YELLOW}timeout after ${max_wait}s — try: ./vm.sh status${NC}"
    return 0
}

#------------------------------------------------------------------------------
# Commands
#------------------------------------------------------------------------------
cmd_start() {
    if pid=$(vm_pid); then
        echo -e "${YELLOW}VM is already running${NC} (PID $pid)"
        return 0
    fi

    # Preflight checks
    [ -f "$DISK" ]      || { echo -e "${RED}Disk image not found:${NC} $DISK"; exit 1; }
    [ -f "$UEFI_VARS" ] || { echo -e "${RED}EFI vars not found:${NC} $UEFI_VARS"; exit 1; }

    local usb_args=()
    if [ "${1:-}" = "--usb" ]; then
        usb_args=(-device usb-ehci,id=ehci
                  -device "usb-host,bus=ehci.0,vendorid=0x2047,productid=0x0013")
        echo -e "${BOLD}Starting VM with USB passthrough...${NC}"
        if [ "$(id -u)" -ne 0 ]; then
            echo -e "${YELLOW}USB passthrough requires sudo. Re-running with sudo...${NC}"
            exec sudo OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES "$0" start --usb
        fi
        export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
    else
        echo -e "${BOLD}Starting VM...${NC}"
    fi

    # Use a disposable copy of EFI vars — the master is never modified.
    # UEFI may rewrite boot entries during runtime; if the VM crashes or
    # drops to EFI Shell, only the disposable copy is affected.
    # Remove stale file first — may be root-owned from a previous --usb run.
    rm -f "$UEFI_VARS_RUN" 2>/dev/null || sudo rm -f "$UEFI_VARS_RUN" 2>/dev/null || true
    cp "$UEFI_VARS" "$UEFI_VARS_RUN"
    chmod 666 "$UEFI_VARS_RUN" 2>/dev/null || true

    $QEMU \
        -machine virt,highmem=on \
        -accel hvf \
        -cpu cortex-a57 \
        -smp 2 \
        -m 2048 \
        -drive if=pflash,format=raw,readonly=on,file="$UEFI_CODE" \
        -drive if=pflash,format=raw,file="$UEFI_VARS_RUN" \
        -drive file="$DISK",if=virtio,format=raw \
        -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
        -device virtio-net-pci,netdev=net0 \
        ${usb_args[@]+"${usb_args[@]}"} \
        -display none \
        -serial "file:$SERIAL_LOG" \
        -monitor none \
        -pidfile "$PID_FILE" \
        -daemonize

    # Make PID file readable by non-root so status/stop work without sudo
    chmod 644 "$PID_FILE" 2>/dev/null || true

    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null || true)
    echo -e "${GREEN}VM started${NC} (PID $pid)"
    wait_for_ssh
}

cmd_stop() {
    local pid
    if ! pid=$(vm_pid); then
        echo -e "${YELLOW}VM is not running${NC}"
        rm -f "$PID_FILE" 2>/dev/null || true
        return 0
    fi

    # Determine if we need sudo to signal this process
    local KILL="kill"
    if ! kill -0 "$pid" 2>/dev/null; then
        KILL="sudo kill"
    fi

    # Try graceful shutdown via SSH first
    if ssh_reachable; then
        echo "Sending shutdown command via SSH..."
        ssh $SSH_OPTS -p "$SSH_PORT" dev@127.0.0.1 "sudo poweroff" 2>/dev/null || true
        # Wait up to 15 seconds for QEMU to exit
        local waited=0
        while [ $waited -lt 15 ] && ps -p "$pid" >/dev/null 2>&1; do
            sleep 1
            waited=$((waited + 1))
        done
    fi

    # Force kill if still running
    if ps -p "$pid" >/dev/null 2>&1; then
        echo "Force stopping QEMU..."
        $KILL "$pid" 2>/dev/null || true
        sleep 1
    fi

    # Clean up disposable runtime files (never save EFI vars back)
    rm -f "$UEFI_VARS_RUN" 2>/dev/null || sudo rm -f "$UEFI_VARS_RUN" 2>/dev/null || true
    rm -f "$PID_FILE" 2>/dev/null || sudo rm -f "$PID_FILE" 2>/dev/null || true
    echo -e "${GREEN}VM stopped${NC}"
}

cmd_status() {
    local pid
    if pid=$(vm_pid); then
        echo -e "VM:   ${GREEN}running${NC}  (PID $pid)"
    else
        echo -e "VM:   ${RED}stopped${NC}"
        rm -f "$PID_FILE" 2>/dev/null || true
        return 0
    fi

    if ssh_reachable; then
        echo -e "SSH:  ${GREEN}reachable${NC}  (port $SSH_PORT)"
        # Show uptime — run SSH in background with a kill timer to avoid hangs
        local up=""
        ssh $SSH_OPTS -p "$SSH_PORT" dev@127.0.0.1 "uptime" > /tmp/.vm-uptime 2>/dev/null &
        local ssh_pid=$!
        ( sleep 4 && kill $ssh_pid 2>/dev/null ) &
        local timer_pid=$!
        if wait $ssh_pid 2>/dev/null; then
            up=$(cat /tmp/.vm-uptime 2>/dev/null || true)
        fi
        kill $timer_pid 2>/dev/null || true
        wait $timer_pid 2>/dev/null || true
        rm -f /tmp/.vm-uptime
        if [ -n "$up" ]; then
            echo -e "Up:   $up"
        fi
    else
        echo -e "SSH:  ${YELLOW}not reachable${NC}  (VM may still be booting)"
    fi
}

cmd_ssh() {
    if ! vm_pid >/dev/null 2>&1; then
        echo -e "${RED}VM is not running.${NC} Start it with: ./vm.sh start"
        exit 1
    fi
    exec ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -p "$SSH_PORT" dev@127.0.0.1
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------
case "${1:-}" in
    start)  cmd_start "${2:-}" ;;
    stop)   cmd_stop ;;
    status) cmd_status ;;
    ssh)    cmd_ssh ;;
    *)
        echo "Usage: $0 {start|stop|status|ssh}"
        echo ""
        echo "  start          Boot the VM in the background"
        echo "  start --usb    Boot with LaunchPad USB passthrough (needs sudo)"
        echo "  stop           Gracefully shut down the VM"
        echo "  status         Show VM and SSH status"
        echo "  ssh            Open SSH session as dev user"
        exit 1
        ;;
esac
