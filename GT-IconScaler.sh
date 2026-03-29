#!/usr/bin/env bash
# ============================================================
#  GT-IconScaler v2.0 — Icon Exporter & Packager
#  توليد أيقونات لجميع المنصات دفعة واحدة
#
#  المنصات المدعومة:
#    ✅ Linux Desktop (hicolor / XDG)
#    ✅ PWA / Web Manifest
#    ✅ Android APK  (mipmap ldpi→xxxhdpi)
#    ✅ iOS / iPadOS (App Icon)
#    ✅ Windows      (.ico متعدد الأحجام)
#    ✅ macOS        (.icns — إن توفّر iconutil أو png2icns)
#    ✅ Electron     (AppImage / Snap / Flatpak)
#    ✅ Favicon      (.ico + PNG منفصلة)
#
#  المتطلبات: ImageMagick (convert)
#  الاختيارية: iconutil (macOS) أو icnsutils (Linux) أو png2icns
#
#  © 2025 GNUtux — GPLv3 or later
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# ────────────────────────────────────────────────────────────
#  الألوان والطباعة
# ────────────────────────────────────────────────────────────
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'
CYN='\033[0;36m'; BLD='\033[1m'; RST='\033[0m'
info()    { echo -e "${CYN}ℹ ${RST}$*"; }
success() { echo -e "${GRN}✅ ${RST}$*"; }
warn()    { echo -e "${YEL}⚠️  ${RST}$*"; }
err()     { echo -e "${RED}❌ ${RST}$*" >&2; }
header()  { echo -e "\n${BLD}${CYN}══ $* ══${RST}"; }

# ────────────────────────────────────────────────────────────
#  فحص ImageMagick
# ────────────────────────────────────────────────────────────
if ! command -v convert &>/dev/null; then
    err "ImageMagick غير مثبّت."
    echo "    Debian/Ubuntu : sudo apt install imagemagick"
    echo "    Fedora         : sudo dnf install imagemagick"
    echo "    Arch           : sudo pacman -S imagemagick"
    exit 1
fi

# ────────────────────────────────────────────────────────────
#  أدوات اختيار الملفات (GUI)
# ────────────────────────────────────────────────────────────
file_picker() {
    if command -v zenity &>/dev/null; then
        zenity --file-selection \
               --file-filter="Images | *.png *.svg *.jpg *.jpeg *.webp" \
               --title "$1" 2>/dev/null
    elif command -v kdialog &>/dev/null; then
        kdialog --getopenfilename . "*.png *.svg *.jpg *.jpeg *.webp" 2>/dev/null
    elif command -v yad &>/dev/null; then
        yad --file-selection \
            --file-filter="Images | *.png *.svg *.jpg *.jpeg *.webp" \
            --title "$1" 2>/dev/null
    else
        err "لا يوجد مدير نوافذ مدعوم (zenity / kdialog / yad)."
        read -rp "أدخل مسار ملف الأيقونة يدوياً: " MANUAL_PATH
        echo "$MANUAL_PATH"
    fi
}

dir_picker() {
    if command -v zenity &>/dev/null; then
        zenity --file-selection --directory --title "$1" 2>/dev/null
    elif command -v kdialog &>/dev/null; then
        kdialog --getexistingdirectory . 2>/dev/null
    elif command -v yad &>/dev/null; then
        yad --file-selection --directory --title "$1" 2>/dev/null
    else
        read -rp "أدخل مسار مجلد التصدير يدوياً: " MANUAL_DIR
        echo "$MANUAL_DIR"
    fi
}

# ────────────────────────────────────────────────────────────
#  Jدول الأحجام الشامل
#  الصيغة: "المقاس|الفئة"
# ────────────────────────────────────────────────────────────
declare -A SIZE_CATEGORIES

# Linux hicolor (XDG Icon Theme)
SIZE_CATEGORIES["16"]="linux"
SIZE_CATEGORIES["22"]="linux"
SIZE_CATEGORIES["24"]="linux"
SIZE_CATEGORIES["32"]="linux"
SIZE_CATEGORIES["48"]="linux"
SIZE_CATEGORIES["64"]="linux"
SIZE_CATEGORIES["96"]="linux"
SIZE_CATEGORIES["128"]="linux"
SIZE_CATEGORIES["256"]="linux"
SIZE_CATEGORIES["512"]="linux"

# PWA / Web Manifest
SIZE_CATEGORIES["72"]="pwa"
SIZE_CATEGORIES["144"]="pwa"
SIZE_CATEGORIES["152"]="pwa"
SIZE_CATEGORIES["180"]="pwa"   # Apple Touch Icon
SIZE_CATEGORIES["192"]="pwa"   # Required for PWA install
SIZE_CATEGORIES["384"]="pwa"
# 16,32,48,96,128,256,512 مشتركة مع linux

# Android mipmap (APK)
SIZE_CATEGORIES["36"]="android"   # ldpi
# 48=mdpi مع linux
SIZE_CATEGORIES["72"]="android"   # hdpi (مشترك مع pwa)
# 96=xhdpi مع linux
SIZE_CATEGORIES["144"]="android"  # xxhdpi (مشترك مع pwa)
SIZE_CATEGORIES["192"]="android"  # xxxhdpi (مشترك مع pwa)

# iOS / iPadOS
SIZE_CATEGORIES["20"]="ios"
SIZE_CATEGORIES["29"]="ios"
SIZE_CATEGORIES["40"]="ios"
SIZE_CATEGORIES["58"]="ios"
SIZE_CATEGORIES["60"]="ios"
SIZE_CATEGORIES["76"]="ios"
SIZE_CATEGORIES["80"]="ios"
SIZE_CATEGORIES["87"]="ios"
SIZE_CATEGORIES["120"]="ios"
# 128 مشترك مع linux
SIZE_CATEGORIES["152"]="ios"   # (مشترك مع pwa)
SIZE_CATEGORIES["167"]="ios"
SIZE_CATEGORIES["180"]="ios"   # (مشترك مع pwa)
# 512 مشترك
SIZE_CATEGORIES["1024"]="ios"  # App Store

# Electron
SIZE_CATEGORIES["1024"]="electron"

# الترتيب الكامل الفريد (مرتب تصاعدياً)
ALL_SIZES=(
  16 20 22 24 29 32 36 40 48
  58 60 64 72 76 80 87 96
  120 128 144 152 167 180 192 256
  384 512 1024
)

# ────────────────────────────────────────────────────────────
#  تصنيف المجلدات حسب المنصة
# ────────────────────────────────────────────────────────────
# أيقونة Linux تذهب لـ hicolor
# PWA و Android و Electron → مجلداتها الخاصة
# iOS → مجلد منفصل

platform_dir() {
    local size=$1
    # أحجام مشتركة بين منصات متعددة → تُنسخ لكل مجلد مناسب
    # الدالة تُعيد قائمة المجلدات المستهدفة
    local dirs=()

    # Linux: جميع أحجام hicolor المعيارية
    case $size in
      16|22|24|32|48|64|96|128|256|512)
        dirs+=("linux/${size}x${size}/apps") ;;
    esac

    # PWA
    case $size in
      16|32|48|72|96|128|144|152|167|180|192|256|384|512)
        dirs+=("pwa") ;;
    esac

    # Android mipmap
    case $size in
      36)  dirs+=("android/mipmap-ldpi")   ;;
      48)  dirs+=("android/mipmap-mdpi")   ;;
      72)  dirs+=("android/mipmap-hdpi")   ;;
      96)  dirs+=("android/mipmap-xhdpi")  ;;
      144) dirs+=("android/mipmap-xxhdpi") ;;
      192) dirs+=("android/mipmap-xxxhdpi");;
    esac

    # iOS
    case $size in
      20|29|40|58|60|76|80|87|120|152|167|180|512|1024)
        dirs+=("ios") ;;
    esac

    # Electron
    case $size in
      16|32|64|128|256|512|1024)
        dirs+=("electron") ;;
    esac

    # المجلد الموحد (يحتوي الكل مرتب حسب المقاس)
    dirs+=("all/${size}x${size}")

    echo "${dirs[@]}"
}

# ────────────────────────────────────────────────────────────
#  واجهة المستخدم
# ────────────────────────────────────────────────────────────
clear
echo -e "${BLD}"
cat << 'BANNER'
  ╔══════════════════════════════════════════════╗
  ║       GT-IconScaler v2.0 — GNUtux            ║
  ║   توليد أيقونات شاملة لجميع المنصات          ║
  ╚══════════════════════════════════════════════╝
BANNER
echo -e "${RST}"

# ── 1. اختيار الأيقونة ─────────────────────────────────────
header "الخطوة 1 — اختيار ملف الأيقونة"
info "سيُفتح مستعرض الملفات..."
ICON_FILE=$(file_picker "اختر ملف الأيقونة (SVG أو PNG — 512px+ موصى به)")
[[ -f "$ICON_FILE" ]] || { err "لم يتم اختيار ملف."; exit 1; }
success "الأيقونة: $ICON_FILE"

ICON_BASENAME=$(basename "${ICON_FILE%.*}")

# تحقق من الأبعاد
IMG_INFO=$(identify -format "%wx%h" "$ICON_FILE" 2>/dev/null || echo "?x?")
info "الأبعاد الأصلية: ${IMG_INFO}"
if [[ "$IMG_INFO" != "?x?" ]]; then
    W=$(echo "$IMG_INFO" | cut -dx -f1)
    if [[ "$W" =~ ^[0-9]+$ ]] && (( W < 512 )); then
        warn "الأيقونة أصغر من 512px — قد تبدو ضبابية في المقاسات الكبيرة."
        warn "يُنصح بأيقونة 1024px على الأقل."
    fi
fi

# ── 2. اختيار مجلد التصدير ─────────────────────────────────
header "الخطوة 2 — اختيار مجلد التصدير"
EXPORT_DIR=$(dir_picker "اختر مجلد التصدير")
[[ -d "$EXPORT_DIR" ]] || { err "لم يتم اختيار مجلد."; exit 1; }
success "التصدير إلى: $EXPORT_DIR"

# ── 3. اسم الحزمة ──────────────────────────────────────────
header "الخطوة 3 — اسم حزمة الأيقونات"
echo "  [1] اسم الملف الأصلي: ${BLD}${ICON_BASENAME}${RST}-icons"
echo "  [2] اسم المجلد الحالي: ${BLD}${EXPORT_DIR##*/}${RST}-icons"
echo "  [3] اسم مخصص"
read -rp "  أدخل الاختيار (1/2/3) [افتراضي: 1]: " NAME_CHOICE
NAME_CHOICE="${NAME_CHOICE:-1}"

case "$NAME_CHOICE" in
    2) ICON_SET_NAME="${EXPORT_DIR##*/}-icons" ;;
    3)
        read -rp "  أدخل الاسم: " CUSTOM_NAME
        ICON_SET_NAME="${CUSTOM_NAME:-iconset}"
        ;;
    *) ICON_SET_NAME="${ICON_BASENAME}-icons" ;;
esac
success "اسم الحزمة: ${ICON_SET_NAME}"

# ── 4. اختيار المنصات ──────────────────────────────────────
header "الخطوة 4 — اختيار المنصات"
echo "  [1] جميع المنصات (${#ALL_SIZES[@]} مقاساً) ← موصى به"
echo "  [2] Linux + PWA فقط"
echo "  [3] Linux + PWA + Android"
echo "  [4] Linux + Electron فقط"
read -rp "  أدخل الاختيار (1/2/3/4) [افتراضي: 1]: " PLAT_CHOICE
PLAT_CHOICE="${PLAT_CHOICE:-1}"

case "$PLAT_CHOICE" in
    2) ENABLED_PLATFORMS="linux pwa" ;;
    3) ENABLED_PLATFORMS="linux pwa android" ;;
    4) ENABLED_PLATFORMS="linux electron" ;;
    *) ENABLED_PLATFORMS="linux pwa android ios electron" ;;
esac
info "المنصات: $ENABLED_PLATFORMS"

# ── 5. بناء قائمة الأحجام الفعلية بناءً على المنصات ──────
ACTIVE_SIZES=()
for size in "${ALL_SIZES[@]}"; do
    dirs_raw=$(platform_dir "$size")
    read -ra dirs <<< "$dirs_raw"
    for d in "${dirs[@]}"; do
        plat="${d%%/*}"  # أول جزء من المسار = اسم المنصة
        if [[ "$ENABLED_PLATFORMS" == *"$plat"* ]] || [[ "$d" == all/* ]]; then
            ACTIVE_SIZES+=("$size")
            break
        fi
    done
done
# إزالة التكرار وإعادة الترتيب
mapfile -t ACTIVE_SIZES < <(printf '%s\n' "${ACTIVE_SIZES[@]}" | sort -un)

info "إجمالي المقاسات: ${#ACTIVE_SIZES[@]} مقاساً"

# ── 6. إنشاء المجلدات وتوليد الأيقونات ────────────────────
header "الخطوة 5 — توليد الأيقونات"
FINAL_DIR="$EXPORT_DIR/$ICON_SET_NAME"
mkdir -p "$FINAL_DIR"

# احتفظ بنسخة كاملة من الأيقونة الأصلية (نقطة صريحة قبل الامتداد)
ORIG_EXT="${ICON_FILE##*.}"
cp "$ICON_FILE" "$FINAL_DIR/${ICON_BASENAME}-original.${ORIG_EXT}" 2>/dev/null || true

DONE=0
FAIL=0

# ══════════════════════════════════════════════════════════════
#  المرحلة أ — توليد all/ لكل المقاسات بشكل مستقل تماماً
#  لا علاقة له بفلتر المنصات — هذا المصدر لكل الخطوات اللاحقة
# ══════════════════════════════════════════════════════════════
info "المرحلة أ: توليد المجلد الموحد all/ ..."
for size in "${ALL_SIZES[@]}"; do
    ALL_TARGET="$FINAL_DIR/all/${size}x${size}"
    mkdir -p "$ALL_TARGET"
    TMP_PNG="/tmp/gt_icon_${size}.png"
    if convert "$ICON_FILE" \
        -resize "${size}x${size}" \
        -gravity center \
        -background none \
        -extent "${size}x${size}" \
        "$TMP_PNG" 2>/dev/null; then
        cp "$TMP_PNG" "$ALL_TARGET/${ICON_BASENAME}.png"
        rm -f "$TMP_PNG"
        printf "  ${GRN}✓${RST} all/%dpx\n" "$size"
        (( DONE++ )) || true
    else
        warn "فشل مقاس ${size}px"
        rm -f "$TMP_PNG"
        (( FAIL++ )) || true
    fi
done

# ══════════════════════════════════════════════════════════════
#  المرحلة ب — توزيع على مجلدات المنصات المُفعَّلة
#  المصدر: all/${size}x${size}/${ICON_BASENAME}.png (مضمون الوجود)
# ══════════════════════════════════════════════════════════════
info "المرحلة ب: توزيع على المنصات ($ENABLED_PLATFORMS) ..."
for size in "${ALL_SIZES[@]}"; do
    SRC_PNG="$FINAL_DIR/all/${size}x${size}/${ICON_BASENAME}.png"
    [[ -f "$SRC_PNG" ]] || continue

    dirs_raw=$(platform_dir "$size")
    read -ra dirs <<< "$dirs_raw"

    for d in "${dirs[@]}"; do
        # تخطي all/ (جاهز من المرحلة أ)
        [[ "$d" == all/* ]] && continue

        # فحص المنصة بحلقة صريحة بدل glob داخل [[]]
        plat="${d%%/*}"
        found_plat=0
        for ep in $ENABLED_PLATFORMS; do
            [[ "$plat" == "$ep" ]] && found_plat=1 && break
        done
        [[ $found_plat -eq 1 ]] || continue

        # تحديد اسم الملف حسب المنصة
        case "$d" in
            android/*)  FNAME="ic_launcher.png" ;;
            ios/*)
                case $size in
                    20)   FNAME="Icon-20.png"   ;;  29)  FNAME="Icon-29.png"   ;;
                    40)   FNAME="Icon-40.png"   ;;  58)  FNAME="Icon-58.png"   ;;
                    60)   FNAME="Icon-60.png"   ;;  76)  FNAME="Icon-76.png"   ;;
                    80)   FNAME="Icon-80.png"   ;;  87)  FNAME="Icon-87.png"   ;;
                    120)  FNAME="Icon-120.png"  ;;  152) FNAME="Icon-152.png"  ;;
                    167)  FNAME="Icon-167.png"  ;;  180) FNAME="Icon-180.png"  ;;
                    512)  FNAME="Icon-512.png"  ;;  1024) FNAME="Icon-1024.png" ;;
                    *)    FNAME="${ICON_BASENAME}-${size}.png" ;;
                esac ;;
            electron/*)    FNAME="${ICON_BASENAME}.png" ;;
            pwa/*)         FNAME="icon-${size}x${size}.png" ;;
            linux/*/apps)  FNAME="${ICON_BASENAME}.png" ;;
            *)             FNAME="${ICON_BASENAME}-${size}.png" ;;
        esac

        TARGET_DIR="$FINAL_DIR/$d"
        mkdir -p "$TARGET_DIR"
        cp "$SRC_PNG" "$TARGET_DIR/$FNAME"
    done
done

# ── 7. توليد ملف .ico (Windows + Favicon) ─────────────────
header "الخطوة 6 — توليد .ico (Windows / Favicon)"
ICO_SIZES=(16 24 32 48 64 128 256)
ICO_INPUTS=()
for s in "${ICO_SIZES[@]}"; do
    # ابحث عن الأحجام في مجلد all
    PNG_PATH="$FINAL_DIR/all/${s}x${s}/${ICON_BASENAME}.png"
    [[ -f "$PNG_PATH" ]] && ICO_INPUTS+=("$PNG_PATH")
done

if [[ ${#ICO_INPUTS[@]} -gt 0 ]]; then
    if convert "${ICO_INPUTS[@]}" "$FINAL_DIR/${ICON_BASENAME}.ico" 2>/dev/null; then
        success "تم إنشاء ${ICON_BASENAME}.ico (${#ICO_INPUTS[@]} أحجام مدمجة)"
    else
        warn "فشل توليد .ico"
    fi
else
    warn "لا توجد ملفات PNG كافية لتوليد .ico"
fi

# favicon مخصص
mkdir -p "$FINAL_DIR/favicon"
for s in 16 32 48; do
    src="$FINAL_DIR/all/${s}x${s}/${ICON_BASENAME}.png"
    [[ -f "$src" ]] && cp "$src" "$FINAL_DIR/favicon/favicon-${s}x${s}.png"
done
[[ -f "$FINAL_DIR/${ICON_BASENAME}.ico" ]] && cp "$FINAL_DIR/${ICON_BASENAME}.ico" "$FINAL_DIR/favicon/favicon.ico"

# ── 8. توليد .icns (macOS) ────────────────────────────────
header "الخطوة 7 — توليد .icns (macOS)"
ICNS_OUT="$FINAL_DIR/${ICON_BASENAME}.icns"

if command -v iconutil &>/dev/null; then
    # macOS — استخدم iconutil
    ICONSET_TMP="/tmp/${ICON_BASENAME}.iconset"
    mkdir -p "$ICONSET_TMP"
    declare -A ICNS_MAP=(
        ["icon_16x16.png"]="16"
        ["icon_16x16@2x.png"]="32"
        ["icon_32x32.png"]="32"
        ["icon_32x32@2x.png"]="64"
        ["icon_128x128.png"]="128"
        ["icon_128x128@2x.png"]="256"
        ["icon_256x256.png"]="256"
        ["icon_256x256@2x.png"]="512"
        ["icon_512x512.png"]="512"
        ["icon_512x512@2x.png"]="1024"
    )
    for fname in "${!ICNS_MAP[@]}"; do
        s="${ICNS_MAP[$fname]}"
        src="$FINAL_DIR/all/${s}x${s}/${ICON_BASENAME}.png"
        [[ -f "$src" ]] && cp "$src" "$ICONSET_TMP/$fname"
    done
    iconutil -c icns "$ICONSET_TMP" -o "$ICNS_OUT" 2>/dev/null && \
        success "تم إنشاء .icns بـ iconutil" || warn "فشل iconutil"
    rm -rf "$ICONSET_TMP"

elif command -v png2icns &>/dev/null; then
    # Linux — png2icns من حزمة icnsutils
    ICNS_SRCS=()
    for s in 16 32 128 256 512; do
        src="$FINAL_DIR/all/${s}x${s}/${ICON_BASENAME}.png"
        [[ -f "$src" ]] && ICNS_SRCS+=("$src")
    done
    [[ ${#ICNS_SRCS[@]} -gt 0 ]] && \
        png2icns "$ICNS_OUT" "${ICNS_SRCS[@]}" 2>/dev/null && \
        success "تم إنشاء .icns بـ png2icns" || \
        warn "فشل png2icns"

elif convert --version 2>&1 | grep -q "ImageMagick"; then
    # بديل: ImageMagick (دعم جزئي لـ .icns)
    src="$FINAL_DIR/all/512x512/${ICON_BASENAME}.png"
    if [[ -f "$src" ]]; then
        convert "$src" "$ICNS_OUT" 2>/dev/null && \
            success "تم إنشاء .icns بـ ImageMagick (محدود)" || \
            warn "فشل ImageMagick → .icns"
    fi
else
    warn ".icns لم يُنشأ (مطلوب: iconutil أو png2icns)"
    info "على Linux: sudo apt install icnsutils"
fi

# ── 9. إنشاء README.md داخل الحزمة ────────────────────────
header "الخطوة 8 — إنشاء فهرس الحزمة"
cat > "$FINAL_DIR/README.md" << README
# ${ICON_SET_NAME}

أُنشئت بواسطة **GT-IconScaler v2.0** — $(date '+%Y-%m-%d %H:%M')

## هيكل المجلدات

\`\`\`
${ICON_SET_NAME}/
├── all/            ← جميع المقاسات (${#ACTIVE_SIZES[@]} مقاساً)
├── linux/          ← hicolor XDG (16→512)
├── pwa/            ← Web Manifest + Apple Touch
├── android/        ← mipmap-ldpi → mipmap-xxxhdpi
├── ios/            ← App Icon (20→1024)
├── electron/       ← AppImage / Snap (16→1024)
├── favicon/        ← favicon.ico + PNG
├── ${ICON_BASENAME}.ico    ← Windows (متعدد الأحجام)
└── ${ICON_BASENAME}.icns   ← macOS (إن توفّر)
\`\`\`

## المقاسات المُصدَّرة

| المقاس | الاستخدام |
|--------|-----------|
| 16 | Linux تبار · Favicon · Electron |
| 20 | iOS Notification |
| 22 | Linux GNOME/KDE صغير |
| 24 | Linux شريط القوائم |
| 29 | iOS Settings |
| 32 | Linux · Favicon · Windows ICO · Electron |
| 36 | Android ldpi |
| 40 | iOS Spotlight |
| 48 | Linux قياسي · Android mdpi |
| 58 | iOS Settings @2x |
| 60 | iOS App @1x |
| 64 | Linux · Electron |
| 72 | Android hdpi · PWA |
| 76 | iPad App |
| 80 | iOS Spotlight @2x |
| 87 | iOS Settings @3x |
| 96 | Linux · Android xhdpi |
| 120 | iOS App @2x |
| 128 | Linux · Electron · Windows ICO |
| 144 | Android xxhdpi · PWA |
| 152 | iPad App @2x · PWA |
| 167 | iPad Pro |
| 180 | iPhone App @3x · Apple Touch Icon |
| 192 | PWA Install Required · Android xxxhdpi |
| 256 | Linux · Electron · Windows ICO |
| 384 | PWA Splash |
| 512 | Linux · PWA Required · Electron |
| 1024 | iOS App Store · Electron |

## الاستخدام

### PWA manifest.json
\`\`\`json
"icons": [
  { "src": "pwa/icon-192x192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
  { "src": "pwa/icon-192x192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
  { "src": "pwa/icon-512x512.png", "sizes": "512x512", "type": "image/png" }
]
\`\`\`

### Android (res/mipmap-*)
انسخ المحتوى من \`android/\` إلى \`app/src/main/res/\`

### Electron (package.json)
\`\`\`json
"linux": { "icon": "electron/" }
\`\`\`
README

success "تم إنشاء README.md"

# ── 10. إنشاء ملف مضغوط ────────────────────────────────────
header "الخطوة 9 — ضغط الحزمة"
echo "  [1] zip"
echo "  [2] tar.gz"
echo "  [3] النسختين معاً"
echo "  [4] بدون ضغط"
read -rp "  أدخل الاختيار [افتراضي: 3]: " COMP_CHOICE
COMP_CHOICE="${COMP_CHOICE:-3}"

cd "$EXPORT_DIR" || exit 1

case "$COMP_CHOICE" in
    1)
        zip -r "${ICON_SET_NAME}.zip" "$ICON_SET_NAME" >/dev/null
        success "تم إنشاء ${ICON_SET_NAME}.zip"
        ;;
    2)
        tar -czf "${ICON_SET_NAME}.tar.gz" "$ICON_SET_NAME"
        success "تم إنشاء ${ICON_SET_NAME}.tar.gz"
        ;;
    4)
        info "تخطي الضغط."
        ;;
    *)
        zip -r "${ICON_SET_NAME}.zip" "$ICON_SET_NAME" >/dev/null
        tar -czf "${ICON_SET_NAME}.tar.gz" "$ICON_SET_NAME"
        success "تم إنشاء النسختين: ${ICON_SET_NAME}.zip و ${ICON_SET_NAME}.tar.gz"
        ;;
esac

# ── 11. ملخص نهائي ─────────────────────────────────────────
echo ""
echo -e "${BLD}${GRN}"
cat << 'DONE_BANNER'
  ╔══════════════════════════════════════════════╗
  ║           🎉 اكتمل التصدير بنجاح!            ║
  ╚══════════════════════════════════════════════╝
DONE_BANNER
echo -e "${RST}"

echo -e "  📁 المجلد  : ${BLD}$EXPORT_DIR/$ICON_SET_NAME${RST}"
echo -e "  ✅ نجح     : ${BLD}${DONE}${RST} مقاساً"
[[ $FAIL -gt 0 ]] && echo -e "  ${YEL}⚠️  فشل     : ${FAIL} مقاساً${RST}"
echo ""
echo -e "  📂 الهيكل:"
echo -e "     all/     ← ${#ACTIVE_SIZES[@]} مقاساً موحداً"
echo -e "     linux/   ← hicolor (XDG Icon Theme)"
echo -e "     pwa/     ← Web App Manifest + Apple Touch"
echo -e "     android/ ← mipmap-ldpi → mipmap-xxxhdpi"
echo -e "     ios/     ← App Icon لجميع أجهزة Apple"
echo -e "     electron/← AppImage / Snap / Flatpak"
echo -e "     favicon/ ← favicon.ico + PNG"
[[ -f "$FINAL_DIR/${ICON_BASENAME}.ico"  ]] && echo -e "     ✅ .ico (Windows)"
[[ -f "$FINAL_DIR/${ICON_BASENAME}.icns" ]] && echo -e "     ✅ .icns (macOS)"
echo ""
