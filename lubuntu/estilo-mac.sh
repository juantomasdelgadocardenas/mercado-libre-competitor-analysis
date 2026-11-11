#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   Estilo macOS para Lubuntu (LXQt) — ligero para 4 GB RAM    ║
# ╚══════════════════════════════════════════════════════════════╝
# Usa los temas libres WhiteSur (github.com/vinceliuice) + dock Plank.
# Uso:  bash estilo-mac.sh            (tema claro, como macOS por defecto)
#       bash estilo-mac.sh oscuro     (modo oscuro)
# Para deshacer:  bash estilo-mac.sh deshacer

set -u
R=$'\e[0m'; B=$'\e[1m'; D=$'\e[2m'
C1=$'\e[38;5;117m'; C2=$'\e[38;5;250m'; OK=$'\e[38;5;114m'; WARN=$'\e[38;5;215m'; ERR=$'\e[38;5;204m'
titulo() { printf "\n${C1}${B}  %s${R}\n" "$1"; }
paso()   { printf "   ${D}…${R} %s" "$1"; }
bien()   { printf "\r   ${OK}●${R} %s\n" "$1"; }
aviso()  { printf "\r   ${WARN}●${R} %s\n" "$1"; }

[ "$(id -u)" -eq 0 ] && { echo "Ejecútalo como tu usuario normal (sin sudo)."; exit 1; }

CFG="$HOME/.config"
SESSION="$CFG/lxqt/session.conf"
LXQT="$CFG/lxqt/lxqt.conf"
PANEL="$CFG/lxqt/panel.conf"

# Editor de archivos .conf/.ini (formato Qt) sin romper el resto del archivo
ini() { # ini archivo sección clave valor
  python3 - "$@" <<'PY'
import configparser, sys, os
f, sec, key, val = sys.argv[1:5]
c = configparser.ConfigParser(interpolation=None, strict=False, delimiters=('=',))
c.optionxform = str
if os.path.exists(f): c.read(f, encoding='utf-8')
if not c.has_section(sec): c.add_section(sec)
c.set(sec, key, val)
os.makedirs(os.path.dirname(f), exist_ok=True)
with open(f, 'w', encoding='utf-8') as h: c.write(h, space_around_delimiters=False)
PY
}

# ─────────────────────────── DESHACER ───────────────────────────
if [ "${1:-}" = "deshacer" ]; then
  ULTIMO=$(ls -d "$HOME"/.respaldo-estilo-mac-* 2>/dev/null | tail -1)
  [ -z "$ULTIMO" ] && { echo "No encontré respaldo."; exit 1; }
  cp -a "$ULTIMO$HOME/." "$HOME/" 2>/dev/null
  for f in "$CFG/autostart/plank.desktop" "$CFG/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" "$PANEL" "$CFG/Kvantum/kvantum.kvconfig"; do
    [ -e "$ULTIMO$f" ] || rm -f "$f"
  done
  [ -e "$ULTIMO$SESSION" ] || ini "$SESSION" General window_manager openbox
  pkill plank 2>/dev/null
  echo "${OK}Restaurado desde $ULTIMO. Cierra sesión y vuelve a entrar.${R}"; exit 0
fi

MODO="${1:-claro}"
if [ "$MODO" = "oscuro" ]; then
  GTK=WhiteSur-Dark; ICON=WhiteSur-dark; KV=WhiteSurDark; PLANK=WhiteSur-Dark; WP=contents/images_dark
else
  GTK=WhiteSur-Light; ICON=WhiteSur; KV=WhiteSur; PLANK=WhiteSur-Light; WP=contents/images
fi

RESPALDO="$HOME/.respaldo-estilo-mac-$(date +%Y%m%d-%H%M%S)"
respaldar() { for f in "$@"; do [ -e "$f" ] && mkdir -p "$RESPALDO$(dirname "$f")" && cp -a "$f" "$RESPALDO$f"; done; }

clear
printf "\n${C2}${B}"
cat <<'EOF'
                 ●  ●  ●
        ┌──────────────────────────┐
        │    estilo  m a c  para   │
        │         Lubuntu          │
        └──────────────────────────┘
EOF
printf "${R}\n"
sudo -v || exit 1

instalar() {
  local d=(); for p in "$@"; do apt-cache show "$p" >/dev/null 2>&1 && d+=("$p"); done
  [ ${#d[@]} -eq 0 ] && return 1
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${d[@]}" >/dev/null 2>&1
}

# ═══════════════════ 1. Programas necesarios ═══════════════════
titulo "Programas"
paso "Dock, gestor de ventanas y motor de temas"
sudo apt-get update -qq >/dev/null 2>&1
instalar git python3 plank xfwm4 qt5-style-kvantum qt6-style-kvantum fonts-inter fonts-noto-color-emoji dconf-cli
command -v plank >/dev/null && command -v xfwm4 >/dev/null \
  && bien "Plank (dock), xfwm4 (ventanas) y Kvantum instalados" \
  || { aviso "No se pudo instalar Plank o xfwm4. Revisa tu internet."; exit 1; }

titulo "Descargando temas WhiteSur (≈150 MB, paciencia)"
TMP="$HOME/.cache/estilo-mac"; rm -rf "$TMP"; mkdir -p "$TMP"
for r in WhiteSur-gtk-theme WhiteSur-icon-theme WhiteSur-cursors WhiteSur-kde; do
  paso "$r"
  git clone -q --depth 1 "https://github.com/vinceliuice/$r.git" "$TMP/$r" 2>/dev/null \
    && bien "$r" || { aviso "Falló la descarga de $r"; exit 1; }
done

# ═══════════════════ 2. Instalar temas ═══════════════════
titulo "Instalando temas"
respaldar "$LXQT" "$SESSION" "$PANEL" "$CFG/gtk-3.0/settings.ini" "$CFG/gtk-4.0/settings.ini" \
  "$HOME/.gtkrc-2.0" "$CFG/Kvantum/kvantum.kvconfig" "$HOME/.icons/default/index.theme" \
  "$CFG/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" "$CFG/autostart/plank.desktop"
mkdir -p "$RESPALDO"

paso "Ventanas y apps GTK"
mkdir -p "$HOME/.themes"
tar -xJf "$TMP/WhiteSur-gtk-theme/release/$GTK.tar.xz" -C "$HOME/.themes"
bien "Tema $GTK"

paso "Iconos (tarda un poco)"
( cd "$TMP/WhiteSur-icon-theme" && ./install.sh >/dev/null 2>&1 ) && bien "Iconos WhiteSur" || aviso "Iconos con errores"

paso "Cursor"
mkdir -p "$HOME/.local/share/icons" "$HOME/.icons/default"
rm -rf "$HOME/.local/share/icons/WhiteSur-cursors"
cp -pr "$TMP/WhiteSur-cursors/dist" "$HOME/.local/share/icons/WhiteSur-cursors"
printf "[Icon Theme]\nInherits=WhiteSur-cursors\n" > "$HOME/.icons/default/index.theme"
bien "Cursor WhiteSur"

paso "Apps Qt (Kvantum)"
mkdir -p "$CFG/Kvantum"; rm -rf "$CFG/Kvantum/WhiteSur"
cp -r "$TMP/WhiteSur-kde/Kvantum/WhiteSur" "$CFG/Kvantum/WhiteSur"
printf "[General]\ntheme=%s\n" "$KV" > "$CFG/Kvantum/kvantum.kvconfig"
bien "Kvantum $KV"

paso "Fondo de pantalla"
mkdir -p "$HOME/Imágenes"
FONDO="$HOME/Imágenes/fondo-whitesur-$MODO.jpg"
cp "$TMP/WhiteSur-kde/wallpaper/WhiteSur/$WP/"*.jpg "$FONDO"
bien "Fondo guardado en Imágenes"

# ═══════════════════ 3. Configurar el escritorio ═══════════════════
titulo "Configurando el escritorio"
paso "Temas, iconos y fuente"
FUENTE="Inter"; fc-list | grep -qi "Inter" || FUENTE="Noto Sans"
ini "$LXQT" General icon_theme "$ICON"
ini "$LXQT" Qt style kvantum
ini "$LXQT" Qt font "\"$FUENTE,10,-1,5,50,0,0,0,0,0\""
for t in kvantum Lubuntu\ Arc Clearlooks; do
  [ -d "/usr/share/lxqt/themes/$t" ] && { ini "$LXQT" General theme "$t"; break; }
done
for v in gtk-3.0 gtk-4.0; do
  mkdir -p "$CFG/$v"
  cat > "$CFG/$v/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK
gtk-icon-theme-name=$ICON
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=$FUENTE 10
gtk-application-prefer-dark-theme=$([ "$MODO" = oscuro ] && echo 1 || echo 0)
gtk-decoration-layout=close,minimize,maximize:
EOF
done
printf 'gtk-theme-name="%s"\ngtk-icon-theme-name="%s"\ngtk-cursor-theme-name="WhiteSur-cursors"\ngtk-font-name="%s 10"\n' \
  "$GTK" "$ICON" "$FUENTE" > "$HOME/.gtkrc-2.0"
ini "$SESSION" Mouse cursor_theme WhiteSur-cursors
ini "$SESSION" Mouse cursor_size 24
bien "Apariencia aplicada a todas las apps"

paso "Botones de ventana a la izquierda (● ● ●)"
ini "$SESSION" General window_manager xfwm4
X="$CFG/xfce4/xfconf/xfce-perchannel-xml"; mkdir -p "$X"
cat > "$X/xfwm4.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="$GTK"/>
    <property name="button_layout" type="string" value="CHM|"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="title_font" type="string" value="$FUENTE Bold 10"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="show_dock_shadow" type="bool" value="false"/>
    <property name="frame_opacity" type="int" value="100"/>
    <property name="workspace_count" type="int" value="2"/>
  </property>
</channel>
EOF
bien "Cerrar · minimizar · maximizar a la izquierda, título centrado"

paso "Barra superior estilo macOS"
python3 - "$PANEL" <<'PY'
import configparser, sys, os, shutil
f = sys.argv[1]
if not os.path.exists(f):
    for cand in ("/etc/xdg/xdg-Lubuntu/lxqt/panel.conf", "/usr/share/lubuntu/lxqt/panel.conf", "/etc/xdg/lxqt/panel.conf"):
        if os.path.exists(cand):
            os.makedirs(os.path.dirname(f), exist_ok=True); shutil.copy(cand, f); break
c = configparser.ConfigParser(interpolation=None, strict=False, delimiters=('=',))
c.optionxform = str
c.read(f, encoding='utf-8')
if not c.has_section('panel1'): c.add_section('panel1')
p = c['panel1']
p['position'] = 'Top'; p['panelSize'] = '28'; p['iconSize'] = '18'
p['lineCount'] = '1'; p['alignment'] = '0'; p['width'] = '100'; p['percent'] = 'true'
# Las apps abiertas y accesos rápidos ahora van en el dock: se quitan de la barra
plugins = [x.strip() for x in p.get('plugins', 'mainmenu, tray, volume, clock').split(',') if x.strip()]
plugins = [x for x in plugins if c.get(x, 'type', fallback=x) not in ('taskbar', 'quicklaunch', 'showdesktop', 'desktopswitch')]
if 'espaciomac' not in plugins:
    plugins.insert(1 if plugins and plugins[0].startswith('mainmenu') else 0, 'espaciomac')
p['plugins'] = ', '.join(plugins)
c['espaciomac'] = {'type': 'spacer', 'expandable': 'true'}
for x in plugins:
    if not c.has_section(x): c[x] = {'type': x}
with open(f, 'w', encoding='utf-8') as h: c.write(h, space_around_delimiters=False)
PY
bien "Barra arriba: menú a la izquierda, reloj y bandeja a la derecha"

paso "Dock (Plank) abajo"
mkdir -p "$HOME/.local/share/plank/themes"
rm -rf "$HOME/.local/share/plank/themes/$PLANK"
cp -r "$HOME/.themes/$GTK/plank" "$HOME/.local/share/plank/themes/$PLANK"
L="$CFG/plank/dock1/launchers"; mkdir -p "$L"; rm -f "$L"/*.dockitem
for app in pcmanfm-qt firefox_firefox firefox qterminal featherpad lxqt-config; do
  for dir in /usr/share/applications /var/lib/snapd/desktop/applications; do
    [ -f "$dir/$app.desktop" ] && [ ! -f "$L/${app%%_*}.dockitem" ] && \
      printf "[PlankDockItemPreferences]\nLauncher=file://%s\n" "$dir/$app.desktop" > "$L/${app%%_*}.dockitem"
  done
done
D1=/net/launchpad/plank/docks/dock1
dconf write $D1/theme "'$PLANK'" 2>/dev/null
dconf write $D1/zoom-enabled true 2>/dev/null
dconf write $D1/zoom-percent 150 2>/dev/null
dconf write $D1/icon-size 44 2>/dev/null
dconf write $D1/hide-mode 0 2>/dev/null
mkdir -p "$CFG/autostart"
printf "[Desktop Entry]\nType=Application\nName=Plank\nExec=plank\nX-LXQt-Need-Tray=false\n" > "$CFG/autostart/plank.desktop"
bien "Dock con efecto de lupa y tus apps principales"

paso "Fondo de pantalla"
command -v pcmanfm-qt >/dev/null && pcmanfm-qt --set-wallpaper="$FONDO" --wallpaper-mode=zoom >/dev/null 2>&1
bien "Fondo WhiteSur aplicado"

rm -rf "$TMP"
printf "\n${C1}${B}  ¡Listo! ${R}\n\n"
printf "   ${WARN}Cierra sesión y vuelve a entrar para ver el cambio completo.${R}\n"
printf "   ${D}Respaldo: %s${R}\n" "$RESPALDO"
printf "   ${D}Modo oscuro: bash %s oscuro   ·   Deshacer: bash %s deshacer${R}\n\n" "$0" "$0"
