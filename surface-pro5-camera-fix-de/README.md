# Surface Pro 5 Kamera Fix für Linux

## Das Problem

Die Kameras vom Surface Pro 5 gehen unter Linux nicht, weil Microsoft im BIOS (DSDT) Mist gebaut hat.

**Der Fehler:** GPIO 151 ist als "Privacy LED" (0x0d) definiert, sollte aber "Power Enable" (0x0b) sein.

Dadurch kriegt die Rückkamera (ov8865) keinen Strom und pennt.

## Die Lösung

Die zwei Kernel-Module `intel_skl_int3472_discrete` und `intel_skl_int3472_common` zu einem kombinieren. Das umgeht Symbol-Abhängigkeitsprobleme beim Bauen.

## Installation

```bash
sudo ./install.sh
sudo reboot
```

## Test

```bash
# Kameras auflisten
cam --list

# Live-Bild (Rückkamera)
gst-launch-1.0 libcamerasrc ! queue ! videoconvert ! autovideosink

# Frontkamera
gst-launch-1.0 libcamerasrc camera-name=1 ! queue ! videoconvert ! autovideosink
```

## Was funktioniert

- ✅ Rückkamera (ov8865, 8MP)
- ✅ Frontkamera (ov5693, 5MP)
- ✅ IR Kamera (ov7251)
- ✅ Autofokus (dw9719)
- ✅ libcamera / gstreamer
- ✅ Bilder aufnehmen

## App-Kompatibilität

**Wichtig:** Die Intel IPU3 Kameras brauchen `libcamera`. Normale V4L2-Apps (OBS, Zoom, Teams, Cheese) funktionieren nicht direkt - das ist ein generelles Linux/IPU3 Problem, kein Surface-spezifisches.

**Was geht:**
```bash
# gstreamer Pipeline
gst-launch-1.0 libcamerasrc ! queue ! videoconvert ! autovideosink

# Bild speichern
gst-launch-1.0 libcamerasrc ! jpegenc ! filesink location=foto.jpg
```

**Was nicht geht (ohne Workaround):**
- OBS Studio (stürzt ab)
- Cheese (Fehler)
- Zoom, Teams, etc.

**Workaround für V4L2-Apps:**
Braucht v4l2loopback als virtuelle Webcam - ist aber ein separates Thema.

## Was geändert wurde

Statt zwei separate Module:
- `intel_skl_int3472_discrete.ko`
- `intel_skl_int3472_common.ko`

Jetzt ein kombiniertes Modul:
- `intel_skl_int3472.ko`

Enthält: `discrete.c`, `common.c`, `clk_and_regulator.c`, `led.c`, `discrete_quirks.c`

## Getestet mit

- Surface Pro 5 (2017)
- Kernel 6.18.7-surface-1
- Linux Mint 22

## Deinstallation

```bash
sudo ./uninstall.sh
sudo reboot
```

## Lizenz

GPL v2 (wie der Linux Kernel)
