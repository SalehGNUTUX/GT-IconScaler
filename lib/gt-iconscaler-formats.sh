#!/usr/bin/env bash
# ============================================================
#  GT-IconScaler — Formats Library
#  محولات الصيغ: .ico (Windows), .icns (macOS), favicon
#  يفترض أن all/ موجود ومملوء (من gt_generate_all)
# ============================================================

# يعتمد على gt_im_cmd من core.sh (يجب أن تُسورس قبله أو معه)

# ────────────────────────────────────────────────────────────
#  gt_build_ico <final_dir> <basename>
#  يبني <basename>.ico من ملفات all/ بأحجام Windows القياسية
#  يعود 0 عند النجاح، 1 عند الفشل، 2 إن لم توجد ملفات مصدر
# ────────────────────────────────────────────────────────────
gt_build_ico() {
    local final_dir=$1
    local basename=$2
    local im
    im=$(gt_im_cmd) || return 1

    local ico_sizes=(16 24 32 48 64 128 256)
    local inputs=()
    local s png_path
    for s in "${ico_sizes[@]}"; do
        png_path="$final_dir/all/${s}x${s}/${basename}.png"
        [[ -f "$png_path" ]] && inputs+=("$png_path")
    done

    [[ ${#inputs[@]} -eq 0 ]] && return 2

    "$im" "${inputs[@]}" "$final_dir/${basename}.ico" 2>/dev/null
}

# ────────────────────────────────────────────────────────────
#  gt_build_favicon <final_dir> <basename>
#  ينشئ favicon/ مع favicon.ico + PNG بأحجام 16/32/48
# ────────────────────────────────────────────────────────────
gt_build_favicon() {
    local final_dir=$1
    local basename=$2
    local fav_dir="$final_dir/favicon"
    mkdir -p "$fav_dir"

    local s src
    for s in 16 32 48; do
        src="$final_dir/all/${s}x${s}/${basename}.png"
        [[ -f "$src" ]] && cp "$src" "$fav_dir/favicon-${s}x${s}.png"
    done

    [[ -f "$final_dir/${basename}.ico" ]] && \
        cp "$final_dir/${basename}.ico" "$fav_dir/favicon.ico"
}

# ────────────────────────────────────────────────────────────
#  gt_build_icns <final_dir> <basename>
#  يبني <basename>.icns عبر iconutil (macOS) أو png2icns (Linux)
#  أو ImageMagick كحل أخير
#  يضبط: GT_ICNS_METHOD = iconutil|png2icns|imagemagick|none
#  يعود 0 عند النجاح، 1 عند الفشل
# ────────────────────────────────────────────────────────────
gt_build_icns() {
    local final_dir=$1
    local basename=$2
    local out="$final_dir/${basename}.icns"
    GT_ICNS_METHOD="none"

    if command -v iconutil &>/dev/null; then
        local tmp
        tmp=$(mktemp -d -t gt-iconset-XXXXXX) || return 1
        local iconset_tmp="$tmp/${basename}.iconset"
        mkdir -p "$iconset_tmp"

        # خريطة Apple الرسمية لـ .iconset
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
        local fname s src
        for fname in "${!icns_map[@]}"; do
            s="${icns_map[$fname]}"
            src="$final_dir/all/${s}x${s}/${basename}.png"
            [[ -f "$src" ]] && cp "$src" "$iconset_tmp/$fname"
        done

        if iconutil -c icns "$iconset_tmp" -o "$out" 2>/dev/null; then
            GT_ICNS_METHOD="iconutil"
            rm -rf "$tmp"
            return 0
        fi
        rm -rf "$tmp"
        return 1
    fi

    if command -v png2icns &>/dev/null; then
        local srcs=()
        local s src
        for s in 16 32 128 256 512; do
            src="$final_dir/all/${s}x${s}/${basename}.png"
            [[ -f "$src" ]] && srcs+=("$src")
        done
        [[ ${#srcs[@]} -gt 0 ]] || return 1
        if png2icns "$out" "${srcs[@]}" 2>/dev/null; then
            GT_ICNS_METHOD="png2icns"
            return 0
        fi
        return 1
    fi

    # حل أخير: ImageMagick (دعم جزئي)
    local im
    im=$(gt_im_cmd) || return 1
    local src="$final_dir/all/512x512/${basename}.png"
    [[ -f "$src" ]] || return 1
    if "$im" "$src" "$out" 2>/dev/null; then
        GT_ICNS_METHOD="imagemagick"
        return 0
    fi
    return 1
}

# ────────────────────────────────────────────────────────────
#  gt_compress_package <export_dir> <package_name> <mode>
#  mode: zip | targz | both | none
# ────────────────────────────────────────────────────────────
gt_compress_package() {
    local export_dir=$1
    local pkg=$2
    local mode=$3

    (
        cd "$export_dir" || return 1
        case "$mode" in
            zip)
                command -v zip &>/dev/null && zip -rq "${pkg}.zip" "$pkg" ;;
            targz)
                tar -czf "${pkg}.tar.gz" "$pkg" ;;
            none)
                : ;;
            both|*)
                command -v zip &>/dev/null && zip -rq "${pkg}.zip" "$pkg"
                tar -czf "${pkg}.tar.gz" "$pkg" ;;
        esac
    )
}
