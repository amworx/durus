<div dir="rtl">

# دروس (Durus)

تطبيق إدارة **الدروس الخصوصية** لمعلم واحد أو فريق تعليمي صغير: الطلاب،
المواد، الجدول الأسبوعي، الحضور، الأقساط الشهرية (المتغيّرة)، الاختبارات،
الملاحظات، التقارير الشهرية، ومتابعة أولياء الأمور.

- **اللغة:** العربية فقط، مع دعم كامل للكتابة من اليمين إلى اليسار.
- **المنصّات:** تطبيق أندرويد للمعلّم/المدير + واجهة ويب متجاوبة لولي الأمر ولوحة المالك.
- **الوضعان:** معلّم واحد (هو المدير) أو عدة معلّمين — يُحدَّد عند أول تشغيل.

## تحميل التطبيق

من صفحة [الإصدارات](https://github.com/amworx/durus/releases):

- **ملف واحد فقط** لكل إصدار: `durus-<النسخة>-arm64.apk`
- الإصدارات القديمة (حتى `v1.1.18`) تحتوي عدة ملفات — **`arm64` هو الصحيح**،
  والملفان الآخران لأجهزة قديمة جدًا (32-بت) وللمحاكيات على الحاسوب.
- التحديث من داخل التطبيق أسهل: **الإعدادات → التحديثات** ويختار الملف الصحيح تلقائيًا.

## بوابة ولي الأمر

لا يحتاج ولي الأمر إلى إنشاء حساب: يشارك المعلّم **رابطًا/رمزًا** لكل طالب،
ويفتح الرابط في المتصفح مباشرة:

```
https://amworx.github.io/durus/#/portal/<token>
```

## المزايا

- **الطلاب والمواد:** إضافة/تعديل/حذف، ربط الطالب بمواده، الصف، ورقم ولي الأمر.
- **الجدول الأسبوعي والحضور:** حصص ثابتة، تسجيل الحضور، وتبرير الغياب.
- **الأقساط:** مبلغ متغيّر لكل طالب/شهر (سجل مالي)، مع الدفع الجزئي والمتبقّي.
- **الاختبارات والملاحظات:** درجات (شهري/نصفي/نهائي/قصير)، تقارير شهرية.
- **أولياء الأمور:** متابعة تفاعلية عبر الرابط، وأكثر من طفل للمنزل نفسه.
- **عدة معلّمين:** كل معلّم يرى طلابه فقط — الفصل مفروض في قاعدة البيانات (RLS).
- **لوحة المالك:** إحصائيات الاستخدام، صحة المدارس، طلبات الميزات، وسجل الأخطاء.

## التقنيات

| الطبقة | التقنية |
|---|---|
| التطبيق | Flutter 3.44.9 / Dart 3.12.2 |
| الحالة والتوجيه | Riverpod 2 · go_router |
| الترجمات | `flutter_localizations` + `.arb` (عربية فقط) |
| الخلفية | Supabase: Postgres + Auth + RLS + Realtime |
| النشر | GitHub Releases (أندرويد) · GitHub Pages (الويب) |

## البنية

```
durus/
  src/          تطبيق Flutter (pubspec.yaml هنا)
  supabase/     ترحيلات SQL (المخطط + RLS + الدوال)
  docs/         نماذج تصميم وتوثيق
  memory/       سجل الأحداث والدروس والأنماط
  plans/ tasks/ الخطط والمهام
  AGENTS.md     قواعد المشروع للوكلاء
  release.ps1   بناء الإصدار (ملف APK واحد)
```

</div>

---

## Development (English)

Flutter app lives in `src/`; backend is a single Supabase project
(`Postgres + Auth + RLS`). All commands run from `src/` unless noted.

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
flutter build web --release --base-href /durus/
```

Supabase URL and the publishable key are compiled in via
`--dart-define` (`src/lib/core/config.dart` has dev defaults). Credentials and
the release keystore live in `../durus-keys/` — **gitignored, never commit or
log them.**

### Releases — one APK, always

Publish **exactly one** APK per release (arm64). Users cannot tell
`app-arm64-v8a` / `app-armeabi-v7a` / `app-x86_64` apart and pick the wrong
file; the other two only serve pre-2017 32-bit phones and PC emulators, and
they had zero downloads on `v1.1.18`.

```powershell
.\release.ps1 -Version 1.1.19 -Notes "<Arabic release notes>"          # build + verify + stage
.\release.ps1 -Version 1.1.19 -Notes "..." -Upload                     # ...and publish
.\release.ps1 -Version 1.1.18 -VerifyApk <path\to\arm64.apk>           # audit an artifact
```

The script bumps `pubspec.yaml` + `AppConfig.appVersion`, runs the tests, builds
the split APKs, verifies the arm64 one with `aapt2` and stages
`dist/durus-<version>-arm64.apk`.

**versionCode is load-bearing.** The arm64 artifact of a `--split-per-abi`
build carries `versionCode = 2000 + build-number` (so `1.1.18+3` → `2003`).
Android refuses anything lower as a downgrade, so:

- always bump the pubspec build number (`+N`) on every release;
- do **not** switch to a plain `flutter build apk --target-platform android-arm64`
  build — that emits `versionCode = N` (e.g. `4`), which is far below the
  installed `2003`, and users silently cannot update.

Still manual after a release: the `app_meta` migration (curated
`latest_release` row) + `supabase db push`, deploying the web build to
`gh-pages`, and the `memory/events.md` entry.
