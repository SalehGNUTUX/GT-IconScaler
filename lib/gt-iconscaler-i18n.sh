#!/usr/bin/env bash
# ============================================================
#  GT-IconScaler — i18n Loader
#  دعم العربية والإنجليزية
#
#  الاستخدام:
#     source lib/gt-iconscaler-i18n.sh
#     gt_i18n_init                  # كشف تلقائي
#     gt_i18n_init "ar"             # فرض لغة
#     echo "$(t banner.title)"
#     printf '%s\n' "$(t step.4.opt1 38)"
#
#  أولوية الكشف:
#     1) معامل صريح إلى gt_i18n_init
#     2) متغير GT_LANG
#     3) LANG يبدأ بـ ar_ → عربي
#     4) الافتراضي: en
# ============================================================

# جدول الترجمة العام
declare -gA T

# الموقع الذاتي للمكتبة (نفس مكان ملفات i18n-{ar,en}.sh)
GT_I18N_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GT_LANG_CURRENT=""

# ────────────────────────────────────────────────────────────
#  gt_i18n_detect [override]
#  يطبع رمز اللغة المختار
# ────────────────────────────────────────────────────────────
gt_i18n_detect() {
    local override="${1:-}"
    local lang

    if [[ -n "$override" ]]; then
        lang="$override"
    elif [[ -n "${GT_LANG:-}" ]]; then
        lang="$GT_LANG"
    else
        # ar_SA.UTF-8 → ar ، en_US.UTF-8 → en ، ar → ar
        local loc="${LANG:-en}"
        loc="${loc%%[._]*}"
        case "$loc" in
            ar) lang="ar" ;;
            *)  lang="en" ;;
        esac
    fi

    # تطبيع
    case "$lang" in
        ar|en) echo "$lang" ;;
        *)     echo "en" ;;
    esac
}

# ────────────────────────────────────────────────────────────
#  gt_i18n_init [lang_override]
#  يحمّل جدول الترجمة وفقاً للغة المكتشفة
# ────────────────────────────────────────────────────────────
gt_i18n_init() {
    local lang
    lang=$(gt_i18n_detect "${1:-}")

    local file="$GT_I18N_DIR/i18n-${lang}.sh"
    if [[ ! -f "$file" ]]; then
        # تراجع إلى الإنجليزية
        lang="en"
        file="$GT_I18N_DIR/i18n-en.sh"
    fi

    [[ -f "$file" ]] || {
        echo "Error: i18n files not built. Run i18n/build-bash.sh" >&2
        return 1
    }

    # تفريغ وإعادة تحميل
    unset T
    declare -gA T
    # shellcheck source=/dev/null
    source "$file"
    GT_LANG_CURRENT="$lang"
}

# ────────────────────────────────────────────────────────────
#  t <key> [printf_args...]
#  - بدون args إضافية: يطبع النص الخام
#  - مع args: يعامل النص كـ printf format
# ────────────────────────────────────────────────────────────
t() {
    local key="$1"
    shift
    local val="${T[$key]:-}"
    [[ -z "$val" ]] && val="$key"   # fallback: المفتاح نفسه عند الغياب
    if (( $# == 0 )); then
        echo "$val"
    else
        # shellcheck disable=SC2059
        printf "$val\n" "$@"
    fi
}

# نسخة بدون \n في النهاية (للسلاسل المضمَّنة في رسائل أكبر)
tn() {
    local key="$1"
    shift
    local val="${T[$key]:-$key}"
    if (( $# == 0 )); then
        printf '%s' "$val"
    else
        # shellcheck disable=SC2059
        printf "$val" "$@"
    fi
}

# ────────────────────────────────────────────────────────────
#  gt_i18n_dir
#  يطبع ltr أو rtl حسب اللغة الحالية (مفيد للـ GUI)
# ────────────────────────────────────────────────────────────
gt_i18n_dir() {
    case "$GT_LANG_CURRENT" in
        ar) echo "rtl" ;;
        *)  echo "ltr" ;;
    esac
}
