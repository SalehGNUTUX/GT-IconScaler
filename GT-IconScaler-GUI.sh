#!/usr/bin/env bash
# ============================================================
#  GT-IconScaler v2.0 GUI — Icon Exporter with Zenity
#  نسخة واجهة رسومية لتوليد الأيقونات
#
#  © 2025 GNUtux — GPLv3 or later
# ============================================================

set -euo pipefail

# ────────────────────────────────────────────────────────────
#  فحص الأدوات المطلوبة
# ────────────────────────────────────────────────────────────
check_requirements() {
    local missing=()
    
    if ! command -v convert &>/dev/null; then
        missing+=("ImageMagick (convert)")
    fi
    if ! command -v zenity &>/dev/null; then
        missing+=("zenity")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        zenity --error --no-wrap \
            --text="الأدوات التالية غير مثبتة:\n\n$(printf '%s\n' "${missing[@]}")" \
            2>/dev/null || echo "Missing: ${missing[@]}"
        return 1
    fi
    return 0
}

# ────────────────────────────────────────────────────────────
#  أدول الأحجام والمنصات
# ────────────────────────────────────────────────────────────

ALL_SIZES=(
  16 20 22 24 29 32 36 40 48
  58 60 64 72 76 80 87 96
  120 128 144 152 167 180 192 256
  384 512 1024
)

platform_dir() {
    local size=$1
    local dirs=()
    
    case $size in
      16|22|24|32|48|64|96|128|256|512)
        dirs+=("linux/${size}x${size}/apps") ;;
    esac
    
    case $size in
      16|32|48|72|96|128|144|152|167|180|192|256|384|512)
        dirs+=("pwa") ;;
    esac
    
    case $size in
      36)  dirs+=("android/mipmap-ldpi")   ;;
      48)  dirs+=("android/mipmap-mdpi")   ;;
      72)  dirs+=("android/mipmap-hdpi")   ;;
      96)  dirs+=("android/mipmap-xhdpi")  ;;
      144) dirs+=("android/mipmap-xxhdpi") ;;
      192) dirs+=("android/mipmap-xxxhdpi");;
    esac
    
    case $size in
      20|29|40|58|60|76|80|87|120|152|167|180|512|1024)
        dirs+=("ios") ;;
    esac
    
    case $size in
      16|32|64|128|256|512|1024)
        dirs+=("electron") ;;
    esac
    
    dirs+=("all/${size}x${size}")
    
    echo "${dirs[@]}"
}

# ────────────────────────────────────────────────────────────
#  نوافذ Zenity
# ───���────────────────────────────────────────────────────────

pick_icon() {
    zenity --file-selection \
        --file-filter="الأيقونات (PNG/SVG/JPG) | *.png *.svg *.jpg *.jpeg *.webp" \
        --title="اختر ملف الأيقونة" \
        2>/dev/null || return 1
}

pick_output_dir() {
    zenity --file-selection \
        --directory \
        --title="اختر مجلد التصدير" \
        2>/dev/null || return 1
}

select_platforms() {
    zenity --list \
        --radiolist \
        --column="اختر" \
        --column="المنصة" \
        TRUE "جميع المنصات (Linux + PWA + Android + iOS + Electron)" \
        FALSE "Linux + PWA فقط" \
        FALSE "Linux + PWA + Android" \
        FALSE "Linux + Electron فقط" \
        --width=550 \
        --height=250 \
        --title="اختر المنصات المطلوبة" \
        2>/dev/null || return 1
}

get_package_name() {
    local default_name="$1"
    zenity --entry \
        --title="اسم حزمة الأيقونات" \
        --text="أدخل اسم الحزمة:" \
        --entry-text="${default_name}-icons" \
        2>/dev/null || return 1
}

select_compression() {
    zenity --list \
        --radiolist \
        --column="اختر" \
        --column="نوع الضغط" \
        TRUE "zip و tar.gz معاً (موصى به)" \
        FALSE "zip فقط" \
        FALSE "tar.gz فقط" \
        FALSE "بدون ضغط" \
        --width=450 \
        --height=200 \
        --title="خيارات الضغط" \
        2>/dev/null || return 1
}

# ────────────────────────────────────────────────────────────
#  توليد الأيقونات
# ────────────────────────────────────────────────────────────

generate_icons() {
    local icon_file="$1"
    local export_dir="$2"
    local icon_set_name="$3"
    local platforms="$4"
    
    local icon_basename=$(basename "${icon_file%.*}")
    local final_dir="$export_dir/$icon_set_name"
    
    mkdir -p "$final_dir"
    cp "$icon_file" "$final_dir/${icon_basename}-original.${icon_file##*.}" 2>/dev/null || true
    
    local done=0 fail=0
    
    # مرحلة أ: توليد all/
    for size in "${ALL_SIZES[@]}"; do
        local all_target="$final_dir/all/${size}x${size}"
        mkdir -p "$all_target"
        local tmp_png="/tmp/gt_icon_${size}.png"
        
        if convert "$icon_file" \
            -resize "${size}x${size}" \
            -gravity center \
            -background none \
            -extent "${size}x${size}" \
            "$tmp_png" 2>/dev/null; then
            cp "$tmp_png" "$all_target/${icon_basename}.png"
            rm -f "$tmp_png"
            (( done++ )) || true
        else
            rm -f "$tmp_png"
            (( fail++ )) || true
        fi
    done
    
    # مرحلة ب: توزيع على المنصات
    for size in "${ALL_SIZES[@]}"; do
        local src_png="$final_dir/all/${size}x${size}/${icon_basename}.png"
        [[ -f "$src_png" ]] || continue
        
        local dirs_raw=$(platform_dir "$size")
        read -ra dirs <<< "$dirs_raw"
        
        for d in "${dirs[@]}"; do
            [[ "$d" == all/* ]] && continue
            
            local plat="${d%%/*}"
            local found_plat=0
            for ep in $platforms; do
                [[ "$plat" == "$ep" ]] && found_plat=1 && break
            done
            [[ $found_plat -eq 1 ]] || continue
            
            local fname
            case "$d" in
                android/*)  fname="ic_launcher.png" ;;
                ios/*)
                    case $size in
                        20)   fname="Icon-20.png"   ;;
                        29)   fname="Icon-29.png"   ;;
                        40)   fname="Icon-40.png"   ;;
                        58)   fname="Icon-58.png"   ;;
                        60)   fname="Icon-60.png"   ;;
                        76)   fname="Icon-76.png"   ;;
                        80)   fname="Icon-80.png"   ;;
                        87)   fname="Icon-87.png"   ;;
                        120)  fname="Icon-120.png"  ;;
                        152)  fname="Icon-152.png"  ;;
                        167)  fname="Icon-167.png"  ;;
                        180)  fname="Icon-180.png"  ;;
                        512)  fname="Icon-512.png"  ;;
                        1024) fname="Icon-1024.png" ;;
                        *)    fname="${icon_basename}-${size}.png" ;;
                    esac ;;
                electron/*)    fname="${icon_basename}.png" ;;
                pwa/*)         fname="icon-${size}x${size}.png" ;;
                linux/*/apps)  fname="${icon_basename}.png" ;;
                *)             fname="${icon_basename}-${size}.png" ;;
            esac
            
            local target_dir="$final_dir/$d"
            mkdir -p "$target_dir"
            cp "$src_png" "$target_dir/$fname"
        done
    done
    
    # توليد .ico
    local ico_sizes=(16 24 32 48 64 128 256)
    local ico_inputs=()
    for s in "${ico_sizes[@]}"; do
        local png_path="$final_dir/all/${s}x${s}/${icon_basename}.png"
        [[ -f "$png_path" ]] && ico_inputs+=("$png_path")
    done
    
    if [[ ${#ico_inputs[@]} -gt 0 ]]; then
        convert "${ico_inputs[@]}" "$final_dir/${icon_basename}.ico" 2>/dev/null || true
    fi
    
    # توليد favicon
    mkdir -p "$final_dir/favicon"
    for s in 16 32 48; do
        local src="$final_dir/all/${s}x${s}/${icon_basename}.png"
        [[ -f "$src" ]] && cp "$src" "$final_dir/favicon/favicon-${s}x${s}.png"
    done
    [[ -f "$final_dir/${icon_basename}.ico" ]] && cp "$final_dir/${icon_basename}.ico" "$final_dir/favicon/favicon.ico"
    
    # توليد .icns (macOS)
    if command -v iconutil &>/dev/null; then
        local iconset_tmp="/tmp/${icon_basename}.iconset"
        mkdir -p "$iconset_tmp"
        declare -A icns_map=(
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
        for fname in "${!icns_map[@]}"; do
            local s="${icns_map[$fname]}"
            local src="$final_dir/all/${s}x${s}/${icon_basename}.png"
            [[ -f "$src" ]] && cp "$src" "$iconset_tmp/$fname"
        done
        iconutil -c icns "$iconset_tmp" -o "$final_dir/${icon_basename}.icns" 2>/dev/null || true
        rm -rf "$iconset_tmp"
    fi
    
    # README
    cat > "$final_dir/README.md" << 'EOF'
# أيقونات GT-IconScaler

تم إنشاؤها بواسطة **GT-IconScaler v2.0 GUI**

## هيكل المجلدات

- **all/** — جميع المقاسات المتاحة
- **linux/** — أيقونات Linux (hicolor/XDG)
- **pwa/** — أيقونات تطبيقات الويب
- **android/** — أيقونات Android
- **ios/** — أيقونات iOS/iPadOS
- **electron/** — أيقونات Electron
- **favicon/** — أيقونات المتصفح

## الملفات المرفقة

- `*.ico` — Windows / Favicon
- `*.icns` — macOS (إذا كانت متاحة)
EOF
    
    echo "$final_dir"
}

# ───────────��────────────────────────────────────────────────
#  البرنامج الرئيسي
# ────────────────────────────────────────────────────────────

main() {
    check_requirements || exit 1
    
    # اختيار الأيقونة
    ICON_FILE=$(pick_icon) || exit 1
    [[ ! -f "$ICON_FILE" ]] && zenity --error --text="الملف غير موجود" 2>/dev/null && exit 1
    
    # اختيار مجلد التصدير
    EXPORT_DIR=$(pick_output_dir) || exit 1
    [[ ! -d "$EXPORT_DIR" ]] && zenity --error --text="المجلد غير موجود" 2>/dev/null && exit 1
    
    # تحديد المنصات
    local platform_choice=$(select_platforms) || exit 1
    
    local platforms
    case "$platform_choice" in
        "Linux + PWA فقط")
            platforms="linux pwa" ;;
        "Linux + PWA + Android")
            platforms="linux pwa android" ;;
        "Linux + Electron فقط")
            platforms="linux electron" ;;
        *)
            platforms="linux pwa android ios electron" ;;
    esac
    
    # اسم الحزمة
    local basename=$(basename "${ICON_FILE%.*}")
    PACKAGE_NAME=$(get_package_name "$basename") || exit 1
    
    # نوع الضغط
    COMPRESSION=$(select_compression) || exit 1
    
    # توليد الأيقونات
    FINAL_DIR=$(generate_icons "$ICON_FILE" "$EXPORT_DIR" "$PACKAGE_NAME" "$platforms")
    
    # ضغط الملفات
    (
        cd "$EXPORT_DIR" || exit 1
        case "$COMPRESSION" in
            "zip فقط")
                zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" >/dev/null 2>&1 ;;
            "tar.gz فقط")
                tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME" 2>/dev/null ;;
            "بدون ضغط")
                : ;;
            *)
                zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" >/dev/null 2>&1
                tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME" 2>/dev/null ;;
        esac
    )
    
    # رسالة النجاح
    zenity --info \
        --title="اكتمل بنجاح! ✅" \
        --no-wrap \
        --text="تم إنشاء الأيقونات بنجاح!\n\nالمجلد: $FINAL_DIR" \
        2>/dev/null
}

main "$@"
