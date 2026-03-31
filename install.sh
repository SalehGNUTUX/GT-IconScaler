#!/bin/bash
# ============================================================
# GT-IconScaler Installer v2.0 (Full)
# يقوم بتثبيت الأداة وفحص المتطلبات تلقائياً
# يدعم: apt, dnf, pacman, zypper
# يقوم بتحميل الملفات المفقودة من المستودع إذا لزم الأمر
# ============================================================

set -euo pipefail

# ────────────────────────────────────────────────────────────
# الألوان والرسائل
# ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*" >&2; }
error() { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

# ────────────────────────────────────────────────────────────
# كشف نظام التشغيل ومدير الحزم
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
        error "لم أتمكن من اكتشاف مدير حزم مدعوم (apt, dnf, pacman, zypper). الرجاء تثبيت ImageMagick و zenity يدوياً."
    fi
}

# ────────────────────────────────────────────────────────────
# التحقق من وجود الأوامر المطلوبة
# ────────────────────────────────────────────────────────────
check_requirements() {
    local missing=()
    for cmd in convert zenity; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        success "جميع المتطلبات موجودة مسبقاً."
        return 0
    fi

    warn "المتطلبات التالية غير مثبتة: ${missing[*]}"
    echo -n "هل تريد تثبيتها تلقائياً؟ (y/n): "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        detect_package_manager
        info "تحديث قائمة الحزم..."
        $UPDATE_CMD
        info "تثبيت: $PKGS"
        $INSTALL_CMD $PKGS
    else
        error "الرجاء تثبيت المتطلبات يدوياً ثم أعد تشغيل المثبت."
    fi
}

# ────────────────────────────────────────────────────────────
# إنشاء المجلدات الأساسية (للتوافق مع السكربتات القديمة)
# ────────────────────────────────────────────────────────────
create_dirs() {
    local dirs=(bin src include lib)
    for d in "${dirs[@]}"; do
        if [[ ! -d "$d" ]]; then
            mkdir -p "$d"
            info "أنشئ المجلد: $d"
        fi
    done
}

# ────────────────────────────────────────────────────────────
# تحديد مسار التثبيت (نظامي أو للمستخدم)
# ────────────────────────────────────────────────────────────
setup_install_paths() {
    if [[ $EUID -eq 0 ]]; then
        # تثبيت نظامي
        BIN_DIR="/usr/local/bin"
        ICON_DIR="/usr/share/icons/hicolor"
        DESKTOP_DIR="/usr/share/applications"
        info "سيتم التثبيت بشكل نظامي (sudo)."
    else
        # تثبيت محلي للمستخدم
        BIN_DIR="$HOME/.local/bin"
        ICON_DIR="$HOME/.local/share/icons/hicolor"
        DESKTOP_DIR="$HOME/.local/share/applications"
        info "سيتم التثبيت محلياً للمستخدم الحالي."
        mkdir -p "$BIN_DIR" "$ICON_DIR" "$DESKTOP_DIR"
        # إضافة ~/.local/bin إلى PATH إذا لم تكن موجودة
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
            warn "تمت إضافة $HOME/.local/bin إلى PATH. أعد تشغيل الطرفية أو نفذ: source ~/.bashrc"
        fi
    fi
}

# ────────────────────────────────────────────────────────────
# تحميل ملف من المستودع إذا لم يكن موجوداً
# ────────────────────────────────────────────────────────────
download_if_missing() {
    local file="$1"
    local base_url="https://raw.githubusercontent.com/SalehGNUTUX/GT-IconScaler/main"
    if [[ ! -f "$file" ]]; then
        info "تحميل $file من المستودع..."
        curl -sSL -o "$file" "$base_url/$file" || return 1
    fi
    return 0
}

# ────────────────────────────────────────────────────────────
# تثبيت السكربتات (تحميلها إذا لزم الأمر)
# ────────────────────────────────────────────────────────────
install_scripts() {
    local scripts=("GT-IconScaler.sh" "GT-IconScaler-GUI.sh")
    local target_names=("gt-iconscaler" "gt-iconscaler-gui")

    for i in "${!scripts[@]}"; do
        local src="${scripts[$i]}"
        local dst="${BIN_DIR}/${target_names[$i]}"
        
        # تحميل الملف إذا لم يكن موجوداً محلياً
        if ! download_if_missing "$src"; then
            warn "فشل تحميل $src. تخطي."
            continue
        fi
        
        if [[ -f "$src" ]]; then
            cp "$src" "$dst"
            chmod +x "$dst"
            success "ثبّت: $dst"
        else
            warn "الملف $src غير موجود بعد المحاولة. تخطي."
        fi
    done
}

# ────────────────────────────────────────────────────────────
# تثبيت أيقونة التطبيق (تحميلها إذا لزم الأمر)
# ────────────────────────────────────────────────────────────
install_icon() {
    local icon_file="gt-iconscaler-gui.png"
    
    # تحميل الأيقونة إذا لم تكن موجودة
    download_if_missing "$icon_file" || true
    
    # إذا لم تنجح التحميلة أو الملف لا يزال غير موجود، أنشئ أيقونة افتراضية
    if [[ ! -f "$icon_file" ]]; then
        if command -v convert &>/dev/null; then
            convert -size 128x128 xc:transparent -font DejaVu-Sans -pointsize 40 -fill black -gravity center -annotate 0 "🎨" "$icon_file" 2>/dev/null || true
        fi
    fi

    if [[ -f "$icon_file" ]]; then
        local sizes=(16 22 24 32 48 64 96 128 256 512)
        for size in "${sizes[@]}"; do
            local dir="$ICON_DIR/${size}x${size}/apps"
            mkdir -p "$dir"
            convert "$icon_file" -resize "${size}x${size}" "$dir/gt-iconscaler-gui.png" 2>/dev/null || true
        done
        success "ثبّت الأيقونة."
    else
        warn "لا توجد أيقونة للتطبيق. يمكنك وضع ملف gt-iconscaler-gui.png في المجلد الرئيسي."
    fi
}

# ────────────────────────────────────────────────────────────
# إنشاء ملف .desktop للنسخة الرسومية
# ────────────────────────────────────────────────────────────
create_desktop_entry() {
    local desktop_file="$DESKTOP_DIR/gt-iconscaler-gui.desktop"
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=GT-IconScaler GUI
Comment=Generate icons for all platforms (GUI)
Exec=${BIN_DIR}/gt-iconscaler-gui
Icon=gt-iconscaler-gui
Terminal=false
Categories=Utility;Graphics;Development;
Keywords=icon;scaler;converter;
GenericName=Icon Scaler
StartupNotify=true

# Arabic translations
Name[ar]=GT-IconScaler - الواجهة الرسومية
Comment[ar]=توليد أيقونات لجميع المنصات (واجهة رسومية)
EOF
    chmod +x "$desktop_file"
    success "أنشأ ملف سطح المكتب: $desktop_file"
}

# ────────────────────────────────────────────────────────────
# تحديث ذاكرة التخزين المؤقت للأيقونات وقاعدة بيانات سطح المكتب
# ────────────────────────────────────────────────────────────
update_caches() {
    if command -v update-icon-caches &>/dev/null; then
        update-icon-caches "$ICON_DIR" 2>/dev/null || true
    fi
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    fi
    success "تم تحديث ذاكرة التخزين المؤقت."
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
    echo -e "    • ${GREEN}gt-iconscaler-gui${NC} - النسخة الرسومية"
    echo ""
    echo -e "  ${BLUE}لتشغيل النسخة الطرفية:${NC}"
    echo "    gt-iconscaler"
    echo ""
    echo -e "  ${BLUE}لتشغيل النسخة الرسومية:${NC}"
    echo "    gt-iconscaler-gui"
    echo ""
    echo -e "  ${YELLOW}ملاحظة:${NC} إذا لم تتعرف الطرفية على الأوامر، أعد تشغيلها أو نفذ:"
    echo "    source ~/.bashrc  (أو source ~/.zshrc)"
    echo ""
    echo -e "  ${BLUE}ملاحظة للأيقونة:${NC} إذا لم تظهر الأيقونة في قائمة البرامج، حاول تسجيل الخروج والدخول مرة أخرى."
}

# ────────────────────────────────────────────────────────────
# البرنامج الرئيسي
# ────────────────────────────────────────────────────────────
main() {
    echo -e "${BLUE}GT-IconScaler Installer v2.0 (Full)${NC}"
    echo ""

    # التحقق من المتطلبات الأساسية
    check_requirements

    # إنشاء المجلدات (للتوافق مع setup.sh)
    create_dirs

    # تحديد مسارات التثبيت
    setup_install_paths

    # تثبيت السكربتات (مع تحميلها إذا لزم الأمر)
    install_scripts

    # تثبيت الأيقونة (مع تحميلها إذا لزم الأمر)
    install_icon

    # إنشاء ملف .desktop للواجهة الرسومية
    create_desktop_entry

    # تحديث الكاش
    update_caches

    # عرض الملخص
    print_summary
}

main "$@"
