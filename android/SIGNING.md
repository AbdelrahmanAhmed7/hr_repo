# توقيع تطبيق Medi HR (Android)

## الملفات المهمة (لا ترفعها على Git)

| الملف | الوصف |
|--------|--------|
| `app/upload-keystore.jks` | مفتاح الرفع (Upload key) — **احتفظ بنسخة احتياطية آمنة** |
| `key.properties` | كلمات مرور المفتاح |

## بيانات المفتاح الحالي

- **Alias:** `upload`
- **Store password:** `MediHR_Upload_2026!`
- **Key password:** `MediHR_Upload_2026!`
- **الصلاحية:** 10,000 يوم (~27 سنة)

> غيّر كلمات المرور في `key.properties` وفي الـ keystore إذا أردت أماناً أعلى قبل الإنتاج.

## بناء ملف الرفع (AAB)

من جذر المشروع:

```bash
flutter build appbundle --release
```

الملف الناتج:

```
build/app/outputs/bundle/release/app-release.aab
```

ارفع هذا الملف في Google Play Console → Testing → Closed testing.

## SHA-1 / SHA-256 (Firebase & Google Sign-In)

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload -storepass "MediHR_Upload_2026!"
```

أضف القيم في Firebase Console → Project settings → Your apps → Android.

## إنشاء مفتاح جديد (اختياري)

```powershell
cd android/app
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

ثم حدّث `android/key.properties` بنفس القيم.

## Play App Signing

عند أول رفع، فعّل **Google Play App Signing**. Google يحتفظ بمفتاح التوقيع النهائي؛ أنت تستخدم **upload key** فقط (`upload-keystore.jks`).

**فقدان الـ keystore = لا يمكنك رفع تحديثات جديدة** (إلا عبر دعم Google Play مع إثبات الملكية).
