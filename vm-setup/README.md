# VM Setup — Alpine Linux + MSP430 Toolchain

Fully automated setup of an Alpine Linux 3.23 VM running the MSP430 GCC toolchain, using QEMU directly on macOS (Apple Silicon). No interactive steps after launch.

> **Why QEMU instead of UTM?** UTM 4.7.5 crashes on macOS 26. QEMU (Homebrew) is used directly as a workaround.

---

## Prerequisites

```sh
brew install qemu
# expect is built into macOS at /usr/bin/expect
```

Ensure these files exist in `vm/` (one directory up from here):
- `msp430-dev.img` — 20 GB raw disk image (blank)
- `alpine-virt-3.23.0-aarch64.iso` — Alpine Linux ARM64 installer
- `efi_vars.fd` — 64 MB UEFI variables file (blank)

To create a blank disk and EFI vars:
```sh
cd ~/Documents/msp430-dev-vm/vm
# 20 GB sparse disk image
truncate -s 20480m msp430-dev.img
# 64 MB blank EFI vars (copy from QEMU's template)
dd if=/dev/zero of=efi_vars.fd bs=1m count=64
```

Download the Alpine ISO from:
```
https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/aarch64/
```

---

## Run the Setup

```sh
cd ~/Documents/msp430-dev-vm
chmod +x vm-setup/full-setup.sh vm-setup/alpine-install.exp
./vm-setup/full-setup.sh
```

Total runtime: **~30 minutes**. Hands-off after launch.

### What it does

| Phase | Script | Duration | What happens |
|-------|--------|----------|-------------|
| 1 | `alpine-install.exp` | ~10 min | Boots QEMU+ISO, drives `setup-alpine` interactively |
| 2 | `full-setup.sh` | ~20 min | Boots installed VM, SSHes in, runs toolchain scripts |

### Phase 2 detail

1. Generate temporary SSH keypair
2. Start VM (no ISO) in background
3. Poll SSH until available (port 5022)
4. Inject SSH public key via password auth
5. Upload `vm-setup.sh` + `install-msp430-support.sh`
6. Run `vm-setup.sh` — installs `gcc-msp430`, `msp430-libc`, `binutils-msp430` from Alpine community repo; builds `mspdebug` from source; creates `dev` user with passwordless sudo
7. Run `install-msp430-support.sh` — installs linker scripts for MSP430G2552/2553/etc.
8. Power off VM; save updated EFI vars (contains Alpine's GRUB boot entry)

---

## Boot the VM After Setup

```sh
VM=~/Documents/msp430-dev-vm/vm
/opt/homebrew/bin/qemu-system-aarch64 \
  -machine virt,highmem=on -accel hvf -cpu host -smp 2 -m 2048 \
  -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -drive if=pflash,format=raw,file="$VM/efi_vars.fd" \
  -drive file="$VM/msp430-dev.img",if=virtio,format=raw \
  -netdev user,id=net0,hostfwd=tcp::5022-:22 \
  -device virtio-net-pci,netdev=net0 -nographic &

# SSH in (root password: alpine123, or use dev user)
ssh -p 5022 -o StrictHostKeyChecking=no dev@127.0.0.1
```

---

## Script Reference

| Script | Purpose |
|--------|---------|
| `full-setup.sh` | Master orchestration script (phases 1 + 2) |
| `alpine-install.exp` | Expect script: automates `setup-alpine` over QEMU serial |
| `vm-setup.sh` | Runs inside VM: installs toolchain, creates `dev` user |
| `install-msp430-support.sh` | Runs inside VM: installs linker scripts + `devices.csv` |
| `setup-flash.sh` | Runs inside VM as `dev`: builds `libmsp430.so` for `mspdebug tilib` |
| `create-utm-vm.sh` | Legacy: creates UTM VM bundle (Debian/UTM approach, superseded) |
| `build-msp430-gcc.sh` | Legacy: builds MSP430 GCC from source (Debian approach, superseded) |

---

## Flash Support (run once, inside VM as `dev`)

The `setup-flash.sh` script builds TI's open-source MSP430 Debug Stack (`libmsp430.so`), needed for `mspdebug tilib` with the eZ-FET lite debugger on Rev 1.5 LaunchPads.

```sh
# Inside the VM:
chmod +x ~/setup-flash.sh
~/setup-flash.sh
```

USB passthrough to the VM is handled by QEMU's `-device usb-host` or via a USB/IP bridge — see the course CLAUDE.md for details.

---

*Alpine 3.23 · aarch64 · QEMU on Apple Silicon*
