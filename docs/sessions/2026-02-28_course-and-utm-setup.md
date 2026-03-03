# Session: Course Completion + UTM VM Creation
**Date:** 2026-02-28
**Project:** MSP430G2552 Assembly Course + VM Setup

---

## What Was Done

### Course audit
All 16 lessons + capstone confirmed present: 48 exercises (ex1–3 per lesson), each with starter `.s`, `Makefile`, and complete solution. `CLAUDE.md` created with build commands, assembly conventions, peripheral patterns, and hardware notes for future Claude sessions.

### UTM headless research
- Apple's new `container` framework does **not** support USB passthrough (tracked at apple/containerization#74) — not viable for MSP430 flashing.
- UTM headless setup: use QEMU backend (Apple Virtualization backend has no USB passthrough). Hide UTM via Preferences → uncheck Dock icon, enable menu bar icon.
- `utmctl` lives at `/Applications/UTM.app/Contents/MacOS/utmctl` — symlink to `/usr/local/bin/utmctl` for convenience.

### UTM VM created
VM `msp430-dev` registered and showing `stopped` in UTM (UUID: `3E345619-2A0B-43A5-A527-B14FCC5DC3CF`).

**Specs:** QEMU backend, aarch64, `virt` machine, HVF accelerated, 2 vCPUs, 2048 MB RAM, 20 GB VirtIO disk, USB 2.0 bus passthrough, Shared/NAT networking, Alpine Linux 3.23 ISO attached.

`create-utm-vm.sh` written — required significant iteration to nail the UTM `config.plist` format (many required keys undocumented; found by reading UTM source code).

### Key UTM config.plist findings
`ConfigurationVersion` must be `4`. Required sections: `System` (Architecture, Target, CPU, CPUCount, MemorySize, CPUFlagsAdd[], CPUFlagsRemove[], ForceMulticore, JITCacheSize), `QEMU` (DebugLog, UEFIBoot, RNGDevice, BalloonDevice, TPMDevice, Hypervisor, RTCLocalTime, PS2Controller, AdditionalArguments[]), `Display[]`, `Network[]`, `Input` (UsbBusSupport, UsbSharing, MaximumUsbShare), `Sharing`, `Sound[]`, `Serial[]`.

---

## Remaining at End of Session

- Install Alpine Linux (click ▶ in UTM, run `setup-alpine`, install to `vda`)
- Create `dev` user with passwordless sudo
- Run `vm-setup.sh` (MSP430 toolchain ~25–40 min), then `install-msp430-support.sh` and `setup-flash.sh`
