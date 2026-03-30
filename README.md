# GT-IconScaler

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

**أداة مجانية لتحويل وتوليد مختلف أحجام أيقونات المشاريع البرمجية (CLI وواجهة رسومية GUI)، وتثبيتها بشكل متكامل مع النظام (أيقونات، اختصارات قائمة التطبيقات، دعم إزالة التثبيت بسهولة).**

---

## ⭐ نظرة سريعة

- دعم توليد الأيقونات لمختلف الحزم (Linux, Windows, Mac)
- نسخة سطر أوامر (CLI) وواجهة رسومية (GUI)
- تكامل كامل مع قوائم البرامج عبر ملفات `.desktop`
- سكريبت تثبيت و إلغاء احترافي: يدير الأيقونات، الاختصارات، وإزالة كل شيء بنقرة

---

## 🚀 التثبيت (Installation)

**تثبيت مباشر من المستودع:**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/SalehGNUTUX/GT-IconScaler/main/install.sh)
```

**أو التثبيت التقليدي:**
```bash
git clone https://github.com/SalehGNUTUX/GT-IconScaler.git
cd GT-IconScaler
sudo ./install.sh
```
سيظهر لك سكريبت تفاعلي لاختيار التثبيت (CLI أو GUI أو كلاهما).

**بعد التثبيت:**
- شغل من القائمة أو بالأمر:
    - الواجهة الرسومية:  
      `gt-iconscaler-gui`
    - سطر الأوامر:  
      `gt-iconscaler-cli`

---

## 🔧 إلغاء التثبيت (Uninstall)

لإزالة كل شيء (الأيقونات، الاختصارات، الملفات):

```bash
sudo gt-iconscaler-uninstall
```
ستحصل على تأكيد قبل الإزالة النهائية.

---

## 📦 مميزات رئيسية (Main features)

- تثبيت أوتوماتيكي للأيقونات بجميع الأحجام القياسية
- إنشاء ملفات `.desktop` للبحث والتشغيل من القائمة
- سكريبت تثبيت احترافي بواجهة ملونة ودعم عربي–إنجليزي
- سكريبت إلغاء تثبيت ينظف كل شيء تماما
- خفيف وسهل ويعمل على الغالبية العظمى من توزيعات لينكس

---

## 🔥 أمثلة للاستخدام (Usage examples)

### سطر الأوامر (CLI)
```bash
gt-iconscaler-cli --input=myicon.png --sizes=16,32,48,64,128,256,512
```

### الواجهة الرسومية (GUI)
ابحث في قائمة البرامج عن  
**GT-IconScaler GUI**  
أو شغل:
```bash
gt-iconscaler-gui
```

---

## 🏷️ تراخيص (License)
[GPL-3.0](LICENSE)

---

## ❤️ ساهم أو تواصل (Contribute / Contact)
- [SalehGNUTUX على GitHub](https://github.com/SalehGNUTUX)
- الاقتراحات/الدعم: افتح Issue جديد في الريبو

---

**السكريبتات والوثائق تدعم العربية بشكل كامل، وتم تبسيط كل الأوامر!**
