# Changelog — GT-IconScaler

All notable changes to this project will be documented in this file.
الالتزام بـ [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) و [Semantic Versioning](https://semver.org/).

---

## [2.2.0] — 2026-05-30

### Added — أُضيف
- **Batch / non-interactive mode** للـ CLI: خمس علامات تتخطى الخطوات التفاعلية:
  `--icon=PATH`, `--output=DIR`, `--name=NAME`, `--platforms=KEY`, `--compress=MODE`.
- **`--json` mode**: يكتم الديكور ويُخرج سطر JSON واحد على stdout بالشكل
  `{final_dir, done, failed, has_ico, has_icns, icns_method, compress, archives:[]}`.
  مُعدّ لاستدعاء البرامج (Electron GUI القادم، CI/CD، شِل scripts).
- **Hybrid fallback**: أي علم batch مفقود يرجع لخطوته التفاعلية المقابلة — لا يكسر استخدام v2.1.
- 11 مفتاح i18n جديد لخيارات batch ورسائل التحقق (ar + en) — الإجمالي 121 مفتاحاً.
- One-line curl install: `bash <(curl -sSL https://raw.githubusercontent.com/SalehGNUTUX/GT-IconScaler/main/install.sh)`.

### Fixed — إصلاحات
- **Bug قديم في `gt_distribute`**: لم يكن يوزّع على المنصات الفرعية لأن entry scripts تضبط
  `IFS=$'\n\t'` فيفشل `for ep in $enabled_platforms`. النتيجة كانت 46 ملفاً بدل 111.
  أُصلح بإعلان `local IFS=$' \t\n'` داخل الدالة.

### Changed — تغييرات
- `banner.title` أصبح `GT-IconScaler v2.2`.
- `CLAUDE.md` يوثّق Batch mode وقاعدة IFS للمكتبات.
- `.desktop` entries هذّبت Categories لتفادي ظهور التطبيق مرّتين في القائمة.

---

## [2.1.0] — 2026-05-25

### Added
- توحيد المنطق المشترك في `lib/`:
  - `gt-iconscaler-core.sh` — جدول 38 مقاساً، توزيع المنصات، gt_im_cmd.
  - `gt-iconscaler-formats.sh` — `.ico`/`.icns`/favicon/compression.
  - `gt-iconscaler-i18n.sh` — محمّل i18n.
- **i18n عربي/إنجليزي كامل** — 110 مفتاح، JSON كمصدر حقيقة، يُجمَّع لـ `.sh` عبر `i18n/build-bash.sh`.
- علامات `--help`, `--version`, `--lang=ar|en` في كلا السكربتين.
- `install.sh` ينسخ المكتبات إلى `share/gt-iconscaler/lib/` (محلي أو نظامي).
- 10 مقاسات جديدة: 44/50/70/150/310 (Windows Tiles)، 88/100/172/196/216 (Apple Watch)، 196 (Chrome Android)، 100 (iPad Pro Spotlight).
- منصتان جديدتان: `watchos/` و `windows/`.

### Changed
- `GT-IconScaler.sh` تقلّص من 590 إلى 323 سطر (قشرة CLI رفيعة).
- `GT-IconScaler-GUI.sh` تقلّص من 363 إلى 208 سطر (مع شريط تقدم zenity).

### Fixed
- `gt-iconscaler-gui.desktop` المكسور بـ `\n` حرفي.
- `install.sh` يستخدم الأيقونات الحقيقية بدل placeholder، يدعم IM6 + IM7.

---

## [2.0] — 2026-05-24

### Added
- النسخة الأولى المنشورة: 38 مقاساً عبر 8 منصات (Linux hicolor، PWA، Android mipmap، iOS، watchOS، Windows Tiles، Electron، macOS `.icns` + Windows `.ico` + favicon).
- نسختان للواجهة: CLI تفاعلي + Zenity GUI.

### Removed
- بقايا قديمة من قوالب C/Java/Node.js (Makefile، setup.sh، bin/، INSTALL.md، install.md).
