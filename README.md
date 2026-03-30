# GT-IconScaler v2.0

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

**أداة احترافية لتوليد وتحويل الأيقونات لجميع المنصات (CLI وGUI).**

---

## 🚀 التثبيت السريع

### الطريقة 1: من الإنترنت مباشرة
```bash
bash <(curl -sSL https://raw.githubusercontent.com/SalehGNUTUX/GT-IconScaler/main/install.sh)
```

### الطريقة 2: التثبيت التقليدي
```bash
git clone https://github.com/SalehGNUTUX/GT-IconScaler.git
cd GT-IconScaler
sudo bash install.sh
```

---

## 📋 المتطلبات

- **ImageMagick** (مطلوب)
- **zenity** (اختياري - للواجهة الرسومية)

### تثبيت المتطلبات

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install imagemagick zenity
```

**Fedora:**
```bash
sudo dnf install ImageMagick zenity
```

**Arch:**
```bash
sudo pacman -S imagemagick zenity
```

---

## 💻 الاستخدام

```bash
# النسخة الطرفية
gt-iconscaler

# النسخة الرسومية
gt-iconscaler-gui
```

---

## ⚠️ حل المشاكل

### خطأ: "الدليل './src' غير موجود"

**الحل التلقائي:** سيتم إنشاء المجلدات تلقائياً.

**الحل اليدوي:**
```bash
mkdir -p bin src GT-IconScaler-CLI-ICON-icons GT-IconScaler-GUI-ICON-icons
```

### خطأ: "ImageMagick غير مثبت"

ثبّت ImageMagick (انظر أعلى).

---

## ✨ الميزات

- ✅ 31 حجم أيقونة (16px - 1024px)
- ✅ 7 منصات (Linux, PWA, Android, iOS, Windows, macOS, Electron)
- ✅ واجهات CLI و GUI
- ✅ دعم عربي كامل
- ✅ تثبيت آلي

---

## 📜 الترخيص

GPL-3.0 - انظر [LICENSE](LICENSE)

---

**للمساعدة:** فتح issue في المستودع


