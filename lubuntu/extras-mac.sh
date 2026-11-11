#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   Extras macOS para Lubuntu: Spotlight, Launchpad, capturas, ║
# ║   notificaciones, pantalla de inicio y arranque              ║
# ╚══════════════════════════════════════════════════════════════╝
# Correr DESPUÉS de estilo-mac.sh.   Uso:  bash extras-mac.sh

set -u
R=$'\e[0m'; B=$'\e[1m'; D=$'\e[2m'
C1=$'\e[38;5;117m'; OK=$'\e[38;5;114m'; WARN=$'\e[38;5;215m'
titulo() { printf "\n${C1}${B}  %s${R}\n" "$1"; }
paso()   { printf "   ${D}…${R} %s" "$1"; }
bien()   { printf "\r   ${OK}●${R} %s\n" "$1"; }
aviso()  { printf "\r   ${WARN}●${R} %s\n" "$1"; }

[ "$(id -u)" -eq 0 ] && { echo "Ejecútalo como tu usuario normal (sin sudo)."; exit 1; }
CFG="$HOME/.config"
RESPALDO="$HOME/.respaldo-extras-mac-$(date +%Y%m%d-%H%M%S)"
respaldar() { for f in "$@"; do [ -e "$f" ] && mkdir -p "$RESPALDO$(dirname "$f")" && cp -a "$f" "$RESPALDO$f"; done; }

instalar() {
  local d=(); for p in "$@"; do apt-cache show "$p" >/dev/null 2>&1 && d+=("$p"); done
  [ ${#d[@]} -eq 0 ] && return 1
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${d[@]}" >/dev/null 2>&1
}

# ¿Modo claro u oscuro? (lo deja estilo-mac.sh en la config de GTK)
OSCURO=0; grep -q 'prefer-dark-theme=1' "$CFG/gtk-3.0/settings.ini" 2>/dev/null && OSCURO=1
if [ $OSCURO -eq 1 ]; then
  BG="#1e1e1ee6"; FG="#f5f5f7"; MUTED="#98989d"; BORDE="#ffffff1f"
else
  BG="#f6f6f6e6"; FG="#1d1d1f"; MUTED="#86868b"; BORDE="#0000001f"
fi
FUENTE="Inter"; fc-list | grep -qi "Inter" || FUENTE="Noto Sans"

clear
printf "\n${C1}${B}      ●  ●  ●   extras mac para Lubuntu\n${R}\n"
sudo -v || exit 1
sudo apt-get update -qq >/dev/null 2>&1

# ═══════════════════ 1. Spotlight y Launchpad ═══════════════════
titulo "Spotlight y Launchpad"
paso "Instalando rofi (buscador ligero, ~10 MB de RAM)"
instalar rofi scrot && bien "rofi y scrot instalados" || { aviso "No se pudo instalar rofi"; exit 1; }

mkdir -p "$CFG/rofi" "$HOME/.local/bin" "$HOME/.local/share/applications"
cat > "$CFG/rofi/spotlight.rasi" <<EOF
/* Buscador estilo Spotlight */
* {
  font: "$FUENTE 13";
  background-color: transparent;
  text-color: $FG;
}
window {
  location: north;
  y-offset: 22%;
  width: 640px;
  border: 1px;
  border-color: $BORDE;
  border-radius: 14px;
  background-color: $BG;
  padding: 6px;
}
mainbox { children: [ inputbar, listview ]; spacing: 4px; }
inputbar { children: [ icon-search, entry ]; padding: 10px 12px; spacing: 12px; }
icon-search { expand: false; filename: "system-search"; size: 24px; }
entry {
  placeholder: "Búsqueda Spotlight";
  placeholder-color: $MUTED;
  vertical-align: 0.5;
  font: "$FUENTE 18";
}
listview { lines: 7; fixed-height: false; scrollbar: false; spacing: 2px; }
element { padding: 7px 12px; spacing: 12px; border-radius: 8px; }
element selected.normal { background-color: #0a84ff; text-color: #ffffff; }
element-icon { size: 26px; }
element-text { text-color: inherit; vertical-align: 0.5; }
EOF

cat > "$CFG/rofi/launchpad.rasi" <<EOF
/* Cuadrícula de apps estilo Launchpad */
* {
  font: "$FUENTE 11";
  background-color: transparent;
  text-color: #ffffff;
}
window {
  fullscreen: true;
  background-color: #000000a6;
  padding: 6% 10%;
}
mainbox { children: [ inputbar, listview ]; spacing: 48px; }
inputbar {
  children: [ entry ];
  margin: 0 30%;
  padding: 7px 14px;
  border-radius: 9px;
  background-color: #ffffff26;
}
entry {
  placeholder: "Buscar";
  placeholder-color: #ffffffa0;
  horizontal-align: 0.5;
}
listview { columns: 7; lines: 4; flow: horizontal; spacing: 24px; fixed-columns: true; scrollbar: false; }
element { orientation: vertical; padding: 14px 6px; spacing: 10px; border-radius: 16px; }
element selected.normal { background-color: #ffffff26; }
element-icon { size: 72px; horizontal-align: 0.5; }
element-text { horizontal-align: 0.5; text-color: inherit; }
EOF

cat > "$HOME/.local/bin/spotlight" <<'EOF'
#!/bin/sh
pkill -x rofi && exit 0
exec rofi -show drun -theme ~/.config/rofi/spotlight.rasi -show-icons -drun-display-format "{name}" -no-lazy-grab
EOF
cat > "$HOME/.local/bin/launchpad" <<'EOF'
#!/bin/sh
pkill -x rofi && exit 0
exec rofi -show drun -theme ~/.config/rofi/launchpad.rasi -show-icons -drun-display-format "{name}" -no-lazy-grab
EOF
chmod +x "$HOME/.local/bin/spotlight" "$HOME/.local/bin/launchpad"

cat > "$HOME/.local/share/applications/launchpad.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Launchpad
Comment=Todas tus aplicaciones
Exec=$HOME/.local/bin/launchpad
Icon=view-app-grid
Terminal=false
NoDisplay=true
EOF
bien "Spotlight (Super + Espacio) y Launchpad (Super + A, y en el dock)"

# ═══════════════════ 2. Capturas de pantalla como Mac ═══════════════════
titulo "Capturas de pantalla"
cat > "$HOME/.local/bin/captura-mac" <<'EOF'
#!/bin/sh
# completa | region  → guarda en el Escritorio como en macOS
DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Escritorio"); mkdir -p "$DIR"
ARCHIVO="$DIR/Captura de pantalla $(date '+%Y-%m-%d a las %H.%M.%S').png"
if [ "$1" = region ]; then scrot -s -f "$ARCHIVO" 2>/dev/null || scrot -s "$ARCHIVO"; else scrot "$ARCHIVO"; fi
[ -f "$ARCHIVO" ] && command -v notify-send >/dev/null && notify-send -i camera-photo "Captura guardada" "En tu Escritorio"
EOF
chmod +x "$HOME/.local/bin/captura-mac"
instalar libnotify-bin >/dev/null 2>&1
bien "Super + Shift + 3 (pantalla completa) · Super + Shift + 4 (zona)"

# ═══════════════════ 3. Atajos de teclado ═══════════════════
titulo "Atajos de teclado"
paso "Registrando atajos en LXQt"
ATAJOS="$CFG/lxqt/globalkeyshortcuts.conf"; respaldar "$ATAJOS"
python3 - "$ATAJOS" "$HOME" <<'PY'
import configparser, sys, os, shutil
f, home = sys.argv[1], sys.argv[2]
if not os.path.exists(f):
    for cand in ("/etc/xdg/xdg-Lubuntu/lxqt/globalkeyshortcuts.conf", "/etc/xdg/lxqt/globalkeyshortcuts.conf"):
        if os.path.exists(cand):
            os.makedirs(os.path.dirname(f), exist_ok=True); shutil.copy(cand, f); break
c = configparser.ConfigParser(interpolation=None, strict=False, delimiters=('=',))
c.optionxform = str
if os.path.exists(f): c.read(f, encoding='utf-8')
nuevos = {
    "Meta%2BSpace":       ("Spotlight",            f"{home}/.local/bin/spotlight"),
    "Meta%2BA":           ("Launchpad",            f"{home}/.local/bin/launchpad"),
    "Shift%2BMeta%2B3":   ("Captura completa",     f"{home}/.local/bin/captura-mac, completa"),
    "Shift%2BMeta%2B4":   ("Captura de una zona",  f"{home}/.local/bin/captura-mac, region"),
}
for combo, (nombre, cmd) in nuevos.items():
    for s in [s for s in c.sections() if s.split('.')[0] == combo]:
        c.remove_section(s)          # quita lo que antes usaba esa combinación
    c[f"{combo}.{900 + len(c.sections())}"] = {"Comment": nombre, "Enabled": "true", "Exec": cmd}
os.makedirs(os.path.dirname(f), exist_ok=True)
with open(f, 'w', encoding='utf-8') as h: c.write(h, space_around_delimiters=False)
PY
bien "Atajos guardados"

# ═══════════════════ 4. Dock completo ═══════════════════
titulo "Dock"
L="$CFG/plank/dock1/launchers"; mkdir -p "$L"
printf "[PlankDockItemPreferences]\nLauncher=file://%s\n" "$HOME/.local/share/applications/launchpad.desktop" > "$L/launchpad.dockitem"
printf "[PlankDockItemPreferences]\nLauncher=docklet://trash\n" > "$L/papelera.dockitem"
ITEMS=$(cd "$L" && ls *.dockitem | grep -vE '^(launchpad|papelera)\.dockitem$' | sed "s/.*/'&'/" | paste -sd,)
dconf write /net/launchpad/plank/docks/dock1/dock-items "['launchpad.dockitem',${ITEMS:+$ITEMS,}'papelera.dockitem']" 2>/dev/null
bien "Launchpad al inicio y Papelera al final del dock"

# ═══════════════════ 5. Notificaciones arriba a la derecha ═══════════════════
titulo "Notificaciones"
N="$CFG/lxqt/notifications.conf"; respaldar "$N"
python3 - "$N" <<'PY'
import configparser, sys, os
f = sys.argv[1]
c = configparser.ConfigParser(interpolation=None, strict=False, delimiters=('=',)); c.optionxform = str
if os.path.exists(f): c.read(f, encoding='utf-8')
if not c.has_section('General'): c.add_section('General')
c['General']['placement'] = 'top-right'
c['General']['server_decides'] = '5'
with open(f, 'w', encoding='utf-8') as h: c.write(h, space_around_delimiters=False)
PY
bien "Aparecen arriba a la derecha, como en macOS"

# ═══════════════════ 6. Pantalla de inicio de sesión ═══════════════════
titulo "Pantalla de inicio de sesión"
FONDO=$(ls "$HOME/Imágenes"/fondo-whitesur-*.jpg 2>/dev/null | head -1)
TEMA=$(grep -hs '^Current=' /etc/sddm.conf /etc/sddm.conf.d/*.conf /usr/lib/sddm/sddm.conf.d/*.conf 2>/dev/null | tail -1 | cut -d= -f2)
TEMA=${TEMA:-lubuntu}; DIRTEMA="/usr/share/sddm/themes/$TEMA"
if [ -n "$FONDO" ] && [ -f "$DIRTEMA/theme.conf" ] && grep -qi '^background=' "$DIRTEMA/theme.conf"; then
  sudo mkdir -p /usr/share/backgrounds
  sudo cp "$FONDO" /usr/share/backgrounds/whitesur.jpg
  [ -f "$DIRTEMA/theme.conf.user" ] && sudo cp "$DIRTEMA/theme.conf.user" "$DIRTEMA/theme.conf.user.bak"
  printf "[General]\nbackground=/usr/share/backgrounds/whitesur.jpg\n" | sudo tee "$DIRTEMA/theme.conf.user" >/dev/null
  bien "Fondo WhiteSur en la pantalla de contraseña"
else
  aviso "Tu pantalla de inicio no permite cambiar el fondo así; se omite"
fi

# ═══════════════════ 7. Arranque limpio (pantalla negra + logo) ═══════════════════
titulo "Animación de arranque"
paso "Estilo Mac: fondo negro, logo de tu equipo y círculo de carga"
if instalar plymouth-theme-spinner; then
  if [ -e /sys/firmware/acpi/bgrt ] && [ -f /usr/share/plymouth/themes/bgrt/bgrt.plymouth ]; then
    P=/usr/share/plymouth/themes/bgrt/bgrt.plymouth
  else
    P=/usr/share/plymouth/themes/spinner/spinner.plymouth
  fi
  sudo update-alternatives --set default.plymouth "$P" >/dev/null 2>&1
  printf "\r   ${D}…${R} Aplicando (tarda 1–2 minutos)                       "
  sudo update-initramfs -u >/dev/null 2>&1
  bien "Arranque minimalista activado                         "
else
  aviso "No disponible en tu versión"
fi

# ═══════════════════ 8. Firefox con aspecto Safari (opcional) ═══════════════════
titulo "Firefox estilo Safari (opcional)"
printf "   ¿Aplicarlo? Firefox debe estar CERRADO. [s/N] "; read -r r
if [[ "$r" =~ ^[sS] ]]; then
  T="$HOME/.cache/whitesur-ff"; rm -rf "$T"
  if git clone -q --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$T" 2>/dev/null; then
    pkill -x firefox 2>/dev/null
    ( cd "$T" && ./tweaks.sh -f >/dev/null 2>&1 ) && bien "Firefox con estilo Safari" || aviso "No se pudo (abre Firefox una vez y reintenta)"
    rm -rf "$T"
  else aviso "No se pudo descargar"; fi
else
  aviso "Omitido"
fi

printf "\n${C1}${B}  ¡Listo!${R}  Cierra sesión y vuelve a entrar.\n\n"
printf "   ${B}Super + Espacio${R}       Spotlight\n"
printf "   ${B}Super + A${R}             Launchpad\n"
printf "   ${B}Super + Shift + 3${R}     Captura completa  → Escritorio\n"
printf "   ${B}Super + Shift + 4${R}     Captura de una zona → Escritorio\n"
printf "\n   ${D}Respaldo: %s${R}\n\n" "$RESPALDO"
