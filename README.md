<div align="center">
  
# GT-IconScaler v2.0

**أداة احترافية لتوليد وتحويل الأيقونات لجميع المنصات (CLI وGUI)**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Platform-Linux-yellow.svg)](https://www.linux.org/)
[![Version](https://img.shields.io/badge/Version-2.0-red.svg)]()


| شعار نسخة الطرفية | شعار نسخة الواجهة| 
| :--- | :---: |
| ![نص بديل](https://github.com/SalehGNUTUX/GT-IconScaler/blob/main/GT-IconScaler-CLI-ICON-icons/all/256x256/GT-IconScaler-CLI-ICON.png?raw=true) | ![نص بديل](https://github.com/SalehGNUTUX/GT-IconScaler/blob/main/GT-IconScaler-GUI-ICON-icons/all/256x256/GT-IconScaler-GUI-ICON.png?raw=true) |
</div>

---

## ✨ المميزات

- ✅ **31 حجم أيقونة** (من 16px إلى 1024px)
- ✅ **7 منصات مدعومة** (Linux, PWA, Android, iOS, Windows, macOS, Electron)
- ✅ **واجهتان** (سطر الأوامر CLI والواجهة الرسومية GUI)
- ✅ **دعم عربي كامل** في الرسائل والواجهات
- ✅ **تثبيت آلي** مع اكتشاف مدير الحزم
- ✅ **توليد .ico** متعدد الأحجام لـ Windows
- ✅ **توليد .icns** لـ macOS (عند توفر الأدوات)
- ✅ **ملف README تلقائي** داخل الحزمة المُصدَّرة
- ✅ **ضغط تلقائي** (ZIP / tar.gz)

---

## 📦 المتطلبات

### أساسية (مطلوبة)
- **ImageMagick** – لمعالجة الصور وتحويل الأحجام

### اختيارية
- **zenity** – للواجهة الرسومية (GUI)
- **iconutil / icnsutils** – لتوليد .icns (macOS)
- **git** – لاستنساخ المستودع (للتثبيت اليدوي)

### تثبيت المتطلبات حسب نظامك

| نظام التشغيل | الأوامر |
|--------------|---------|
| **Ubuntu/Debian** | `sudo apt update && sudo apt install imagemagick zenity git` |
| **Fedora** | `sudo dnf install ImageMagick zenity git` |
| **Arch Linux** | `sudo pacman -S imagemagick zenity git` |
| **openSUSE** | `sudo zypper install ImageMagick zenity git` |

> **ملاحظة:** يمكنك استخدام الأداة بدون zenity إذا كنت تفضل واجهة سطر الأوامر فقط.

---

## 🚀 التثبيت السريع

### الطريقة 1: التثبيت المباشر من الإنترنت (الأسهل)
```bash
bash <(curl -sSL https://raw.githubusercontent.com/SalehGNUTUX/GT-IconScaler/main/install.sh)
```

### الطريقة 2: التثبيت المحلي (للمطورين)
```bash
git clone https://github.com/SalehGNUTUX/GT-IconScaler.git
cd GT-IconScaler
chmod +x install.sh
./install.sh          # للتثبيت المحلي (للمستخدم الحالي)
# أو
sudo ./install.sh     # للتثبيت النظامي (لجميع المستخدمين)
```

### الطريقة 3: التشغيل المباشر (بدون تثبيت)
```bash
git clone https://github.com/SalehGNUTUX/GT-IconScaler.git
cd GT-IconScaler
chmod +x GT-IconScaler.sh GT-IconScaler-GUI.sh
./GT-IconScaler.sh    # للتشغيل المباشر
```

---

## 💻 الاستخدام

### 🖥️ النسخة الطرفية (CLI)
```bash
gt-iconscaler
```
ستظهر لك واجهة تفاعلية تطلب:
1. **اختيار ملف الأيقونة** (PNG, SVG, JPG, WebP)
2. **اختيار مجلد التصدير**
3. **تحديد اسم الحزمة**
4. **اختيار المنصات المطلوبة** (Linux, PWA, Android, iOS, Electron)
5. **اختيار نوع الضغط** (ZIP, tar.gz, أو بدون ضغط)

### 🎨 النسخة الرسومية (GUI)
```bash
gt-iconscaler-gui
```
ستظهر نافذة رسومية باستخدام zenity لتوجيهك خلال جميع الخطوات بسهولة.

---

## 🎯 المنصات المدعومة

| المنصة | المسار | الاستخدام | الأحجام المدعومة |
|--------|--------|-----------|------------------|
| **Linux** | `linux/` | hicolor XDG Icon Theme | 16, 22, 24, 32, 48, 64, 96, 128, 256, 512 |
| **PWA** | `pwa/` | Web Manifest + Apple Touch Icon | 16, 32, 48, 72, 96, 128, 144, 152, 167, 180, 192, 256, 384, 512 |
| **Android** | `android/` | mipmap-ldpi → mipmap-xxxhdpi | 36, 48, 72, 96, 144, 192 |
| **iOS** | `ios/` | App Icon (iPhone, iPad, App Store) | 20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 512, 1024 |
| **Windows** | `.ico` | ملف ICO متعدد الأحجام | 16, 24, 32, 48, 64, 128, 256 |
| **macOS** | `.icns` | ملف ICNS (إذا توفرت الأدوات) | 16, 32, 64, 128, 256, 512, 1024 |
| **Electron** | `electron/` | أيقونات تطبيقات Electron | 16, 32, 64, 128, 256, 512, 1024 |
| **Favicon** | `favicon/` | أيقونات المتصفح | 16, 32, 48 |

---

## 📁 هيكل المخرجات

بعد تشغيل الأداة، سيتم إنشاء مجلد به الهيكل التالي:

```
اسم_الحزمة-icons/
├── all/                      # جميع الأحجام (مصدر للمنصات الأخرى)
│   ├── 16x16/
│   ├── 32x32/
│   └── ... (جميع الأحجام)
├── linux/                    # أيقونات Linux (hicolor)
│   ├── 16x16/apps/
│   ├── 32x32/apps/
│   └── ...
├── pwa/                      # أيقونات تطبيقات الويب
│   ├── icon-16x16.png
│   ├── icon-32x32.png
│   └── ...
├── android/                  # أيقونات Android
│   ├── mipmap-ldpi/ic_launcher.png
│   ├── mipmap-mdpi/ic_launcher.png
│   └── ...
├── ios/                      # أيقونات iOS
│   ├── Icon-20.png
│   ├── Icon-29.png
│   └── ...
├── electron/                 # أيقونات Electron
│   └── icon.png
├── favicon/                  # أيقونات المتصفح
│   ├── favicon.ico
│   ├── favicon-16x16.png
│   └── favicon-32x32.png
├── اسم_الأيقونة.ico          # ملف Windows متعدد الأحجام
├── اسم_الأيقونة.icns         # ملف macOS (إن توفر)
└── README.md                 # ملف توضيحي للمخرجات
```

---

## 🛠️ حل المشاكل

### ❌ خطأ: "الدليل './src' غير موجود"
**الحل:** هذا الخطأ من السكربتات القديمة. المثبت الجديد يتعامل معه تلقائياً. إذا ظهر، نفّذ:
```bash
mkdir -p bin src include lib
```

### ❌ خطأ: "ImageMagick غير مثبت"
**الحل:** ثبّت ImageMagick باستخدام مدير الحزم الخاص بك:
```bash
# Ubuntu/Debian
sudo apt install imagemagick

# Fedora
sudo dnf install ImageMagick

# Arch
sudo pacman -S imagemagick
```

### ❌ خطأ: "command not found: gt-iconscaler"
**الحل:** أعد تشغيل الطرفية أو أضف المسار يدوياً:
```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### ❌ خطأ: "zenity غير موجود"
**الحل:** ثبّت zenity أو استخدم النسخة الطرفية (CLI):
```bash
# تثبيت zenity
sudo apt install zenity   # Ubuntu/Debian
sudo dnf install zenity   # Fedora
sudo pacman -S zenity     # Arch
```

### ❌ خطأ: "لا توجد صلاحيات للتثبيت"
**الحل:** استخدم `sudo` للتثبيت النظامي:
```bash
sudo ./install.sh
```

### ❌ مشكلة: الأيقونات الناتجة ضبابية
**الحل:** استخدم أيقونة مصدر بدقة عالية (1024x1024 أو أكبر) بصيغة PNG مع خلفية شفافة.

---

## 🗑️ إزالة التثبيت

### إذا قمت بالتثبيت عبر المثبت
```bash
# للتثبيت النظامي
sudo rm -f /usr/local/bin/gt-iconscaler
sudo rm -f /usr/local/bin/gt-iconscaler-gui
sudo rm -f /usr/share/applications/gt-iconscaler-gui.desktop
sudo rm -rf /usr/share/icons/hicolor/*/apps/gt-iconscaler-gui.png

# للتثبيت المحلي
rm -f ~/.local/bin/gt-iconscaler
rm -f ~/.local/bin/gt-iconscaler-gui
rm -f ~/.local/share/applications/gt-iconscaler-gui.desktop
rm -rf ~/.local/share/icons/hicolor/*/apps/gt-iconscaler-gui.png

# تحديث قواعد البيانات
update-icon-caches ~/.local/share/icons 2>/dev/null || true
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

### استخدام سكربت الإزالة الموجود
```bash
./uninstall.sh
```

---

## 🤝 المساهمة والتطوير

نرحب بمساهماتكم! يمكنكم المساعدة من خلال:

1. **الإبلاغ عن مشاكل** – عبر [Issues](https://github.com/SalehGNUTUX/GT-IconScaler/issues)
2. **اقتراح تحسينات** – عبر Pull Requests
3. **ترجمة الواجهات** – إضافة دعم لغات جديدة
4. **تطوير المثبت** – دعم المزيد من مديري الحزم

### بيئة التطوير
```bash
git clone https://github.com/SalehGNUTUX/GT-IconScaler.git
cd GT-IconScaler
chmod +x *.sh
# عدّل السكربتات حسب الحاجة
./GT-IconScaler.sh  # للاختبار
```

---

## 📜 الترخيص

هذا المشروع مرخص تحت رخصة **GNU General Public License v3.0** – انظر ملف [LICENSE](LICENSE) للتفاصيل.

---

## 👤 المطور

**GNUtux (SalehGNUTUX)**  
- 🌐 [GitHub](https://github.com/SalehGNUTUX)
- 📧 [saleh@gnutux.com](mailto:saleh@gnutux.com)

---

<div align="center">

**⭐ إذا أعجبك المشروع، لا تنسَ وضع نجمة على GitHub!**  
**شكراً لاستخدامك GT-IconScaler**

---

*آخر تحديث: 30 مارس 2026*

</div>
