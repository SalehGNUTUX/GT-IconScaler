#!/usr/bin/env bash
# ============================================================
# GT-IconScaler Installer v2.2.0
# تثبيت آلي مع كشف مدير الحزم واستخدام الأيقونات الحقيقية
# يدعم: apt, dnf, pacman, zypper
# يدعم وضع التشغيل عبر `bash <(curl -sSL .../install.sh)`
# ============================================================

set -euo pipefail

# ────────────────────────────────────────────────────────────
# الألوان والرسائل
# ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC} $*" >&2; }
error()   { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

# ────────────────────────────────────────────────────────────
# وسائط سطر الأوامر — اختيار النسخة
# ────────────────────────────────────────────────────────────
INSTALL_CLI=1      # افتراضياً نثبّت الاثنين
INSTALL_GUI=1
AUTO_YES=0         # -y → لا تسأل، استخدم الافتراضي

ORIG_ARGS=("$@")   # نحفظها لتمريرها عند bootstrap_from_remote

show_install_help() {
    cat <<HELP
GT-IconScaler Installer — usage:

  install.sh                Interactive: prompts which version to install
  install.sh --all          Install BOTH CLI and Zenity GUI (default if -y)
  install.sh --cli          Install CLI only
  install.sh --gui          Install Zenity GUI only
  install.sh -y, --yes      Non-interactive: assume defaults (--all + auto-install deps)
  install.sh -h, --help     Show this help

Examples:
  bash <(curl -sSL .../install.sh)              # interactive
  bash <(curl -sSL .../install.sh) --cli -y     # CLI only, no prompts
  sudo bash install.sh --all -y                 # system-wide, both, no prompts
HELP
}

# parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)            INSTALL_CLI=1; INSTALL_GUI=1 ;;
        --cli)            INSTALL_CLI=1; INSTALL_GUI=0 ;;
        --gui)            INSTALL_CLI=0; INSTALL_GUI=1 ;;
        -y|--yes)         AUTO_YES=1 ;;
        -h|--help)        show_install_help; exit 0 ;;
        *) warn "خيار غير معروف: $1 (استخدم --help)"; ;;
    esac
    shift
done

# علم داخلي: هل المستخدم مرّر اختياراً صريحاً؟
EXPLICIT_CHOICE=0
for arg in "${ORIG_ARGS[@]}"; do
    case "$arg" in
        --all|--cli|--gui) EXPLICIT_CHOICE=1; break ;;
    esac
done

# ────────────────────────────────────────────────────────────
# تحديد دليل المشروع (حيث يقع هذا السكربت)
# ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# التحقق من أن السكربت يعمل من داخل مستودع مستنسخ
REQUIRED_FILES=(
    "GT-IconScaler.sh"
    "GT-IconScaler-GUI.sh"
    "gt-iconscaler-cli.desktop"
    "gt-iconscaler-gui.desktop"
    "GT-IconScaler-CLI-ICON-icons"
    "GT-IconScaler-GUI-ICON-icons"
    "lib/gt-iconscaler-core.sh"
    "lib/gt-iconscaler-formats.sh"
    "lib/gt-iconscaler-i18n.sh"
    "lib/i18n-ar.sh"
    "lib/i18n-en.sh"
)

# استنساخ الريبو لمجلد مؤقت ثم إعادة تشغيل install.sh منه
# مُستخدَم عند: bash <(curl -sSL .../install.sh)
# يمرّر ORIG_ARGS لينقل خيارات المستخدم (--cli/--gui/-y) للسكربت المستنسخ
bootstrap_from_remote() {
    local repo_url="https://github.com/SalehGNUTUX/GT-IconScaler.git"
    local branch="main"

    info "وضع التثبيت عبر curl — سيتم تنزيل المستودع لمجلد مؤقت."

    if ! command -v git &>/dev/null; then
        error "git غير مثبت. ثبّته أولاً: sudo apt install git (أو ما يقابله) ثم أعد تشغيل الأمر."
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d -t gt-iconscaler-install-XXXXXX) || error "تعذّر إنشاء مجلد مؤقت."
    info "تنزيل من $repo_url إلى $tmp_dir ..."
    if ! git clone --depth 1 --branch "$branch" "$repo_url" "$tmp_dir" 2>&1; then
        error "فشل clone من $repo_url"
    fi

    success "اكتمل التنزيل. تشغيل install.sh من النسخة المُنزَّلة..."
    echo ""
    exec bash "$tmp_dir/install.sh" "${ORIG_ARGS[@]}"
}

# اختيار النسخة بشكل تفاعلي إذا لم يُمرّر --cli/--gui/--all
choose_components() {
    # لو المستخدم مرّر اختياراً صريحاً أو -y، نحترمه
    if [[ $EXPLICIT_CHOICE -eq 1 || $AUTO_YES -eq 1 ]]; then
        return
    fi
    # لو stdin ليس tty (curl|bash بدون tty مربوط)، استخدم الافتراضي
    if [[ ! -t 0 ]]; then
        info "وضع غير تفاعلي — التثبيت الافتراضي (CLI + GUI)."
        return
    fi

    echo ""
    echo -e "${BOLD}${BLUE}ما النسخة التي تريد تثبيتها؟${NC}"
    echo "  ${BOLD}[1]${NC} نسخة الطرفية (CLI) — تفاعلية في terminal، تدعم batch mode + JSON"
    echo "  ${BOLD}[2]${NC} نسخة Zenity (GUI) — نوافذ رسومية تقليدية"
    echo "  ${BOLD}[3]${NC} كلاهما (موصى به)"
    echo ""
    local choice
    read -rp "  اختر [1/2/3, افتراضي: 3]: " choice
    choice="${choice:-3}"
    case "$choice" in
        1) INSTALL_CLI=1; INSTALL_GUI=0; info "اختيارك: CLI فقط" ;;
        2) INSTALL_CLI=0; INSTALL_GUI=1; info "اختيارك: GUI (zenity) فقط" ;;
        3|*) INSTALL_CLI=1; INSTALL_GUI=1; info "اختيارك: كلاهما" ;;
    esac
    echo ""
}

check_source_files() {
    local missing=()
    for f in "${REQUIRED_FILES[@]}"; do
        [[ ! -e "$SCRIPT_DIR/$f" ]] && missing+=("$f")
    done

    # كل الملفات الأساسية مفقودة ⇒ المستخدم على الأرجح يشغّل عبر curl|bash
    # نُعيد التشغيل من نسخة مستنسخة من GitHub
    if [[ ${#missing[@]} -eq ${#REQUIRED_FILES[@]} ]]; then
        bootstrap_from_remote "$@"
        # exec لا يعود، لكن للسلامة:
        exit 1
    fi

    # مفقود جزئياً ⇒ نسخة معطوبة أو غير مكتملة
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "ملفات المصدر التالية غير موجودة بجانب install.sh:"
        printf '  - %s\n' "${missing[@]}"
        echo ""
        info "يبدو أن النسخة المحلية ناقصة. الرجاء استنساخ المستودع كاملاً:"
        echo ""
        echo "  git clone https://github.com/SalehGNUTUX/GT-IconScaler.git"
        echo "  cd GT-IconScaler"
        echo "  ./install.sh"
        echo ""
        exit 1
    fi
}

# ────────────────────────────────────────────────────────────
# كشف مدير الحزم — يضبط: PKG_MANAGER, INSTALL_CMD, UPDATE_CMD, IM_PKG, ZENITY_PKG
# ────────────────────────────────────────────────────────────
detect_package_manager() {
    if command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
        UPDATE_CMD="sudo apt update"
        IM_PKG="imagemagick"
        ZENITY_PKG="zenity"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf check-update || true"
        IM_PKG="ImageMagick"
        ZENITY_PKG="zenity"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        UPDATE_CMD="sudo pacman -Sy"
        IM_PKG="imagemagick"
        ZENITY_PKG="zenity"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"
        INSTALL_CMD="sudo zypper install -y"
        UPDATE_CMD="sudo zypper refresh"
        IM_PKG="ImageMagick"
        ZENITY_PKG="zenity"
    elif command -v apk &>/dev/null; then
        PKG_MANAGER="apk"
        INSTALL_CMD="sudo apk add"
        UPDATE_CMD="sudo apk update"
        IM_PKG="imagemagick"
        ZENITY_PKG="zenity"
    else
        PKG_MANAGER=""
    fi
}

# IM7 يستخدم 'magick'، IM6 يستخدم 'convert' — كلاهما مقبول
has_imagemagick() {
    command -v convert &>/dev/null || command -v magick &>/dev/null
}

# يبني قائمة الحزم الفعلية المطلوبة بناءً على الاختيار + ما هو مفقود
build_deps_list() {
    detect_package_manager
    DEPS_TO_INSTALL=()
    DEPS_HUMAN=()      # أسماء عرض

    # ImageMagick — مطلوب لكلا النسختين
    if ! has_imagemagick; then
        if [[ -n "$PKG_MANAGER" ]]; then DEPS_TO_INSTALL+=("$IM_PKG"); fi
        DEPS_HUMAN+=("ImageMagick (إلزامي)")
    fi

    # zenity — إلزامي للـ GUI، موصى به للـ CLI (الـ file picker)
    if ! command -v zenity &>/dev/null; then
        if [[ $INSTALL_GUI -eq 1 ]]; then
            if [[ -n "$PKG_MANAGER" ]]; then DEPS_TO_INSTALL+=("$ZENITY_PKG"); fi
            DEPS_HUMAN+=("zenity (إلزامي للـ GUI)")
        elif [[ $INSTALL_CLI -eq 1 ]]; then
            # CLI يعمل بدون zenity (له fallback لـ kdialog/yad/read)
            # لكن نُبلّغ المستخدم أنه موصى به
            DEPS_RECOMMENDED+=("zenity (اختياري للـ CLI — للـ file picker)")
        fi
    fi
}

check_requirements() {
    declare -ga DEPS_TO_INSTALL=()
    declare -ga DEPS_HUMAN=()
    declare -ga DEPS_RECOMMENDED=()

    build_deps_list

    if [[ ${#DEPS_HUMAN[@]} -eq 0 && ${#DEPS_RECOMMENDED[@]} -eq 0 ]]; then
        success "جميع المتطلبات موجودة مسبقاً."
        return 0
    fi

    # عرض الاعتماديات الموصى بها (لا توقف، فقط تنبيه)
    if [[ ${#DEPS_RECOMMENDED[@]} -gt 0 ]]; then
        warn "اعتمادية موصى بها (اختيارية):"
        printf "  • %s\n" "${DEPS_RECOMMENDED[@]}"
    fi

    # لا اعتماديات إلزامية مفقودة؟ نكمل
    if [[ ${#DEPS_HUMAN[@]} -eq 0 ]]; then
        return 0
    fi

    warn "المتطلبات الإلزامية الناقصة:"
    printf "  • %s\n" "${DEPS_HUMAN[@]}"
    echo ""

    if [[ -z "$PKG_MANAGER" ]]; then
        error "لم أتمكن من اكتشاف مدير حزم مدعوم (apt/dnf/pacman/zypper/apk). ثبّت المتطلبات يدوياً."
    fi

    info "مدير الحزم المكتشف: $PKG_MANAGER → سيُثبَّت: ${DEPS_TO_INSTALL[*]}"

    local answer="y"
    if [[ $AUTO_YES -eq 0 && -t 0 ]]; then
        read -rp "هل تريد تثبيتها تلقائياً عبر $PKG_MANAGER؟ (Y/n): " answer
        answer="${answer:-y}"
    fi

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "تحديث قائمة الحزم..."
        $UPDATE_CMD || warn "تعذّر تحديث الفهرس — أحاول التثبيت رغم ذلك..."
        info "تثبيت: ${DEPS_TO_INSTALL[*]}"
        $INSTALL_CMD "${DEPS_TO_INSTALL[@]}" || error "فشل تثبيت الاعتماديات. ثبّتها يدوياً ثم أعد المحاولة."
        success "تم تثبيت الاعتماديات."
    else
        error "ثبّت المتطلبات يدوياً ثم أعد تشغيل المثبت."
    fi
}

# ────────────────────────────────────────────────────────────
# تحديد مسارات التثبيت (نظامي أو للمستخدم)
# ────────────────────────────────────────────────────────────
setup_install_paths() {
    if [[ $EUID -eq 0 ]]; then
        BIN_DIR="/usr/local/bin"
        ICON_DIR="/usr/share/icons/hicolor"
        DESKTOP_DIR="/usr/share/applications"
        SHARE_DIR="/usr/local/share/gt-iconscaler"
        SCOPE="نظامي (لجميع المستخدمين)"
    else
        BIN_DIR="$HOME/.local/bin"
        ICON_DIR="$HOME/.local/share/icons/hicolor"
        DESKTOP_DIR="$HOME/.local/share/applications"
        SHARE_DIR="$HOME/.local/share/gt-iconscaler"
        SCOPE="محلي (المستخدم الحالي فقط)"
        mkdir -p "$BIN_DIR" "$ICON_DIR" "$DESKTOP_DIR" "$SHARE_DIR"

        # إضافة ~/.local/bin إلى PATH عند الحاجة
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
                [[ -f "$rc" ]] || continue
                grep -q '\.local/bin' "$rc" 2>/dev/null && continue
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
                info "تمت إضافة \$HOME/.local/bin إلى $rc"
            done
            warn "أعد تشغيل الطرفية أو نفّذ: source ~/.bashrc"
        fi
    fi
    info "نوع التثبيت: $SCOPE"
}

# ────────────────────────────────────────────────────────────
# تثبيت السكربتات (CLI + GUI)
# ────────────────────────────────────────────────────────────
install_scripts() {
    if [[ $INSTALL_CLI -eq 1 ]]; then
        install -m 755 "$SCRIPT_DIR/GT-IconScaler.sh" "$BIN_DIR/gt-iconscaler"
        success "ثبّت: $BIN_DIR/gt-iconscaler"
    fi
    if [[ $INSTALL_GUI -eq 1 ]]; then
        install -m 755 "$SCRIPT_DIR/GT-IconScaler-GUI.sh" "$BIN_DIR/gt-iconscaler-gui"
        success "ثبّت: $BIN_DIR/gt-iconscaler-gui"
    fi
}

# ────────────────────────────────────────────────────────────
# تثبيت wrapper لتشغيل CLI من قائمة البرامج
# يكتشف terminal emulator متاح ويبقي النافذة مفتوحة بعد الانتهاء
# (يحل مشكلة "لا يحدث شيء" عند النقر على .desktop ذي Terminal=true
#  في KDE/GNOME عندما لا يكون default terminal مضبوطاً)
# ────────────────────────────────────────────────────────────
install_cli_launcher() {
    [[ $INSTALL_CLI -eq 1 ]] || return 0
    local launcher="$BIN_DIR/gt-iconscaler-cli-launcher"
    cat > "$launcher" << 'LAUNCHER_EOF'
#!/usr/bin/env bash
# AUTO-GENERATED by GT-IconScaler install.sh — do not edit
# Universal terminal launcher for gt-iconscaler CLI.
# Works on KDE, GNOME, XFCE, MATE, Cinnamon, LXDE/LXQt, Deepin, elementary,
# sway/wayland, X11 fallback — supports 14+ terminal emulators.

# 1) أنشئ helper script مؤقت يحوي الأمر + رسالة pause + self-cleanup
#    (هذا يتفادى مشاكل quoting مع -e / -- لكل terminal)
INNER=$(mktemp -t gt-iconscaler-XXXXXX.sh) || exit 1
chmod 755 "$INNER"
cat > "$INNER" << 'INNER_EOF'
#!/usr/bin/env bash
gt-iconscaler "$@"
ec=$?
echo
echo "──────────────────────────────────────────"
read -n 1 -s -r -p "  Press any key to close / اضغط أي مفتاح للإغلاق  "
echo
rm -f "$0"
exit $ec
INNER_EOF

# 2) دالة موحّدة لتشغيل terminal باسمه
launch_with() {
    local term=$1
    case "$term" in
        gnome-terminal)   exec gnome-terminal -- "$INNER" ;;
        xfce4-terminal)   exec xfce4-terminal -e "$INNER" ;;
        *)                exec "$term" -e "$INNER" ;;
    esac
}

# 3a) أولاً: احترم متغير البيئة $TERMINAL (de facto standard)
if [[ -n "${TERMINAL:-}" ]] && command -v "$TERMINAL" &>/dev/null; then
    launch_with "$TERMINAL"
fi

# 3b) ثانياً: xdg-terminal-exec (freedesktop spec الحديث، لو متاح)
if command -v xdg-terminal-exec &>/dev/null; then
    exec xdg-terminal-exec "$INNER"
fi

# 3c) ثالثاً: أولوية terminal حسب desktop environment الحالي
PRIORITY=()
case "${XDG_CURRENT_DESKTOP,,}" in
    *kde*|*plasma*)   PRIORITY+=(konsole) ;;
    *gnome*|*unity*)  PRIORITY+=(gnome-terminal) ;;
    *xfce*)           PRIORITY+=(xfce4-terminal) ;;
    *mate*)           PRIORITY+=(mate-terminal) ;;
    *cinnamon*)       PRIORITY+=(gnome-terminal mate-terminal) ;;
    *lxqt*)           PRIORITY+=(qterminal) ;;
    *lxde*)           PRIORITY+=(lxterminal) ;;
    *deepin*)         PRIORITY+=(deepin-terminal) ;;
    *pantheon*)       PRIORITY+=(io.elementary.terminal) ;;
    *sway*|*wlroots*) PRIORITY+=(foot alacritty) ;;
esac

# 3d) Fallback شامل: 14 terminal emulator، مرتبة من الأكثر شيوعاً
FALLBACK=(konsole gnome-terminal xfce4-terminal mate-terminal lxterminal \
          qterminal deepin-terminal io.elementary.terminal tilix \
          alacritty kitty terminator foot \
          x-terminal-emulator xterm)

for term in "${PRIORITY[@]}" "${FALLBACK[@]}"; do
    command -v "$term" &>/dev/null && launch_with "$term"
done

# 4) لا terminal على الإطلاق — تنظيف + تنبيه
rm -f "$INNER"
if command -v zenity &>/dev/null; then
    zenity --error --no-wrap --title="GT-IconScaler" \
        --text="No terminal emulator found on this system.\n\nInstall any of: konsole, gnome-terminal, xfce4-terminal,\nmate-terminal, alacritty, kitty, foot, xterm...\n\nلم أجد terminal emulator مثبَّتاً.\nثبّت أحد البرامج التالية:\nkonsole, gnome-terminal, xfce4-terminal,\nmate-terminal, alacritty, kitty, foot, xterm" 2>/dev/null
fi
echo "ERROR: gt-iconscaler-cli-launcher — no terminal emulator found." >&2
exit 1
LAUNCHER_EOF
    chmod 755 "$launcher"
    success "ثبّت: $launcher (يدعم 14+ terminal emulator)"
}

# ────────────────────────────────────────────────────────────
# تثبيت المكتبات (lib/) وملفات الترجمة المسبقة البناء
# ────────────────────────────────────────────────────────────
install_libs() {
    mkdir -p "$SHARE_DIR/lib"
    for f in gt-iconscaler-core.sh gt-iconscaler-formats.sh gt-iconscaler-i18n.sh \
             i18n-ar.sh i18n-en.sh; do
        install -m 644 "$SCRIPT_DIR/lib/$f" "$SHARE_DIR/lib/$f"
    done
    success "ثبّت 5 ملفات مكتبة في: $SHARE_DIR/lib/"
}

# ────────────────────────────────────────────────────────────
# تثبيت أيقونتي CLI و GUI من الأيقونات الحقيقية الموجودة في المستودع
# ────────────────────────────────────────────────────────────
install_icons() {
    # الأحجام القياسية المعتمدة في FreeDesktop hicolor
    local sizes=(16 22 24 32 48 64 96 128 256 512)

    # نبني قائمة الأيقونات بناءً على الاختيار
    local icon_names=()
    declare -A icon_sources=()
    declare -A icon_filenames=()
    if [[ $INSTALL_CLI -eq 1 ]]; then
        icon_names+=("gt-iconscaler-cli")
        icon_sources["gt-iconscaler-cli"]="$SCRIPT_DIR/GT-IconScaler-CLI-ICON-icons/all"
        icon_filenames["gt-iconscaler-cli"]="GT-IconScaler-CLI-ICON.png"
    fi
    if [[ $INSTALL_GUI -eq 1 ]]; then
        icon_names+=("gt-iconscaler-gui")
        icon_sources["gt-iconscaler-gui"]="$SCRIPT_DIR/GT-IconScaler-GUI-ICON-icons/all"
        icon_filenames["gt-iconscaler-gui"]="GT-IconScaler-GUI-ICON.png"
    fi

    for icon_name in "${icon_names[@]}"; do
        local src_dir="${icon_sources[$icon_name]}"
        local src_file="${icon_filenames[$icon_name]}"

        if [[ ! -d "$src_dir" ]]; then
            warn "مجلد الأيقونات غير موجود: $src_dir"
            continue
        fi

        for size in "${sizes[@]}"; do
            local src="$src_dir/${size}x${size}/$src_file"
            local dst_dir="$ICON_DIR/${size}x${size}/apps"
            if [[ -f "$src" ]]; then
                mkdir -p "$dst_dir"
                install -m 644 "$src" "$dst_dir/${icon_name}.png"
            fi
        done
        success "ثبّت أيقونة: $icon_name (${#sizes[@]} مقاسات)"
    done
}

# ────────────────────────────────────────────────────────────
# تثبيت ملفات .desktop (مع تعديل Exec للمسار الصحيح)
# ────────────────────────────────────────────────────────────
install_desktop_entries() {
    if [[ $INSTALL_CLI -eq 1 ]]; then
        local cli_desktop="$DESKTOP_DIR/gt-iconscaler-cli.desktop"
        # CLI: يستخدم wrapper launcher بدل الاعتماد على Terminal=true
        # لأن KDE/GNOME قد لا يجدا default terminal فيظهر "لا يحدث شيء"
        install -m 644 "$SCRIPT_DIR/gt-iconscaler-cli.desktop" "$cli_desktop"
        sed -i "s|^Exec=.*|Exec=${BIN_DIR}/gt-iconscaler-cli-launcher|"       "$cli_desktop"
        sed -i "s|^TryExec=.*|TryExec=${BIN_DIR}/gt-iconscaler-cli-launcher|" "$cli_desktop"
        sed -i "s|^Terminal=true|Terminal=false|"                              "$cli_desktop"
        success "ثبّت: $cli_desktop"
    fi

    if [[ $INSTALL_GUI -eq 1 ]]; then
        local gui_desktop="$DESKTOP_DIR/gt-iconscaler-gui.desktop"
        # GUI: Exec المباشر لـ zenity-based script (لا حاجة لـ wrapper)
        install -m 644 "$SCRIPT_DIR/gt-iconscaler-gui.desktop" "$gui_desktop"
        sed -i "s|^Exec=.*|Exec=${BIN_DIR}/gt-iconscaler-gui|" "$gui_desktop"
        success "ثبّت: $gui_desktop"
    fi
}

# ────────────────────────────────────────────────────────────
# تحديث ذاكرة التخزين المؤقت
# ────────────────────────────────────────────────────────────
update_caches() {
    if command -v gtk-update-icon-cache &>/dev/null; then
        gtk-update-icon-cache -q -t -f "$ICON_DIR" 2>/dev/null || true
    elif command -v update-icon-caches &>/dev/null; then
        update-icon-caches "$ICON_DIR" 2>/dev/null || true
    fi
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    fi
    success "تم تحديث ذاكرة الأيقونات وقاعدة بيانات سطح المكتب."
}

# ────────────────────────────────────────────────────────────
# الملخص النهائي
# ────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} تم تثبيت GT-IconScaler بنجاح!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "  ${BLUE}الأوامر المتاحة:${NC}"
    [[ $INSTALL_CLI -eq 1 ]] && echo -e "    • ${GREEN}gt-iconscaler${NC}      - النسخة الطرفية (CLI، تفاعلية + batch + --json)"
    [[ $INSTALL_GUI -eq 1 ]] && echo -e "    • ${GREEN}gt-iconscaler-gui${NC}  - النسخة الرسومية (Zenity)"
    echo ""
    echo -e "  ${YELLOW}ملاحظة:${NC} إذا لم تظهر الأيقونات في قائمة البرامج فوراً، سجّل الخروج والدخول"
    echo "          (أو على GNOME: Alt+F2 → r، أو على KDE: kbuildsycoca6)"
    echo ""
}

# ────────────────────────────────────────────────────────────
# البرنامج الرئيسي
# ────────────────────────────────────────────────────────────
main() {
    echo -e "${BLUE}${BOLD}GT-IconScaler Installer v2.2.0${NC}"
    echo ""

    check_source_files "${ORIG_ARGS[@]}"
    choose_components
    check_requirements
    setup_install_paths
    install_scripts
    install_cli_launcher
    install_libs
    install_icons
    install_desktop_entries
    update_caches
    print_summary
}

main
