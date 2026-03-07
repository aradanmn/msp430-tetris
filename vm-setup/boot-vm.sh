#!/bin/sh
# Boot the MSP430 dev VM with LaunchPad USB passthrough.
# Requires sudo (for USB host device access).
# Usage: sudo ./vm-setup/boot-vm.sh
VM="$HOME/Documents/msp430-dev-vm/vm"
exec /opt/homebrew/bin/qemu-system-aarch64 \
    -machine virt,highmem=on \
    -accel hvf \
    -cpu cortex-a57 \
    -smp 2 \
    -m 2048 \
    -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd \
    -drive if=pflash,format=raw,file="$VM/efi_vars.fd" \
    -drive file="$VM/msp430-dev.img",if=virtio,format=raw \
    -netdev user,id=net0,hostfwd=tcp::5022-:22 \
    -device virtio-net-pci,netdev=net0 \
    -device usb-ehci,id=ehci \
    -device usb-host,bus=ehci.0,vendorid=0x2047,productid=0x0013 \
    -display none \
    -serial file:/tmp/vm-serial.log \
    -monitor none
