#!/usr/bin/env bash
# ============================================================
#  GT-IconScaler — Core Library
#  منطق توليد الأيقونات الأساسي (مستقل عن الواجهة واللغة)
#
#  هذه المكتبة لا تطبع أي رسائل user-facing — المُستدعي يقرر
#  الرسائل والترجمات. كل الدوال تعود بأكواد خروج وأكواد عددية
#  عبر متغيرات GT_* أو stdout عند الحاجة.
# ============================================================

# ────────────────────────────────────────────────────────────
#  جدول الأحجام الكامل (38 مقاساً)
# ────────────────────────────────────────────────────────────
GT_ALL_SIZES=(
    16 20 22 24 29 32 36 40 44 48 50
    58 60 64 70 72 76 80 87 88 96 100
    120 128 144 150 152 167 172 180 192 196
    216 256 310 384 512 1024
)

# ────────────────────────────────────────────────────────────
#  أداة ImageMagick: convert (IM6) أو magick (IM7)
# ────────────────────────────────────────────────────────────
gt_im_cmd() {
    if command -v magick &>/dev/null; then
        echo "magick"
    elif command -v convert &>/dev/null; then
        echo "convert"
    else
        return 1
    fi
}

# ────────────────────────────────────────────────────────────
#  identify: نفس فكرة gt_im_cmd لكن لأداة identify
# ────────────────────────────────────────────────────────────
gt_identify_cmd() {
    if command -v magick &>/dev/null; then
        echo "magick identify"
    elif command -v identify &>/dev/null; then
        echo "identify"
    else
        return 1
    fi
}

# ────────────────────────────────────────────────────────────
#  gt_platform_dirs <size>
#  تطبع قائمة المجلدات النسبية المستهدفة لهذا المقاس
#  (مفصولة بمسافات في سطر واحد)
# ────────────────────────────────────────────────────────────
gt_platform_dirs() {
    local size=$1
    local dirs=()

    # Linux hicolor (XDG Icon Theme)
    case $size in
        16|22|24|32|48|64|96|128|256|512)
            dirs+=("linux/${size}x${size}/apps") ;;
    esac

    # PWA / Web Manifest (يشمل Chrome Android: 196)
    case $size in
        16|32|48|72|96|128|144|152|167|180|192|196|256|384|512)
            dirs+=("pwa") ;;
    esac

    # Android mipmap
    case $size in
        36)  dirs+=("android/mipmap-ldpi")    ;;
        48)  dirs+=("android/mipmap-mdpi")    ;;
        72)  dirs+=("android/mipmap-hdpi")    ;;
        96)  dirs+=("android/mipmap-xhdpi")   ;;
        144) dirs+=("android/mipmap-xxhdpi")  ;;
        192) dirs+=("android/mipmap-xxxhdpi") ;;
    esac

    # iOS / iPadOS
    case $size in
        20|29|40|58|60|76|80|87|100|120|152|167|180|512|1024)
            dirs+=("ios") ;;
    esac

    # watchOS / Apple Watch
    case $size in
        48|55|58|88|100|172|196|216)
            dirs+=("watchos") ;;
    esac

    # Windows 10/11 Tiles
    case $size in
        44|50|70|150|310)
            dirs+=("windows") ;;
    esac

    # Electron
    case $size in
        16|32|64|128|256|512|1024)
            dirs+=("electron") ;;
    esac

    # المجلد الموحد
    dirs+=("all/${size}x${size}")

    echo "${dirs[@]}"
}

# ────────────────────────────────────────────────────────────
#  gt_target_filename <relative_dir> <size> <icon_basename>
#  تطبع اسم الملف الصحيح حسب المنصة
# ────────────────────────────────────────────────────────────
gt_target_filename() {
    local d=$1 size=$2 basename=$3
    case "$d" in
        android/*) echo "ic_launcher.png" ;;
        ios/*)
            case $size in
                20)   echo "Icon-20.png"   ;;
                29)   echo "Icon-29.png"   ;;
                40)   echo "Icon-40.png"   ;;
                58)   echo "Icon-58.png"   ;;
                60)   echo "Icon-60.png"   ;;
                76)   echo "Icon-76.png"   ;;
                80)   echo "Icon-80.png"   ;;
                87)   echo "Icon-87.png"   ;;
                100)  echo "Icon-100.png"  ;;
                120)  echo "Icon-120.png"  ;;
                152)  echo "Icon-152.png"  ;;
                167)  echo "Icon-167.png"  ;;
                180)  echo "Icon-180.png"  ;;
                512)  echo "Icon-512.png"  ;;
                1024) echo "Icon-1024.png" ;;
                *)    echo "${basename}-${size}.png" ;;
            esac ;;
        watchos/*)
            echo "AppIcon-${size}.png" ;;
        windows/*)
            case $size in
                44)  echo "StoreLogo-44.png"      ;;
                50)  echo "StoreLogo-50.png"      ;;
                70)  echo "Square70x70Logo.png"   ;;
                150) echo "Square150x150Logo.png" ;;
                310) echo "Square310x310Logo.png" ;;
                *)   echo "Tile-${size}.png"      ;;
            esac ;;
        electron/*)    echo "${basename}.png" ;;
        pwa/*)         echo "icon-${size}x${size}.png" ;;
        linux/*/apps)  echo "${basename}.png" ;;
        *)             echo "${basename}-${size}.png" ;;
    esac
}

# ────────────────────────────────────────────────────────────
#  gt_generate_all <icon_file> <final_dir> <basename> [progress_cb]
#  المرحلة أ: توليد all/${size}x${size}/${basename}.png لكل المقاسات
#  progress_cb (اختياري): اسم دالة تُستدعى لكل مقاس بصيغة:
#       progress_cb <size> <status>   حيث status = "ok" أو "fail"
#  يضبط: GT_DONE_COUNT, GT_FAIL_COUNT
# ────────────────────────────────────────────────────────────
gt_generate_all() {
    local icon_file=$1
    local final_dir=$2
    local basename=$3
    local progress_cb=${4:-}

    local im
    im=$(gt_im_cmd) || return 1

    GT_DONE_COUNT=0
    GT_FAIL_COUNT=0

    local tmp_png size all_target
    local tmp_base
    tmp_base=$(mktemp -d -t gt-iconscaler-XXXXXX) || return 1

    for size in "${GT_ALL_SIZES[@]}"; do
        all_target="$final_dir/all/${size}x${size}"
        mkdir -p "$all_target"
        tmp_png="$tmp_base/icon_${size}.png"

        if "$im" "$icon_file" \
            -resize "${size}x${size}" \
            -gravity center \
            -background none \
            -extent "${size}x${size}" \
            "$tmp_png" 2>/dev/null
        then
            cp "$tmp_png" "$all_target/${basename}.png"
            rm -f "$tmp_png"
            GT_DONE_COUNT=$(( GT_DONE_COUNT + 1 ))
            [[ -n "$progress_cb" ]] && "$progress_cb" "$size" "ok"
        else
            rm -f "$tmp_png"
            GT_FAIL_COUNT=$(( GT_FAIL_COUNT + 1 ))
            [[ -n "$progress_cb" ]] && "$progress_cb" "$size" "fail"
        fi
    done

    rm -rf "$tmp_base"
    return 0
}

# ────────────────────────────────────────────────────────────
#  gt_distribute <final_dir> <basename> <enabled_platforms>
#  المرحلة ب: نسخ من all/ إلى مجلدات المنصات حسب التوجيه + الفلتر
#  enabled_platforms: سلسلة مفصولة بمسافات (linux pwa android ...)
# ────────────────────────────────────────────────────────────
gt_distribute() {
    local final_dir=$1
    local basename=$2
    local enabled_platforms=$3

    # القيمة الافتراضية للـ IFS داخل النطاق المحلي حتى لا تكسر split-on-space
    # عند استدعاء المكتبة من entry script ضابطٍ IFS=$'\n\t' (الحالة المعتادة).
    local IFS=$' \t\n'

    local size src_png dirs_raw d plat found_plat ep fname target_dir
    local -a dirs

    for size in "${GT_ALL_SIZES[@]}"; do
        src_png="$final_dir/all/${size}x${size}/${basename}.png"
        [[ -f "$src_png" ]] || continue

        dirs_raw=$(gt_platform_dirs "$size")
        read -ra dirs <<< "$dirs_raw"

        for d in "${dirs[@]}"; do
            # تخطي all/ — جاهز من gt_generate_all
            [[ "$d" == all/* ]] && continue

            # فحص أن المنصة ضمن المُفعَّلة
            plat="${d%%/*}"
            found_plat=0
            for ep in $enabled_platforms; do
                [[ "$plat" == "$ep" ]] && found_plat=1 && break
            done
            [[ $found_plat -eq 1 ]] || continue

            fname=$(gt_target_filename "$d" "$size" "$basename")
            target_dir="$final_dir/$d"
            mkdir -p "$target_dir"
            cp "$src_png" "$target_dir/$fname"
        done
    done
}

# ────────────────────────────────────────────────────────────
#  gt_get_image_dimensions <file> → "WxH" أو "?x?"
# ────────────────────────────────────────────────────────────
gt_get_image_dimensions() {
    local file=$1
    local id
    id=$(gt_identify_cmd) || { echo "?x?"; return 1; }
    $id -format "%wx%h" "$file" 2>/dev/null || echo "?x?"
}

# ────────────────────────────────────────────────────────────
#  gt_resolve_platforms <preset>
#  يحوّل رقم/اسم اختيار المنصات إلى سلسلة منصات مفعَّلة
#  المعلِم: all|linux-pwa|linux-pwa-android|linux-electron|mobile|windows
# ────────────────────────────────────────────────────────────
gt_resolve_platforms() {
    case "$1" in
        linux-pwa)         echo "linux pwa" ;;
        linux-pwa-android) echo "linux pwa android" ;;
        linux-electron)    echo "linux electron" ;;
        mobile)            echo "android ios watchos" ;;
        windows)           echo "windows" ;;
        all|*)             echo "linux pwa android ios watchos windows electron" ;;
    esac
}
