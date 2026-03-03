# Session: VM Automation — Alpine Install Bugs Fixed
**Date:** 2026-03-03
**Project:** `vm-setup/` (full-setup.sh + alpine-install.exp)

---

## Context

UTM 4.7.5 crashes on macOS 26. Previous session created `create-utm-vm.sh` (UTM approach). This session pivoted to a pure QEMU automation path:

- `alpine-install.exp` — expect script that boots QEMU+ISO and drives `setup-alpine` fully unattended
- `full-setup.sh` — orchestrates phase 1 (Alpine install) + phase 2 (SSH-based toolchain setup)

---

## Bug #1: EFI Vars Wrong Size

**Error:** `qemu-system-aarch64: cfi.pflash01 device '/machine/virt.flash1' requires 67108864 bytes, pflash1 block backend provides 655360 bytes`

**Cause:** `efi_vars.fd` was 640 KB (from UTM's template). QEMU needs exactly 64 MB for the pflash1 device.

**Fix:** Recreated `vm/efi_vars.fd` as a 64 MB zeroed file.

---

## Bug #2: Alpine Install Keyboard Layout Handler Fires on Section Header

**Symptom:** Hostname set to `us` instead of `msp430`; hostname answer (`msp430`) consumed by interface prompt; interface finally accepted via re-prompt.

**Root cause:** Alpine 3.23's `setup-alpine` uses ANSI cursor positioning to draw a full-screen UI. The section header text `Keyboard layout` appears in the raw terminal stream (in the ANSI draw sequence) even though Alpine 3.23 doesn't actually prompt for keyboard layout. The expect pattern `[Kk]eyboard layout` matched the header, sending `us\r` (and a second `us\r` for variant) into the input buffer. These were consumed by the hostname and first interface prompts.

**Fix:** Removed the keyboard layout handler entirely. Alpine 3.23 removed this prompt in v3.22+.

---

## Bug #3: Mirror Pattern Double-Fires, Sending "done" as Username

**Symptom:** User "done" created during Alpine install; script stalled at password prompt for user "done"; timeout/failure.

**Root cause:** Alpine 3.23's APK Mirror UI renders the prompt text `Enter mirror number or URL: [1]` in the raw ANSI terminal stream before all menu items are displayed (as part of cursor-positioning draw). The expect pattern `Enter mirror number|mirror.*URL.*\[1\]` matched this early occurrence (sending `f\r`, setting `mirror_sent=1`), then matched again immediately when the actual prompt appeared (`mirror_sent=1` → else branch → sent `done\r`). The buffered `done\r` sat in Alpine's stdin and was consumed by the user creation prompt (`Setup a user? [no]`), creating a user named "done".

**Fix:** Removed the else branch. Alpine 3.23 doesn't need `done` — sending `f` auto-selects the fastest mirror and advances. The now-empty else just ignores spurious re-matches.

```tcl
# Before (buggy):
-re {Enter mirror number|mirror.*URL.*\[1\]} {
    if {!$mirror_sent} {
        set mirror_sent 1; send "f\r"; set timeout 360
    } else {
        send "done\r"; set timeout 60   # ← caused the problem
    }
}

# After (fixed):
-re {Enter mirror number|mirror.*URL.*\[1\]} {
    if {!$mirror_sent} {
        set mirror_sent 1; send "f\r"; set timeout 360
    }
    # else: spurious re-match — do nothing
}
```

---

## Repo Reorganization (this session)

- Moved all VM scripts to `vm-setup/` subfolder
- Updated `full-setup.sh` to find `vm/` one level up (`REPO_ROOT`)
- Created top-level `README.md` and `.gitignore`
- Removed nested `.git` from `handheld-msp430/`
- Moved session notes to `docs/sessions/`
- Created GitHub repo `aradanmn/msp430-dev-vm` and pushed

---

## Status

- `vm/msp430-dev.img` — re-zeroed (20 GB sparse), ready for fresh install
- `vm/efi_vars.fd` — 64 MB blank, correct size
- Scripts fixed, ready to re-run: `./vm-setup/full-setup.sh`
