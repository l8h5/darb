# T-001 — شاشة الخريطة الأولى

## الهدف
فتح التطبيق على خريطة حقيقية لمدينة حائل، مع إمكانية تحريك الخريطة وتكبيرها،
وزر للعودة إلى حائل، وزر لعرض كامل المملكة، وزر "موقعي" يطلب إذن الموقع
عند الضغط فقط.

## النتيجة المتوقعة
- يفتح التطبيق على حائل بمستوى تكبير 11.
- الخريطة تتحرك وتُكبَّر باللمس، ولا تدور (شمالية دائماً).
- شريط أعلى الشاشة يعرض إحداثيات مركز الخريطة أثناء التحريك.
- زر "المملكة" يضبط الكاميرا على حدود المملكة.
- زر "حائل" يعيد الكاميرا إلى حائل.
- زر "موقعي" يطلب إذن الموقع، ثم ينقل الخريطة إلى موقع المستخدم بنقطة زرقاء.
- عند رفض الإذن أو إغلاق خدمة الموقع تظهر رسالة عربية مع زر يفتح الإعدادات المناسبة.
- نص إسناد OpenStreetMap ظاهر دائماً أسفل الشاشة.

## الملفات المتأثرة
| الملف | الدور |
| --- | --- |
| `lib/main.dart` | جذر التطبيق: عربي، RTL، سمة Material 3 |
| `lib/core/app_config.dart` | كل الثوابت: مركز حائل، حدود المملكة، رابط البلاطات، User-Agent |
| `lib/services/location_service.dart` | غلاف حول geolocator، لا تعرف الواجهة شيئاً عنه |
| `lib/screens/map_screen.dart` | واجهة الخريطة والأزرار |
| `android/app/src/main/AndroidManifest.xml` | إذن الإنترنت وإذن الموقع، واسم التطبيق "درب حائل" |
| `test/widget_test.dart` | اختبارات `AppConfig` (حدود المملكة، مستويات التكبير، قالب البلاطات) |
| `pubspec.yaml` | flutter_map 8.3.2، latlong2، geolocator، flutter_localizations |

## طريقة التشغيل
```powershell
cd "C:\Users\NXTLVL\Documents\Tools\Darb Hail"
C:\Users\NXTLVL\dev\f.cmd run
```

## الاختبار
```powershell
C:\Users\NXTLVL\dev\f.cmd analyze   # لا أخطاء
C:\Users\NXTLVL\dev\f.cmd test      # 4 اختبارات ناجحة
C:\Users\NXTLVL\dev\f.cmd build apk --debug
```

## النتيجة

### ثابت (تم التحقق منه)
| الفحص | النتيجة |
| --- | --- |
| `flutter analyze` | لا ملاحظات |
| `flutter test` | 4/4 ناجحة |
| `flutter build apk --debug` | نجح في 418 ثانية |
| ملف الخرج | `build\app\outputs\flutter-apk\app-debug.apk` (155 ميجا — حجم طبيعي لبناء debug) |
| `package` | `sa.darbhail.darb_hail` |
| `minSdk / targetSdk` | 24 / 36 |
| الأذونات داخل APK | `INTERNET`, `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` |
| اسم التطبيق | `درب حائل` في كل اللغات |

### تم التحقق على جهاز حقيقي (Honor VNE-N41، Android 12، 720×1600)

| الاختبار | النتيجة | الدليل |
| --- | --- | --- |
| فتح التطبيق على حائل | نجح | `docs/screenshots/T-001-map-hail.png` |
| تنزيل بلاطات OSM | نجح | لون أرض OSM `rgb(242,239,233)` يغطي 41.7% من الصورة + 2163 لوناً مختلفاً |
| التصغير إلى المملكة | نجح بلا أخطاء بعد إضافة حدّ الاتصالات | لا وجود لـ `E/flutter` في logcat |
| «موقعي» | نجح: تحركت الخريطة إلى الموقع وظهرت النقطة الزرقاء | `docs/screenshots/T-001-location.png` — لون `#1A73E8` في مركز الشاشة |
| إذن الموقع | `granted=true`، دقة 17.8 م | `dumpsys package` + `dumpsys location` |
| سجل الأخطاء | لا استثناءات Dart | logcat |

**ملاحظة:** إذن الموقع مُنح يدوياً عبر `adb pm grant` أثناء الاختبار. اختبار نافذة الإذن نفسها (السماح/الرفض من المستخدم) ما زال مطلوباً بعد إلغاء الإذن.

### عقبات واجهناها أثناء البناء (وحلولها)
1. قفل Gradle بسبب بناءين متزامنين — انظر `docs/environment-setup.md`.
2. NDK مفقودة — نزّلنا r28c يدوياً إلى `android-sdk\ndk\28.2.13676358`.
3. Gradle ثبّت تلقائياً `platforms;android-35` و`cmake;3.22.1` لأنهما مطلوبان لمشروع CMake الداخلي في Flutter.

## قرارات مرتبطة
- D-001: `flutter_map` 8.x مع بلاطات OSM، أونلاين فقط.
- D-002: `userAgentPackageName` إلزامي، والإسناد ظاهر دائماً.
- D-006: لا تدوير للخريطة في MVP (يبسّط الإحساس بالاتجاه).
