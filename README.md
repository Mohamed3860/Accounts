# Amania Arabic EGP

تطبيق Flutter عربي لإدارة العملاء والمنتجات والفواتير والمدفوعات محليًا.

## البناء محليًا

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

## البناء على GitHub

ارفع المشروع كما هو إلى GitHub ثم شغل workflow باسم **Build Android APK**.

## ملاحظات

- اللغة العربية فقط.
- العملة EGP فقط.
- التخزين محلي باستخدام SharedPreferences.
- النسخ الاحتياطي والاستعادة بصيغة JSON.
