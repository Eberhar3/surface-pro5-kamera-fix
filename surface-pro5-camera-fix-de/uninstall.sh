#!/bin/bash
# Surface Pro 5 Kamera Fix - Deinstallation

set -e

KERNEL_VERSION=$(uname -r)
MODULE_DIR="/lib/modules/$KERNEL_VERSION/kernel/drivers/platform/x86/intel/int3472"

echo "Surface Pro 5 Kamera Fix - Deinstallation"

if [ "$EUID" -ne 0 ]; then
    echo "Fehler: Bitte mit sudo ausführen"
    exit 1
fi

if [ -f "$MODULE_DIR/intel_skl_int3472.ko" ]; then
    rm "$MODULE_DIR/intel_skl_int3472.ko"
    echo "Entfernt: intel_skl_int3472.ko"
fi

for mod in intel_skl_int3472_discrete intel_skl_int3472_common; do
    if [ -f "$MODULE_DIR/${mod}.ko.disabled" ]; then
        mv "$MODULE_DIR/${mod}.ko.disabled" "$MODULE_DIR/${mod}.ko"
        echo "Wiederhergestellt: ${mod}.ko"
    fi
done

depmod -a
update-initramfs -u

echo ""
echo "Fertig! Bitte neustarten."
