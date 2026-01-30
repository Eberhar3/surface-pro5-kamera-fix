#!/bin/bash
# Surface Pro 5 Kamera Fix - Installer

set -e

KERNEL_VERSION=$(uname -r)
WORK_DIR="/tmp/surface-camera-fix-$$"
MODULE_DIR="/lib/modules/$KERNEL_VERSION/kernel/drivers/platform/x86/intel/int3472"

echo "========================================"
echo "Surface Pro 5 Kamera Fix"
echo "Kernel: $KERNEL_VERSION"
echo "========================================"

if [ "$EUID" -ne 0 ]; then
    echo "Fehler: Bitte mit sudo ausführen"
    exit 1
fi

echo "[1/6] Abhängigkeiten prüfen..."
apt-get install -y build-essential linux-headers-$KERNEL_VERSION git 2>/dev/null

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "[2/6] Kernel-Source holen..."
git clone --depth=1 --filter=blob:none --sparse \
    https://github.com/linux-surface/kernel.git 2>/dev/null
cd kernel
git sparse-checkout set drivers/platform/x86/intel/int3472

echo "[3/6] Dateien vorbereiten..."
mkdir -p "$WORK_DIR/build"
cp drivers/platform/x86/intel/int3472/*.c "$WORK_DIR/build/"
cp drivers/platform/x86/intel/int3472/*.h "$WORK_DIR/build/" 2>/dev/null || true
cd "$WORK_DIR/build"

cat > Kbuild << 'EOF'
obj-m := intel_skl_int3472.o
intel_skl_int3472-y := discrete.o common.o clk_and_regulator.o led.o discrete_quirks.o
EOF

echo "[4/6] Modul bauen..."
make -C /lib/modules/$KERNEL_VERSION/build M=$(pwd) modules 2>&1 | tail -10

if [ ! -f intel_skl_int3472.ko ]; then
    echo "Fehler: Build fehlgeschlagen!"
    exit 1
fi

echo "[5/6] Modul installieren..."
mkdir -p "$MODULE_DIR"

for mod in intel_skl_int3472_discrete intel_skl_int3472_common; do
    if [ -f "$MODULE_DIR/${mod}.ko" ]; then
        cp "$MODULE_DIR/${mod}.ko" "$MODULE_DIR/${mod}.ko.backup"
        mv "$MODULE_DIR/${mod}.ko" "$MODULE_DIR/${mod}.ko.disabled"
    fi
done

cp intel_skl_int3472.ko "$MODULE_DIR/"

echo "[6/6] System aktualisieren..."
depmod -a
update-initramfs -u

rm -rf "$WORK_DIR"

echo ""
echo "========================================"
echo "Fertig! Jetzt neustarten:"
echo "  sudo reboot"
echo ""
echo "Danach testen mit:"
echo "  cam --list"
echo "========================================"
