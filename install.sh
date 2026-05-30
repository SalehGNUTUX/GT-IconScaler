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
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC} $*" >&2; }
error()   { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

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
    exec bash "$tmp_dir/install.sh" "$@"
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
# كشف مدير الحزم وتثبيت المتطلبات
# ────────────────────────────────────────────────────────────
detect_package_manager() {
    if command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
        UPDATE_CMD="sudo apt update"
        PKGS="imagemagick zenity"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf check-update || true"
        PKGS="ImageMagick zenity"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        UPDATE_CMD="sudo pacman -Sy"
        PKGS="imagemagick zenity"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"
        INSTALL_CMD="sudo zypper install -y"
        UPDATE_CMD="sudo zypper refresh"
        PKGS="ImageMagick zenity"
    else
        error "لم أتمكن من اكتشاف مدير حزم مدعوم (apt/dnf/pacman/zypper). ثبّت ImageMagick و zenity يدوياً."
    fi
}

# IM7 يستخدم 'magick'، IM6 يستخدم 'convert' — كلاهما مقبول
has_imagemagick() {
    command -v convert &>/dev/null || command -v magick &>/dev/null
}

check_requirements() {
    local missing=()
    has_imagemagick || missing+=("ImageMagick")
    command -v zenity &>/dev/null || missing+=("zenity")

    if [[ ${#missing[@]} -eq 0 ]]; then
        success "جميع المتطلبات موجودة مسبقاً."
        return 0
    fi

    warn "المتطلبات التالية غير مثبتة: ${missing[*]}"
    read -rp "هل تريد تثبيتها تلقائياً؟ (y/n): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        detect_package_manager
        info "تحديث قائمة الحزم..."
        $UPDATE_CMD
        info "تثبيت: $PKGS"
        $INSTALL_CMD $PKGS
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
    install -m 755 "$SCRIPT_DIR/GT-IconScaler.sh"     "$BIN_DIR/gt-iconscaler"
    install -m 755 "$SCRIPT_DIR/GT-IconScaler-GUI.sh" "$BIN_DIR/gt-iconscaler-gui"
    success "ثبّت: $BIN_DIR/gt-iconscaler"
    success "ثبّت: $BIN_DIR/gt-iconscaler-gui"
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

    # خريطة: اسم_الأيقونة_في_النظام → مجلد_مصدر_الأيقونة
    declare -A icon_sources=(
        ["gt-iconscaler-cli"]="$SCRIPT_DIR/GT-IconScaler-CLI-ICON-icons/all"
        ["gt-iconscaler-gui"]="$SCRIPT_DIR/GT-IconScaler-GUI-ICON-icons/all"
    )
    declare -A icon_filenames=(
        ["gt-iconscaler-cli"]="GT-IconScaler-CLI-ICON.png"
        ["gt-iconscaler-gui"]="GT-IconScaler-GUI-ICON.png"
    )

    for icon_name in "${!icon_sources[@]}"; do
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
    local cli_desktop="$DESKTOP_DIR/gt-iconscaler-cli.desktop"
    local gui_desktop="$DESKTOP_DIR/gt-iconscaler-gui.desktop"

    # CLI: نسخ + تعديل Exec إلى المسار الكامل
    install -m 644 "$SCRIPT_DIR/gt-iconscaler-cli.desktop" "$cli_desktop"
    sed -i "s|^Exec=.*|Exec=${BIN_DIR}/gt-iconscaler|"          "$cli_desktop"
    sed -i "s|^TryExec=.*|TryExec=${BIN_DIR}/gt-iconscaler|"    "$cli_desktop"

    # GUI: نسخ + تعديل Exec
    install -m 644 "$SCRIPT_DIR/gt-iconscaler-gui.desktop" "$gui_desktop"
    sed -i "s|^Exec=.*|Exec=${BIN_DIR}/gt-iconscaler-gui|" "$gui_desktop"

    success "ثبّت: $cli_desktop"
    success "ثبّت: $gui_desktop"
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
    echo -e "    • ${GREEN}gt-iconscaler${NC}      - النسخة الطرفية"
    echo -e "    • ${GREEN}gt-iconscaler-gui${NC}  - النسخة الرسومية"
    echo ""
    echo -e "  ${YELLOW}ملاحظة:${NC} إذا لم تظهر الأيقونات في قائمة البرامج فوراً، سجّل الخروج والدخول"
    echo "          (أو أعد تشغيل GNOME Shell بـ Alt+F2 → r)"
    echo ""
}

# ────────────────────────────────────────────────────────────
# البرنامج الرئيسي
# ────────────────────────────────────────────────────────────
main() {
    echo -e "${BLUE}GT-IconScaler Installer v2.2.0${NC}"
    echo ""

    check_source_files "$@"
    check_requirements
    setup_install_paths
    install_scripts
    install_libs
    install_icons
    install_desktop_entries
    update_caches
    print_summary
}

main "$@"
