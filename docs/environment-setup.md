# بيئة التطوير على هذا الجهاز

كل شيء مثبّت داخل حساب المستخدم `C:\Users\NXTLVL\dev` بدون صلاحيات مدير.

| الأداة | المسار | الإصدار |
| --- | --- | --- |
| Flutter | `C:\Users\NXTLVL\dev\flutter` | 3.47.9 (stable) |
| Dart | داخل Flutter | 3.13.7 |
| JDK | `C:\Users\NXTLVL\dev\jdk17` | Temurin 17.0.21 |
| Android SDK | `C:\Users\NXTLVL\dev\android-sdk` | platform-tools 37.0.1 |
| منصّة البناء | `android-sdk\platforms\android-36` | API 36 |
| أدوات البناء | `android-sdk\build-tools\36.0.0` | 36.0.0 |
| NDK | `android-sdk\ndk\28.2.13676358` | r28c |

## تشغيل أوامر Flutter

`flutter` غير مضاف إلى PATH (لتجنّب تعارض مع نسخ أخرى). استخدم:

```powershell
C:\Users\NXTLVL\dev\f.cmd <الأمر>
# مثال
C:\Users\NXTLVL\dev\f.cmd run
```

الملف `f.cmd` يضبط `JAVA_HOME` و`ANDROID_HOME` و`PATH` ثم يشغّل
`flutter_tools.snapshot` مباشرة عبر `dart.exe`. السبب: `flutter.bat` و`flutter doctor`
كانا يتجمّدان في هذه البيئة عند تشغيلهما من PowerShell.

نسخة ثانية `flutter.cmd` تستدعي `flutter.bat`؛ تُستخدم فقط عند الحاجة.

## مشاكل حُلّت (لا تعد إليها)

### 1. لا تشغّل أمرَي بناء في وقت واحد
خطأ `Timeout of 120000 reached waiting for exclusive access to file:
gradle-9.3.1-all.zip` ليس خطأ شبكة، بل عمليتان تحاولان استخدام نفس ملف Gradle.
شغّل أمراً واحداً وانتظر انتهاءه.

### 2. NDK إلزامية في Flutter 3.47
أدوات Flutter تستدعي `forceNdkDownload` في كل بناء، وAGP 9 يعطي `ndkVersion`
قيمة افتراضية `28.2.13676358`. حذف السطر من `app/build.gradle.kts` لا يمنع الطلب.

أدوات SDK الحديثة (`android.exe`) لا تفهم صيغة Flutter
`sdkmanager --install "ndk;28.2.13676358"`، поэтому تفشل الأتمتة.
الحل المستخدم: تنزيل `android-ndk-r28c-windows.zip` (713 ميجا) من
`https://dl.google.com/android/repository/android-ndk-r28c-windows.zip` وفكّه في
`android-sdk\ndk\28.2.13676358` مع التأكد أن `source.properties` يحتوي
`Pkg.Revision = 28.2.13676358`.

### 3. Kotlin daemon
كان يفشل الاتصال بـ Kotlin compile daemon. عولج في `android/gradle.properties`:

```properties
kotlin.compiler.execution.strategy=in-process
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G
```

### 4. Gradle بطيء أول مرة
Gradle ينزّل التوزيعة `gradle-9.3.1-all.zip` (224 ميجا) مرة واحدة إلى
`C:\Users\NXTLVL\.gradle\wrapper\dists`. بعدها البناء لا يعيد التنزيل.

## مساحة القرص
NDK وحدها 2.1 جيجا، وFlutter ~2.5 جيجا. راقب المساحة قبل إضافة أي حزم كبيرة.
