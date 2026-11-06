# T-003 — التهيئة الأولية والإعدادات

**التاريخ:** 2026-11-06
**النطاق:** المرحلة الثانية من خطة التطوير (Onboarding + Preferences + Settings)
**القاعدة:** Extend, Don't Rewrite — لا تغيير في المعمارية أو المكتبات أو مصدر الخرائط.

---

## 1. تقرير الفحص (Audit)

### 1.1 الحالة الفعلية للمشروع

| البند | الواقع في الكود (لا الافتراض) |
|---|---|
| المعمارية | Feature-first: `lib/features/{map,spots}` + `lib/core` + `lib/app` |
| إدارة الحالة | `StatefulWidget` + `ValueNotifier` فقط. **لا يوجد** flutter_bloc/Cubit |
| الشبكة | `http` + `IOClient` + `RetryClient` لبلاطات الخريطة. **لا يوجد** Dio |
| الخريطة | `flutter_map` 8.3.2 + `latlong2` + 3 طبقات (OSM / OpenTopoMap / EOX Sentinel-2) |
| GPS | `geolocator`، طلب الموقع عند الضغط فقط، بلا اشتراكات أو تتبع خلفي |
| التخزين | SQLite للأماكن المحفوظة + `shared_preferences` (كان للترحيل فقط) |
| التنقل | `Navigator` مباشر. لا يوجد GoRouter ولا شاشة رئيسية |
| DI | لا يوجد GetIt؛ الخدمات تُنشأ داخل الشاشة |
| الطقس / القبلة / الرحلات | **غير موجودة** كملفات أو شاشات أو خدمات |
| الحسابات | لا يوجد تسجيل دخول ولا سيرفر |

### 1.2 الموجود فعلاً ويعمل

- الخريطة، تحديد الموقع عند الطلب، حفظ/تعديل/حذف مكان في SQLite، الطبقات الثلاث،
  التخزين المؤقت للبلاطات التي زارها المستخدم فقط (150 م.ب)، سطر الإسناد.
- اختبارات SQLite والترحيل والطبقات والتهيئة.

### 1.3 غير موجود (لذلك لم يُحسَّن ولم تُضف له أزرار)

- Home، Weather، Qibla، Trips/Track Recording، Offline Region Download، Compass.
- لا توجد بيانات طقس أو قبلة أو رحلات يمكن عرضها؛ إضافة واجهات لها الآن
  ستكون أزراراً وهمية، وهو ممنوع في المتطلبات.

### 1.4 الملفات القابلة لإعادة الاستخدام

`MapHeader`, `MapAttribution`, `MapLayerSheet`, `MapView`, `MyLocationDot`,
`SavedPlaceMarker`, `PlaceNameDialog`, `SavedPlacesSheet`,
`CoordinateFormatter`, `DistanceFormatter`.

---

## 2. ما تم تنفيذه

### 2.1 التهيئة الأولية (5 خطوات)

- ترحيب بهوية درب + شرح الخصوصية.
- اختيار نمط الاستخدام: **بسيط (افتراضي)** أو متقدم.
- اختيار الطبقة الافتراضية من الطبقات الثلاث الموجودة فعلاً.
- تفضيلات الاستخدام: صيغة الإحداثيات + وحدة المسافة + اللغة (العربية ثابتة).
- ملخص نهائي ثم «ابدأ رحلتك مع درب».
- زر تخطي في كل خطوة، والحالة تُحفظ قبل الانتقال للخريطة.
- لا تُطلب أي صلاحية جهاز أثناء التهيئة.

### 2.2 التخزين المركزي

- `UserPreferences` نموذج واحد مع `schemaVersion` وقيم افتراضية آمنة.
- `PreferencesRepository` يحفظ JSON في `shared_preferences` (لم نضف قاعدة بيانات).
- `PreferencesController` هو المصدر الوحيد للحالة، ويُشارَك عبر
  `PreferencesScope` (`InheritedNotifier`) — بلا حزمة إدارة حالة جديدة.
- فشل القراءة/الكتابة لا يمنع تشغيل التطبيق: يعود للافتراضي أو يكمل بالذاكرة.
- إعادة تشغيل التهيئة متاحة من الإعدادات، ولا تمس الأماكن المحفوظة.

### 2.3 التطبيق الفعلي للاختيارات

- **النمط البسيط:** معلومات أساسية + موقعي + الأماكن المحفوظة + الإعدادات.
- **النمط المتقدم:** يضيف دقة GPS في الشريط وزر تبديل الطبقات على الخريطة.
- **الطبقة الافتراضية:** تُفتح الخريطة عليها، وتتغير فوراً عند تغييرها من الإعدادات.
- **صيغة الإحداثيات:** تُطبَّق على شريط الخريطة وقائمة الأماكن المحفوظة.
- **وحدة المسافة:** تُطبَّق على المسافة إلى الأماكن المحفوظة عند توفر موقع معروف.
- التبديل بين النمطين فوري دون إعادة تشغيل، ولا يمس حالة الخريطة أو الطبقة الحالية.

### 2.4 الإعدادات

نمط الاستخدام، الطبقة الافتراضية، وحدة المسافة، صيغة الإحداثيات، شرح صلاحية
الموقع مع فتح إعدادات التطبيق، إعادة التهيئة، ومعلومات الإصدار.

---

## 3. الملفات

### جديدة

```
lib/features/settings/domain/user_preferences.dart
lib/features/settings/data/preferences_repository.dart
lib/features/settings/presentation/preferences_controller.dart
lib/features/settings/presentation/preferences_scope.dart
lib/features/settings/presentation/settings_screen.dart
lib/features/onboarding/presentation/onboarding_screen.dart
lib/features/onboarding/presentation/widgets/onboarding_steps.dart
lib/features/onboarding/presentation/widgets/onboarding_usage_steps.dart
lib/features/onboarding/presentation/widgets/onboarding_widgets.dart
lib/features/map/presentation/widgets/map_view.dart
lib/core/format/coordinate_formatter.dart
lib/core/format/distance_formatter.dart
test/user_preferences_test.dart
test/format_test.dart
test/onboarding_test.dart
```

### معدّلة

```
lib/main.dart
lib/app/app.dart
lib/core/config/app_config.dart
lib/features/map/presentation/map_screen.dart
lib/features/map/presentation/widgets/map_header.dart
lib/features/spots/presentation/saved_places_sheet.dart
pubspec.yaml (تعليق فقط — لا اعتماديات جديدة)
```

---

## 4. الاختبارات

- `flutter analyze`: **No issues found**.
- `flutter test`: **32 اختباراً ناجحاً**، منها:
  - القيم الافتراضية وعدم كسر التشغيل عند بيانات تالفة.
  - حفظ/استرجاع التفضيلات، إكمال التهيئة، التخطي، إعادة التهيئة.
  - فشل التخزين لا يمنع الاستخدام.
  - تنسيق الإحداثيات (عشري / DMS / جنوب وغرب).
  - تنسيق المسافة (م / كم / ميل).
  - التهيئة: التخطي، واختيار الوضع المتقدم ثم الإكمال.
- `flutter build apk --debug`: **نجح**.

### التحقق على الجهاز

تعذّر في هذه الجولة: الجهاز `AAYSNU2702203627` انقطع عن adb قبل التثبيت.
التحقق المطلوب عند reconnect: ظهور التهيئة أول تشغيل، إكمالها، عدم ظهورها بعد
إعادة التشغيل، تطبيق الوضع/الطبقة/الصيغة، وعدم وجود overflow في logcat.

---

## 5. قرارات وحدود

- **لا Bloc/Dio/Hive/GetIt:** غير موجودة أصلاً؛ إضافتها ستكون تغييراً معمارياً
  بلا حاجة. استخدمنا `ChangeNotifier` المدمج.
- **لا إعدادات إشعارات أو بوصلة:** لا توجد ميزة تستخدمها بعد؛ إظهار المفتاح
  سيكون تحكماً وهمياً.
- **لا تنزيل مناطق أوفلاين:** سياسة OSM تمنع التنزيل الجماعي. الموجود حالياً
  تخزين مؤقت للبلاطات المزارة فقط، وهو ليس Offline Maps كاملاً.
- **اللغة:** العربية فقط حالياً؛ لم نضف مبدّلاً لا يغيّر شيئاً.

---

## 6. الحالة

| البند | الحالة |
|---|---|
| التهيئة + التفضيلات + الإعدادات | Implemented |
| تطبيق النمط والطبقة وصيغة الإحداثيات والمسافة | Implemented |
| التحقق على الجهاز | Blocked (الجهاز غير متصل) |
| Home / Weather / Qibla / Trips | Planned (غير موجودة بعد) |
| Offline Maps بمناطق قابلة للتنزيل | Planned + يحتاج مصدراً مرخّصاً |
