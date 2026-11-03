#!/bin/sh
# Builds power-plus_<ver>_all.deb
set -eu
cd "$(dirname "$0")"
VER=$(grep -oP "^VERSION = '\K[^']+" src/power-plus)
R=build/power-plus_${VER}_all
rm -rf build; mkdir -p "$R/DEBIAN" "$R/usr/bin" "$R/usr/libexec/power-plus" \
  "$R/usr/share/applications" "$R/usr/share/polkit-1/actions" \
  "$R/usr/share/icons/hicolor/scalable/apps" "$R/usr/share/doc/power-plus"
install -m755 src/power-plus "$R/usr/bin/power-plus"
install -m755 src/lid-helper "$R/usr/libexec/power-plus/lid-helper"
install -m644 src/com.palamarka.PowerPlus.desktop "$R/usr/share/applications/"
install -m644 src/com.palamarka.PowerPlus.policy "$R/usr/share/polkit-1/actions/"
install -m644 src/com.palamarka.PowerPlus.svg "$R/usr/share/icons/hicolor/scalable/apps/"
install -m644 README.md "$R/usr/share/doc/power-plus/README.md"
cat > "$R/DEBIAN/control" <<CTL
Package: power-plus
Version: $VER
Section: gnome
Priority: optional
Architecture: all
Depends: python3, python3-gi, gir1.2-gtk-4.0, gir1.2-adw-1 (>= 1.4), pkexec | policykit-1, systemd
Recommends: gnome-settings-daemon
Maintainer: Palamarka <https://tech.palamarka.com>
Homepage: https://tech.palamarka.com
Description: power settings GNOME hides
 Power Plus adds the power options missing from GNOME Settings:
 any screen blank delay (not only up to 15 minutes), automatic
 suspend on AC and battery, and what happens when the laptop lid
 is closed (on battery, plugged in, with an external monitor).
 Bulgarian and English interface.
CTL
cat > "$R/DEBIAN/postrm" <<'PR'
#!/bin/sh
set -e
if [ "$1" = purge ] && [ -f /etc/systemd/logind.conf.d/50-power-plus.conf ]; then
  rm -f /etc/systemd/logind.conf.d/50-power-plus.conf
  systemctl kill -s HUP systemd-logind 2>/dev/null || true
fi
PR
chmod 755 "$R/DEBIAN/postrm"
dpkg-deb --root-owner-group --build "$R" build/ >/dev/null
ls -l build/*.deb
