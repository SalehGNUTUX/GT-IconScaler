#!/usr/bin/env bash
# ============================================================
# GT-IconScaler Uninstaller v2.0.1
# يحذف جميع الملفات المثبّتة من نسختي المستخدم والنظام
# ============================================================

set -euo pipefail

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC} $*" >&2; }

# ────────────────────────────────────────────────────────────
# الأسماء المثبّتة
# ────────────────────────────────────────────────────────────
BINARIES=("gt-iconscaler" "gt-iconscaler-gui")
DESKTOP_FILES=("gt-iconscaler-cli.desktop" "gt-iconscaler-gui.desktop")
ICON_NAMES=("gt-iconscaler-cli" "gt-iconscaler-gui")
ICON_SIZES=(16 22 24 32 48 64 96 128 256 512)

# ────────────────────────────────────────────────────────────
# تحديد مسارات الحذف حسب الصلاحية
# ────────────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    BIN_DIR="/usr/local/bin"
    ICON_DIR="/usr/share/icons/hicolor"
    DESKTOP_DIR="/usr/share/applications"
    SHARE_DIR="/usr/local/share/gt-iconscaler"
    SCOPE="نظامي"
else
    BIN_DIR="$HOME/.local/bin"
    ICON_DIR="$HOME/.local/share/icons/hicolor"
    DESKTOP_DIR="$HOME/.local/share/applications"
    SHARE_DIR="$HOME/.local/share/gt-iconscaler"
    SCOPE="محلي"
fi

# ────────────────────────────────────────────────────────────
# الترحيب والتأكيد
# ────────────────────────────────────────────────────────────
echo -e "${BLUE}GT-IconScaler Uninstaller${NC}"
echo ""
echo "سيتم حذف ($SCOPE):"
echo "  - الملفات التنفيذية من: $BIN_DIR"
echo "  - ملفات .desktop من:   $DESKTOP_DIR"
echo "  - الأيقونات من:         $ICON_DIR"
echo "  - المكتبات من:          $SHARE_DIR"
echo ""
read -rp "هل تريد المتابعة؟ (y/n): " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo -e "${RED}تم إلغاء العملية.${NC}"
    exit 0
fi

# ────────────────────────────────────────────────────────────
# الحذف
# ────────────────────────────────────────────────────────────
removed=0
not_found=0

# حذف الملفات التنفيذية
for bin in "${BINARIES[@]}"; do
    if [[ -f "$BIN_DIR/$bin" ]]; then
        rm -f "$BIN_DIR/$bin"
        success "حُذف: $BIN_DIR/$bin"
        (( removed++ )) || true
    else
        (( not_found++ )) || true
    fi
done

# حذف ملفات .desktop
for d in "${DESKTOP_FILES[@]}"; do
    if [[ -f "$DESKTOP_DIR/$d" ]]; then
        rm -f "$DESKTOP_DIR/$d"
        success "حُذف: $DESKTOP_DIR/$d"
        (( removed++ )) || true
    else
        (( not_found++ )) || true
    fi
done

# حذف الأيقونات بجميع مقاساتها
for icon in "${ICON_NAMES[@]}"; do
    for size in "${ICON_SIZES[@]}"; do
        f="$ICON_DIR/${size}x${size}/apps/${icon}.png"
        if [[ -f "$f" ]]; then
            rm -f "$f"
            (( removed++ )) || true
        fi
    done
done
[[ $removed -gt 0 ]] && success "حُذفت الأيقونات لجميع المقاسات."

# حذف مجلد المكتبات
if [[ -d "$SHARE_DIR" ]]; then
    rm -rf "$SHARE_DIR"
    success "حُذف: $SHARE_DIR"
    (( removed++ )) || true
fi

# ────────────────────────────────────────────────────────────
# تحديث ذاكرة التخزين المؤقت
# ────────────────────────────────────────────────────────────
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -q -t -f "$ICON_DIR" 2>/dev/null || true
elif command -v update-icon-caches &>/dev/null; then
    update-icon-caches "$ICON_DIR" 2>/dev/null || true
fi
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo ""
if [[ $removed -gt 0 ]]; then
    echo -e "${GREEN}اكتملت إزالة التثبيت بنجاح ($removed عنصر محذوف).${NC}"
else
    warn "لم يُعثر على أي ملفات مثبّتة في $SCOPE — ربما لم تكن مثبّتة، أو ثبّتت بصلاحيات مختلفة."
    info "جرّب: ${BLUE}sudo ./uninstall.sh${NC} (للتثبيت النظامي)"
fi
