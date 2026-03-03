#!/bin/bash
# create-utm-vm.sh
# Creates a Debian 12 ARM64 QEMU VM in UTM for MSP430 development.
# Must be run on macOS with UTM installed.

set -e

VM_NAME="msp430-dev"
UTM_DOCS="$HOME/Library/Containers/com.utmapp.UTM/Data/Documents"
VM_DIR="$UTM_DOCS/$VM_NAME.utm"
DATA_DIR="$VM_DIR/Data"
PLIST="$VM_DIR/config.plist"

# ── Preflight ─────────────────────────────────────────────────────────────────
if [ ! -d "$UTM_DOCS" ]; then
    echo "ERROR: UTM documents directory not found. Is UTM installed?"
    exit 1
fi

if [ -d "$VM_DIR" ]; then
    echo "ERROR: VM '$VM_NAME' already exists at:"
    echo "  $VM_DIR"
    echo "Delete it first, or rename VM_NAME in this script."
    exit 1
fi

# ── Generate identifiers ──────────────────────────────────────────────────────
VM_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
DRIVE_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
ISO_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
MAC_ADDR=$(printf '52:54:00:%02x:%02x:%02x' \
    $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))

echo "=================================================="
echo "  Creating UTM VM: $VM_NAME"
echo "  UUID:  $VM_UUID"
echo "  MAC:   $MAC_ADDR"
echo "=================================================="

# ── Create bundle structure ───────────────────────────────────────────────────
mkdir -p "$DATA_DIR"
echo ""
echo "==> Bundle created at: $VM_DIR"

# ── Download Alpine Linux (virt) ARM64 ISO ────────────────────────────────────
# alpine-virt is optimized for VMs: ~60 MB, minimal, no hardware drivers.
# vm-setup.sh supports Alpine natively (installs gcc-msp430 from community repo).
ISO_BASE="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64"
echo ""
echo "==> Fetching Alpine Linux ARM64 (virt) ISO filename..."
ISO_FILE=$(curl -sL "${ISO_BASE}/" \
    | grep -oE 'alpine-virt-[0-9]+\.[0-9]+\.[0-9]+-aarch64\.iso' \
    | head -1)

if [ -z "$ISO_FILE" ]; then
    echo "ERROR: Could not determine current Alpine virt ISO filename."
    echo "Check: ${ISO_BASE}/"
    rm -rf "$VM_DIR"
    exit 1
fi

ISO_DEST="$DATA_DIR/$ISO_FILE"

# Reuse ISO if already downloaded
if [ -f "$HOME/Downloads/$ISO_FILE" ]; then
    echo "==> Found $ISO_FILE in ~/Downloads — copying..."
    cp "$HOME/Downloads/$ISO_FILE" "$ISO_DEST"
else
    echo "==> Downloading $ISO_FILE (~60 MB)..."
    curl -L --progress-bar "${ISO_BASE}/${ISO_FILE}" -o "$ISO_DEST"
fi

echo "==> ISO ready."

# ── Create 20 GB disk image ───────────────────────────────────────────────────
echo ""
echo "==> Creating 20 GB disk image..."
hdiutil create -layout none -size 20g -quiet "$DATA_DIR/$DRIVE_UUID"
mv "$DATA_DIR/$DRIVE_UUID.dmg" "$DATA_DIR/$DRIVE_UUID.img"
echo "==> Disk image created."

# ── Write config.plist ────────────────────────────────────────────────────────
echo ""
echo "==> Writing config.plist..."

# Bootstrap an empty plist
cat > "$PLIST" << 'PLIST_INIT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
PLIST_INIT

PB() { /usr/libexec/PlistBuddy -c "$1" "$PLIST"; }

# Top-level keys
PB "add :Backend              string  QEMU"
PB "add :ConfigurationVersion integer 4"

# Information
PB "add :Information          dict"
PB "add :Information:Name     string  $VM_NAME"
PB "add :Information:UUID     string  $VM_UUID"
PB "add :Information:IconCustom bool  false"

# System
PB "add :System                   dict"
PB "add :System:Architecture      string  aarch64"
PB "add :System:CPU               string  default"
PB "add :System:CPUCount          integer 2"
PB "add :System:MemorySize        integer 2048"
PB "add :System:Target            string  virt"

# QEMU settings
PB "add :QEMU                     dict"
PB "add :QEMU:Hypervisor          bool    true"
PB "add :QEMU:UEFIBoot            bool    true"
PB "add :QEMU:BalloonDevice       bool    true"
PB "add :QEMU:RNGDevice           bool    true"

# Drive[0] — main disk (VirtIO)
PB "add :Drive                              array"
PB "add :Drive:0                            dict"
PB "add :Drive:0:Identifier                 string  $DRIVE_UUID"
PB "add :Drive:0:ImageName                  string  $DRIVE_UUID.img"
PB "add :Drive:0:ImageType                  string  Disk"
PB "add :Drive:0:Interface                  string  VirtIO"
PB "add :Drive:0:ReadOnly                   bool    false"

# Drive[1] — Alpine installer ISO (IDE CD-ROM)
PB "add :Drive:1                            dict"
PB "add :Drive:1:Identifier                 string  $ISO_UUID"
PB "add :Drive:1:ImageName                  string  $ISO_FILE"
PB "add :Drive:1:ImageType                  string  CD"
PB "add :Drive:1:Interface                  string  VirtIO"
PB "add :Drive:1:ReadOnly                   bool    true"

# Network — shared/NAT (for SSH access)
PB "add :Network                            array"
PB "add :Network:0                          dict"
PB "add :Network:0:Hardware                 string  virtio-net-pci"
PB "add :Network:0:Mode                     string  Shared"
PB "add :Network:0:MacAddress               string  $MAC_ADDR"
PB "add :Network:0:IsolateFromHost          bool    false"
PB "add :Network:0:PortForward              array"

# Display — virtio GPU (needed for Alpine installer)
PB "add :Display                            array"
PB "add :Display:0                          dict"
PB "add :Display:0:Hardware                 string  virtio-gpu-gl-pci"
PB "add :Display:0:DynamicResolution        bool    true"
PB "add :Display:0:UpscalingFilter          string  Linear"
PB "add :Display:0:DownscalingFilter        string  Linear"
PB "add :Display:0:NativeResolution         bool    false"

# Serial — built-in terminal console
PB "add :Serial                             array"
PB "add :Serial:0                           dict"
PB "add :Serial:0:Mode                      string  Terminal"
PB "add :Serial:0:Target                    string  Auto"

# Sound — empty (no sound card needed)
PB "add :Sound                              array"

# Sharing — directory share settings
PB "add :Sharing                            dict"
PB "add :Sharing:DirectoryShareMode         string  None"
PB "add :Sharing:DirectoryShareReadOnly     bool    false"
PB "add :Sharing:ClipboardSharing          bool    false"

# Input — USB passthrough (USB 2.0 bus, eZ-FET compatible)
PB "add :Input                              dict"
PB "add :Input:UsbBusSupport               string  2.0"
PB "add :Input:UsbSharing                  bool    true"
PB "add :Input:MaximumUsbShare             integer 3"

echo "==> config.plist written."

# ── Open in UTM ───────────────────────────────────────────────────────────────
echo ""
echo "==> Opening VM in UTM..."
open -a UTM "$VM_DIR"

echo ""
echo "=================================================="
echo "  VM '$VM_NAME' is ready!"
echo "=================================================="
echo ""
echo "Alpine Linux installer steps:"
echo "  Login as 'root' (no password)"
echo "  Run:  setup-alpine"
echo "  Keyboard:  us / us"
echo "  Hostname:  msp430"
echo "  Network:   eth0, dhcp"
echo "  Password:  set a root password"
echo "  Timezone:  your timezone"
echo "  Mirror:    pick a nearby one (or 'f' for fastest)"
echo "  SSH:       openssh"
echo "  NTP:       chrony"
echo "  Disk:      vda → sys (overwrites disk)"
echo "  After install: reboot"
echo ""
echo "Post-install, in the VM:"
echo "  adduser dev"
echo "  apk add sudo"
echo "  echo 'dev ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
echo ""
echo "From Mac Terminal:"
echo "  ssh dev@\$(utmctl ip-address '$VM_NAME')"
echo "  # Then run vm-setup.sh per SETUP.md"
echo ""
