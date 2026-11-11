#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Optimizador + embellecedor para Lubuntu (equipos de 4 GB)   ║
# ╚══════════════════════════════════════════════════════════════╝
# Uso:  bash optimizar-lubuntu.sh
# Pide tu contraseña (sudo) una vez. Respalda tus configuraciones antes
# de tocarlas en ~/.respaldo-optimizador-<fecha>.

set -u

# ── Colores y adornos ──────────────────────────────────────────────
R=$'\e[0m'; B=$'\e[1m'; D=$'\e[2m'
C1=$'\e[38;5;141m'; C2=$'\e[38;5;117m'; OK=$'\e[38;5;114m'; WARN=$'\e[38;5;215m'; ERR=$'\e[38;5;204m'

titulo() { printf "\n${C1}${B}╭─ %s${R}\n" "$1"; }
paso()   { printf "${C2}│${R}  ${D}…${R} %s" "$1"; }
bien()   { printf "\r${C2}│${R}  ${OK}✔${R} %s\n" "$1"; }
aviso()  { printf "\r${C2}│${R}  ${WARN}!${R} %s\n" "$1"; }
fallo()  { printf "\r${C2}│${R}  ${ERR}✘${R} %s\n" "$1"; }

if [ "$(id -u)" -eq 0 ]; then
  echo "${ERR}Ejecútalo como tu usuario normal (sin sudo); el script pedirá la contraseña.${R}"; exit 1
fi

USUARIO_HOME="$HOME"
RESPALDO="$HOME/.respaldo-optimizador-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RESPALDO"
respaldar() { [ -e "$1" ] && mkdir -p "$RESPALDO$(dirname "$1")" && cp -a "$1" "$RESPALDO$1"; }

ram_libre() { free -m | awk '/^Mem:/{print $7}'; }
RAM_ANTES=$(ram_libre)
DISCO_ANTES=$(df -m / | awk 'NR==2{print $4}')

clear
cat <<EOF
${C1}${B}
   ██╗     ██╗   ██╗██████╗ ██╗   ██╗███╗   ██╗████████╗██╗   ██╗
   ██║     ██║   ██║██╔══██╗██║   ██║████╗  ██║╚══██╔══╝██║   ██║
   ██║     ██║   ██║██████╔╝██║   ██║██╔██╗ ██║   ██║   ██║   ██║
   ██║     ██║   ██║██╔══██╗██║   ██║██║╚██╗██║   ██║   ██║   ██║
   ███████╗╚██████╔╝██████╔╝╚██████╔╝██║ ╚████║   ██║   ╚██████╔╝
   ╚══════╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝    ╚═════╝
${R}${C2}              ✦  optimizar · limpiar · embellecer  ✦${R}

EOF
sudo -v || { echo "Se necesita la contraseña para continuar."; exit 1; }
# Mantener sudo vivo mientras corre el script
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &

instalar() {  # instala paquetes que existan en los repositorios, ignora los que no
  local disponibles=()
  for p in "$@"; do apt-cache show "$p" >/dev/null 2>&1 && disponibles+=("$p"); done
  [ ${#disponibles[@]} -eq 0 ] && return 1
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${disponibles[@]}" >/dev/null 2>&1
}

# ═══════════════════════════ 1. SISTEMA ═══════════════════════════
titulo "Actualizando lista de paquetes"
paso "apt update"; sudo apt-get update -qq >/dev/null 2>&1 && bien "Repositorios al día" || aviso "No se pudo actualizar (¿sin internet?)"

titulo "Memoria: sacarle el jugo a 4 GB"
paso "zram (swap comprimida en RAM)"
if instalar zram-tools; then
  respaldar /etc/default/zramswap
  printf "ALGO=zstd\nPERCENT=50\nPRIORITY=100\n" | sudo tee /etc/default/zramswap >/dev/null
  sudo systemctl restart zramswap >/dev/null 2>&1
  bien "zram activo: ~2 GB extra comprimidos en RAM"
else aviso "zram-tools no disponible en tu versión"; fi

paso "Ajustes del kernel"
respaldar /etc/sysctl.d/99-optimizador.conf
sudo tee /etc/sysctl.d/99-optimizador.conf >/dev/null <<'EOF'
# Optimizador Lubuntu: priorizar RAM, usar zram antes que disco
vm.swappiness=100
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=10
vm.page-cluster=0
EOF
sudo sysctl --system >/dev/null 2>&1 && bien "swappiness, caché y escritura en disco ajustados"

paso "earlyoom (evita que el equipo se congele)"
instalar earlyoom && sudo systemctl enable --now earlyoom >/dev/null 2>&1 \
  && bien "earlyoom vigilando: cierra la app culpable antes de un cuelgue" || aviso "earlyoom no disponible"

titulo "Arranque y servicios"
paso "Límite de logs del sistema"
sudo mkdir -p /etc/systemd/journald.conf.d
printf "[Journal]\nSystemMaxUse=100M\n" | sudo tee /etc/systemd/journald.conf.d/99-optimizador.conf >/dev/null
sudo systemctl restart systemd-journald >/dev/null 2>&1; sudo journalctl --vacuum-size=100M >/dev/null 2>&1
bien "Logs limitados a 100 MB"

paso "TRIM semanal para SSD"
if lsblk -dno ROTA 2>/dev/null | grep -q 0; then
  sudo systemctl enable --now fstrim.timer >/dev/null 2>&1; bien "SSD detectado: TRIM semanal activado"
else bien "Disco mecánico: TRIM no aplica"; fi

paso "GRUB más rápido"
if [ -f /etc/default/grub ] && grep -q '^GRUB_TIMEOUT=' /etc/default/grub; then
  respaldar /etc/default/grub
  sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
  sudo update-grub >/dev/null 2>&1; bien "Menú de arranque: 2 segundos"
else aviso "GRUB no encontrado, se omite"; fi

paso "Servicios que casi nadie usa en casa"
for s in ModemManager.service whoopsie.service apport.service kerneloops.service; do
  systemctl list-unit-files "$s" >/dev/null 2>&1 && sudo systemctl disable --now "$s" >/dev/null 2>&1
done
bien "Desactivados: módem 3G, reportes de errores (si existían)"

titulo "Limpieza"
paso "Paquetes huérfanos y caché"
sudo apt-get autoremove --purge -y -qq >/dev/null 2>&1; sudo apt-get clean
rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null
bien "Paquetes sobrantes y miniaturas eliminados"
if command -v snap >/dev/null; then
  paso "Versiones viejas de snap"
  sudo snap set system refresh.retain=2 >/dev/null 2>&1
  snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read -r n v; do sudo snap remove "$n" --revision="$v" >/dev/null 2>&1; done
  bien "Snaps antiguos eliminados"
fi

# ═══════════════════════════ 2. ESTÉTICA ══════════════════════════
titulo "Apariencia del escritorio"
paso "Iconos, temas y fuentes"
instalar papirus-icon-theme arc-theme fonts-noto-core fonts-noto-color-emoji fonts-firacode \
  && bien "Papirus, Arc y fuentes Noto / Fira Code instalados" || aviso "Algunos paquetes no se instalaron"

LXQT="$HOME/.config/lxqt/lxqt.conf"
paso "Tema oscuro para LXQt"
mkdir -p "$(dirname "$LXQT")"; respaldar "$LXQT"; touch "$LXQT"
grep -q '^\[General\]' "$LXQT" || printf "[General]\n" >> "$LXQT"
poner() { # poner archivo sección clave valor
  if grep -q "^$3=" "$1"; then sed -i "s|^$3=.*|$3=$4|" "$1"
  else sed -i "/^\[$2\]/a $3=$4" "$1"; fi
}
poner "$LXQT" General icon_theme Papirus-Dark
for tema in Lubuntu\ Arc Arc-Dark Lubuntu dark; do
  [ -d "/usr/share/lxqt/themes/$tema" ] && { poner "$LXQT" General theme "$tema"; break; }
done
bien "Iconos Papirus-Dark aplicados"

paso "Aplicaciones GTK (Firefox, etc.) en oscuro"
for v in gtk-3.0 gtk-4.0; do
  f="$HOME/.config/$v/settings.ini"; mkdir -p "$(dirname "$f")"; respaldar "$f"
  cat > "$f" <<'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=1
EOF
done
respaldar "$HOME/.gtkrc-2.0"
printf 'gtk-theme-name="Arc-Dark"\ngtk-icon-theme-name="Papirus-Dark"\ngtk-font-name="Noto Sans 10"\n' > "$HOME/.gtkrc-2.0"
bien "GTK con Arc-Dark"

QT="$HOME/.config/qterminal.org/qterminal.ini"
paso "QTerminal bonito"
mkdir -p "$(dirname "$QT")"; respaldar "$QT"; touch "$QT"
grep -q '^\[General\]' "$QT" || printf "[General]\n" >> "$QT"
poner "$QT" General colorScheme DarkPastels
poner "$QT" General fontFamily "Fira Code"
poner "$QT" General fontSize 11
poner "$QT" General ApplicationTransparency 8
poner "$QT" General TerminalMargin 8
bien "Esquema DarkPastels, Fira Code, leve transparencia"

titulo "Terminal con estilo"
paso "Herramientas: fastfetch/neofetch, bat, btop"
instalar fastfetch || instalar neofetch
instalar bat btop || instalar htop
bien "Herramientas instaladas"

respaldar "$HOME/.bashrc"
sed -i '/# >>> optimizador-lubuntu >>>/,/# <<< optimizador-lubuntu <<</d' "$HOME/.bashrc"
cat >> "$HOME/.bashrc" <<'EOF'
# >>> optimizador-lubuntu >>>
__prompt() {
  local s=$? git=""
  local b; b=$(git symbolic-ref --short HEAD 2>/dev/null) && git=" \[\e[38;5;215m\] $b"
  local flecha="\[\e[38;5;114m\]❯"; [ $s -ne 0 ] && flecha="\[\e[38;5;204m\]❯"
  PS1="\n\[\e[38;5;141m\]╭─ \[\e[1m\]\u\[\e[22m\] \[\e[38;5;117m\] \w${git}\n\[\e[38;5;141m\]╰─${flecha}\[\e[0m\] "
}
PROMPT_COMMAND=__prompt
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lhF'
alias la='ls -lhAF'
alias grep='grep --color=auto'
alias ..='cd ..'
command -v batcat >/dev/null && alias cat='batcat --paging=never --style=plain'
alias actualizar='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y'
alias limpiar='sudo apt autoremove --purge -y && sudo apt clean && rm -rf ~/.cache/thumbnails/*'
alias ram='free -h'
[ -z "${__SALUDO:-}" ] && export __SALUDO=1 && { command -v fastfetch >/dev/null && fastfetch || { command -v neofetch >/dev/null && neofetch; }; }
# <<< optimizador-lubuntu <<<
EOF
bien "Prompt de dos líneas con colores, rama de git y alias útiles"

# ═══════════════════════════ RESUMEN ══════════════════════════════
RAM_DESPUES=$(ram_libre); DISCO_DESPUES=$(df -m / | awk 'NR==2{print $4}')
printf "\n${C1}${B}╰─ ¡Listo!${R}\n\n"
printf "   ${B}RAM disponible${R}   %s MB → ${OK}%s MB${R}\n" "$RAM_ANTES" "$RAM_DESPUES"
printf "   ${B}Disco libre${R}      %s MB → ${OK}%s MB${R}\n" "$DISCO_ANTES" "$DISCO_DESPUES"
printf "   ${B}Swap (zram)${R}      %s\n" "$(swapon --show=NAME,SIZE --noheadings 2>/dev/null | tr '\n' ' ')"
printf "\n   ${D}Respaldo de tus configuraciones: %s${R}\n" "$RESPALDO"
printf "   ${WARN}Cierra sesión y vuelve a entrar (o reinicia) para ver todo el cambio.${R}\n\n"
