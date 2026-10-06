# Localization Audit — Medi HR (Flutter)

> READ-ONLY audit. No code was changed. All findings below are based on actual
> code read during the audit (Nov 2025–Oct 2026 working tree). Where something
> could not be verified, it is marked **[UNVERIFIED]**.
>
> App: `mediconsult_internal` v1.0.7 — internal HR app for hospital staff.
> UI today: **Arabic-only, RTL**.

---

## 1. Executive summary

| Item | Value |
|---|---|
| **Readiness score** | **3 / 10** |
| Total Dart files (`lib/`) | **501** |
| Lines containing Arabic text (`lib/`) | **~2,775 lines in 224 files** (measured with regex `[\u0600-\u06FF]` scan) |
| `Text(` occurrences | **~1,255 in 174 files** |
| Screens (`*screen.dart`) | **64** |
| Features with Arabic strings | **25+** (see §2 table) |
| Existing `.arb` / `l10n.yaml` / generated l10n | **None** |
| Locale switching logic | **None** (`locale:` is hardcoded) |
| Total migration effort (rough) | **~7–10 weeks, 1–2 engineers** (details §10) |

### Top 5 risks

1. **~2,775 hardcoded Arabic lines across 224 files, zero l10n infra.** Every
   string must be touched. There is no `l10n.yaml`, no `.arb`, no
   `AppLocalizations`, no locale cubit/provider. This is a greenfield retrofit,
   not an incremental change.
2. **Backend returns Arabic-only content and the client has no
   `Accept-Language` contract.** API error `title`/`message`, status display
   names, and push-notification titles/bodies flow through untranslated
   (`AppException`, `DioClient`, `PushNotificationService`). `.arb` files alone
   fix only ~60–70% of visible text; the rest needs backend work.
3. **Error handling matches on Arabic substrings.**
   `AppException.isServerUnavailableMessage` does
   `message.contains('تعذر الوصول للسيرفر')` etc.
   (`lib/src/core/utils/app_exception.dart:24-31`). The moment messages become
   English, these checks silently stop matching. This is a correctness bug
   waiting to happen.
4. **RTL is hardcoded in two directions.** 9 explicit
   `TextDirection.rtl/ltr` overrides + 125 non-directional `Alignment.*Left/Right`
   + 19 `EdgeInsets.only(left/right)` + 26 `Positioned(left/right)` + 27
   `BorderRadius.only(topleft/…)` with **zero** `BorderRadiusDirectional`.
   Switching to LTR will visibly break cards, chips, drawers, and the org chart
   (which is pinned `TextDirection.ltr`).
5. **Arabic plural/interpolation logic is hand-rolled everywhere (243 lines).**
   Ternaries like `count == 1 ? "طلبك" : "$count طلبات"`
   (`home_notification_service.dart:60,139,159`) ignore Arabic's
   zero/one/two/few/many/other rules and cannot be mechanically converted —
   each needs an ICU `plural` entry and a translator pass.

---

## 2. Current state

### 2.1 SDK / packages (`pubspec.yaml`)

| Item | State |
|---|---|
| Dart SDK | `^3.9.2` declared; installed **3.12.1** |
| Flutter | installed **3.44.1, channel stable** |
| `flutter_localizations` (SDK) | ✅ present |
| `intl` | ✅ `^0.20.2` |
| `flutter_bloc` | ✅ `^9.1.1` (~109 files reference bloc/cubit) |
| `go_router` | ✅ `^14.0.0` (27 files) |
| `get_it` | ✅ `^9.2.0` (43 files) |
| `shared_preferences` | ✅ `^2.5.4` |
| `flutter_secure_storage` | ✅ `^10.0.0` |
| `easy_localization` / `slang` / any l10n package | ❌ none |
| `l10n.yaml` | ❌ does not exist |
| `*.arb` files | ❌ none found (`find . -name "*.arb"` empty) |
| `lib/l10n`, `*locali*`, `*intl*`, `*l10n*` | ❌ none |

### 2.2 App root (`lib/main.dart:110-121`)

```dart
return MaterialApp.router(
  ...
  locale: const Locale('ar', 'EG'),                        // HARDCODED
  supportedLocales: const [Locale('ar'), Locale('en')],   // 'en' listed but useless
  localizationsDelegates: const [                          // only Flutter SDK delegates
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  routerConfig: AppRouter.router,
```

Findings:

- `locale:` is pinned to `ar_EG`. There is **no** `localeResolutionCallback`,
  no `localeListResolutionCallback`, no `onGenerateTitle`.
- `supportedLocales` lists `en`, but without `AppLocalizations.delegate` this
  only localizes **Material/Cupertino system widgets** (date pickers, etc.) —
  **zero** app strings. Misleading; looks ready, is not.
- No `CupertinoApp` anywhere; single `MaterialApp.router`. Good — one place to
  wire the locale.
- No `Directionality` at root (correct — MaterialApp provides it from `locale`).
  But 5 nested `Directionality(` overrides exist (see §5), which will fight the
  root direction after adding English.

### 2.3 Locale switching / persistence

- **No switching logic exists.** `grep` for `Locale` outside `main.dart` and
  `flutter_localizations` imports finds nothing in routing/auth.
- `StorageKeys.language = 'language'` is **defined but never used**
  (`lib/src/core/constants/storage_keys.dart:26`; only hit for `'language'` in
  `lib/` is the definition). So even the key is aspirational.
- Natural home: `SharedPreferences` (`shared_preferences` is already a dep and
  used for other settings), key `StorageKeys.language`, exposed via a
  `LocaleCubit` (bloc is the dominant state-management choice, 109 files) held
  above `MaterialApp.router`, calling `setLocale` → `MaterialApp.locale`.
  None of this exists yet.

### 2.4 State management & locale propagation

- **Bloc/Cubit dominates** (flutter_bloc 109 files), with `get_it` service
  locator (43 files) and `go_router` (27 files). No Riverpod/GetX/Provider.
- Cleanest propagation path for THIS codebase: a `LocaleCubit`/`SettingsCubit`
  provided above `MainApp`/`MaterialApp.router`; `BlocBuilder` rebuilds
  `MaterialApp` with the new `locale`. Low risk because the whole tree already
  rebuilds on auth changes through the same mechanism.
- `go_router` needs no locale-aware routes today (no localized deep links
  found), but `redirect` logic must not cache localized strings.

---

## 3. Hardcoded strings inventory

Method: full-`lib/` regex scan for `[\u0600-\u06FF]`.
**Result: ~2,775 lines with Arabic text in 224 of 501 files (~45% of files).**

Supporting counts:

| Metric | Count |
|---|---|
| `Text(` occurrences | ~1,255 in 174 files |
| `SnackBar` / `CustomToast.show*` / `Fluttertoast` refs | ~202 |
| `validator` / `hintText` / `labelText` refs | ~101 lines |
| Arabic + `$interpolation` on same line | **243 lines** (ICU work, §3.1) |
| Tooltip / semantics refs | 8 files contain `tooltip`/`semanticsLabel`/`Semantics(` |
| Validators (`TextFormField`/`validator`) | 14 files |

### 3.1 Per-feature breakdown (measured, `lib/src/features`)

| Arabic lines | Files | Feature |
|---:|---:|---|
| 497 | 27 | `admin` (dashboard, payroll, dept requests, employee details) |
| 243 | 18 | `hr` (dashboard, salary calc, employee profile) |
| 220 | 26 | `attendance` |
| 208 | 14 | `tasks` (incl. `task_labels.dart` alone: 70 lines) |
| 165 | 4 | `payslip` (densest per-file: `payslip_screen.dart` **121 lines**) |
| 128 | 6 | `requests` (incl. `create_permission_bottom_sheet.dart`: 53) |
| 127 | 10 | `profile` |
| 115 | 9 | `home` |
| 112 | 10 | `leaves` |
| 110 | 17 | `organization` |
| 101 | 5 | `holidays` |
| 87 | 12 | `missions` |
| 85 | 2 | `employee_history` (`employee_history_screen.dart`: 83) |
| 72 | 8 | `employee_of_month` |
| 69 | 8 | `notifications` |
| 65 | 5 | `overtime` |
| 64 | 7 | `auth` (login/OTP/password) |
| 38 | 3 | `permissions` |
| 37 | 4 | `meetings` |
| 32 | 2 | `reports` |
| 30 | 2 | `penalties` |
| 22 | 2 | `bonuses` |
| 18 | 1 | `device_fingerprint` |
| 2 | 1 | `splash` |
| 1 | 1 | `main` (model-adjacent) |
| — | — | + `lib/src/core`: **84 lines / 10 files**, `lib/src/shared`: **41 / 9**, `lib/main.dart`: **2** |

Highest-density single files (migrate first, they dominate QA):

- `payslip/payslip_screen.dart` — 121
- `employee_history/employee_history_screen.dart` — 83
- `admin/payroll_screen.dart` — 79
- `tasks/utils/task_labels.dart` — 70 (enum-adjacent label maps — high risk, §9)
- `admin/department_requests/department_requests_screen.dart` — 56
- `requests/widgets/create_permission_bottom_sheet.dart` — 53

> Note: counts are **lines containing Arabic**, not ICU messages. One line can
> hold 2–3 strings (`'من $a إلى $b'`), and multi-line `Text('...')` blocks count
> once. Budget ~2,500–3,000 ICU messages after splitting. Exact key count
> requires the extraction pass (Phase 1).

### 3.2 Interpolation / concatenation / plurals (ICU work — 243 lines)

These **cannot** be copy-pasted into `.arb`; each needs placeholders/plurals.
Recurring patterns found:

| Pattern | Example (file:line) |
|---|---|
| Counts + Arabic nouns | `'لديك $pendingCount طلبات معلقة'` (`home_notification_service.dart:49`) |
| Hand-rolled singular/plural ternary | `pendingCount == 1 ? "طلب معلق" : "طلبات معلقة"` (`:60`); same shape at `:139`, `:159` for approve/reject |
| Durations | `'$hours ساعة و $minutes دقيقة'` (`employee_dashboard_sections.dart:17`, `permission_request.dart`, `attendance_formatters.dart:40-42`, `punch_pair_model.dart:131-133`) |
| Ranges | `'من ${item.startDate} إلى ${item.endDate}'` (`recent_activity.dart:295,397,401`); `'${_formatNumber(x)} ساعة'` (payslip ×12) |
| Currency suffix concat | `'${_currencyFormat.format(amount)} ج.م'` (`app_formatters.dart:21`) — must become `{amount} {currency}` placeholder, not baked suffix |
| Dates in sentences | `'إصدار ${DateFormat(...).format(...)}'` (`payslip_screen.dart:655`); `'تاريخ التعيين: ...'` (`:140`) |
| Status-code in message | `'حدث خطأ غير متوقع (رمز: $statusCode).'` (`app_exception.dart:138`) |
| Ternary inside notification | `'تم الموافقة على ${count == 1 ? "طلبك" : "$count طلبات"}'` (`:139`) |

Arabic plural rules (zero/one/two/few/many/other) mean a translator must review
every count string — e.g. `2 طلبات` is wrong Arabic (should be `طلبان/طلبين`).
`intl`/`gen-l10n` supports ICU `plural`; `slang` also does. Budget reviewer time.

### 3.3 Backend-driven strings (NOT solvable by `.arb` alone)

| Source | Evidence | What backend must do |
|---|---|---|
| API error `title`/`message` passthrough | `AppException._fromDio` + repository catch blocks surface `data['title'] ?? data['message']` verbatim (e.g. `permission_repository.dart`, `overtime_repository.dart`); `DioClient` sends only `Accept: application/json` + `Authorization`, **no `Accept-Language`** (`dio_client.dart:27-30,79`) | Send `Accept-Language: ar|en` on every request; return `{code, messageAr, messageEn}` or localized by header; document fallback when header absent |
| Status display names | Client maps `approved/rejected/pending` itself today, but `rejectionReason`, `where`, `reason` free-text and HR remarks render verbatim in cards (`unified_request_card.dart`, dept cards, `admin_home_screen.dart`) | Free text stays as-is (user-generated); **enum/status labels must be client-mapped**, never trusted from server |
| Notification titles/bodies | `PushNotificationService` renders `notification.title/body ?? data['title']/['body']` verbatim (`push_notification_service.dart:216-222,280-296`); in-app `home_notification_service.dart` builds Arabic titles client-side (`:49-:159`) | FCM payloads need `titleAr/titleEn/bodyAr/bodyEn` (or `*_loc_key` + args); client picks by locale; data-only messages must carry a message code, not pre-rendered Arabic |
| Cached/persisted text | `hrEmployeesList`, `userProfile`, attendance caches in SharedPreferences; notification history | Cache **codes/IDs**, never rendered strings; or version cache by locale and rebuild on switch |
| `AppException` Arabic matching (§1 risk 3) | `app_exception.dart:24-31,138` | Refactor to typed error codes first; string matching must die before l10n |

---

## 4. Formatting & locale-sensitive logic

### 4.1 Dates & times — fragmented, half-migrated

- `DateFormat(` appears **24× in 13 files**, mostly hardcoded `'dd/MM/yyyy'`
  (e.g. `payslip_screen.dart:655`). No locale is passed to `DateFormat`, so
  today everything renders Latin digits in `dd/MM/yyyy` order regardless of
  device locale.
- Central helper `AppDateUtils` (`lib/src/core/utils/date_utils.dart`) exists
  but is **not used everywhere**: parallel formatters live in
  `attendance/utils/attendance_formatters.dart` (own `kArDays`, `kArMonths`,
  own `formatDate/formatTime`), `TodayAttendance` getters, `PunchPairModel`,
  `department_requests_response.dart:139,149`, meetings cubit, etc.
- **AM/PM is currently inconsistent** (flagging honestly — the tree shows a
  mid-migration state):
  - `AppDateUtils.formatTime12h` emits English **`AM`/`PM`**
    (`date_utils.dart`, verified at audit time).
  - `TimePickerHelper.formatTime12Hour` emits **`صباحاً`/`مساءً`**
    (`time_picker_helper.dart:82-85`).
  - `attendance_formatters.formatTime` is still **24h**.
  - Pick ONE (recommend `صباحاً`/`مساءً` for ar, `AM`/`PM` for en via `.arb`,
    not hardcoded) and route all three through it.
- `parseFlexible` in `date_utils.dart` accepts ISO, epoch, .NET `/Date()/`,
  `dd/MM/yyyy`, `MM/dd/yyyy`, Arabic-Indic digits — good, keep locale-independent.
  Display (`formatDate`) and parsing are correctly separated; do not merge them.

### 4.2 Numbers / currency / percent / durations

- Currency: `AppFormatters._currencyFormat = NumberFormat('#,##0.##', 'en_US')`
  + hardcoded suffix `ج.م` (`app_formatters.dart:14-22`). `currency` referenced
  **78× in 10 files** (payslip, bonuses, penalties, requests). For `en` this
  must become `EGP 4,500` / `$`-style via `NumberFormat.simpleCurrency(locale:)`,
  with the currency token as an ICU placeholder — **not** string concat.
- `NumberFormat` otherwise appears **2× in 1 file** — number formatting is
  essentially un-localized today.
- Digits: UI uses **Western digits** everywhere; Arabic-Indic digits are only
  *accepted on input* (`date_utils._normalizeDigits`). No Hijri anywhere
  (grep `Hijri|هجري` = 0). Gregorian only — fine, keep it; just decide digit
  shaping per locale (`ar-EG` traditionally uses ٠١٢٣٤٥٦٧٨٩; current app does
  not — confirm with design whether `en` keeps `123` and `ar` stays `123`).
- Durations: at least **5 hand-rolled** Arabic duration builders
  (`attendance_formatters.dart:40-42`, `punch_summary_model.dart:31-33`,
  `punch_pair_model.dart:131-133`, `employee_dashboard_sections.dart:17-21`,
  `permission_request.dart` duration). Each needs ICU plural treatment.

### 4.3 Logic depending on Arabic text (fragile — must refactor pre-l10n)

- `AppException.isServerUnavailableMessage` — substring match on 4 Arabic
  phrases. **Will break on first English error.** Replace with error codes.
- Status mapping via `status.toLowerCase() == 'pending'/'approved'/…` is safe
  (compares API codes, not Arabic) — keep that pattern; forbid comparing
  *display* strings.
- `sort/compareTo/toLowerCase` appears in **174 spots / 66 files**, mostly
  sorting records by date/number (safe). Any name search/sort over
  `employeeNameAr` must be checked per screen during migration (Arabic
  collation ≠ code-unit order), but no per-screen collation audit was done here
  — flagged as Phase-2 QA item.
- `getArDayName`, `kArDays`, `kArMonths` — parallel Arabic calendar vocabulary
  that duplicates `DateFormat('EEEE', 'ar')`. Delete after l10n and use
  `DateFormat` with locale.

### 4.4 Timezone safety (attendance / night shift)

- `.toLocal()/.toUtc()/timezone/TZDateTime` appears **16× in 6 files**; display
  helpers consistently `.toLocal()` before formatting — correct pattern.
- `test/core/time/server_clock_test.dart` exists — server-clock handling is
  tested; locale change does not affect instants, only rendering.
- **Verdict:** calculations are timezone-aware and locale-independent as far as
  read. No `DateFormat` without explicit pattern drives logic (only display).
  **[UNVERIFIED]** night-shift spanning-midnight math was not line-audited
  (files identified: `attendance_shift_resolver_test.dart`, attendance
  repository/cubit) — include a regression run in Phase 5.

---

## 5. RTL / LTR readiness — NOT ready

Measured totals (`lib/`, 501 files):

| Pattern | Count | Files | Action |
|---|---|---|---|
| `EdgeInsets.only(left/right)` | **19** | 15 | → `EdgeInsetsDirectional.only(start/end)` |
| `Alignment.centerLeft/Right…` (non-directional) | **125** | 48 | → `AlignmentDirectional` (only 4 uses today) |
| `Positioned(left/right)` | **26** | 19 | → `PositionedDirectional` |
| `TextAlign.left/right` | **0** | 0 | ✅ already clean (`start/end/center`: 75 uses) |
| `BorderRadius.only(topLeft/…)` | **27** | 20 | → `BorderRadiusDirectional` (**0 uses today**) |
| `EdgeInsetsDirectional` | 6 | 6 | ✅ pattern exists, expand it |
| `Directionality(` overrides | 5 | 5 | 4× forced `rtl`, org-chart forced `ltr`, OTP forced `ltr` — each must be re-evaluated for `en` |
| `TextDirection.rtl/ltr` literals | 9 | 9 | same as above |
| Directional arrow/chevron icons | **67** | 57 | triage mirror vs non-mirror (below) |
| `Drawer`/`endDrawer` | 6 | 2 | `Drawer` = start side; verify each screen in LTR |

Details & examples:

- `EdgeInsets.only(left/right)` sample files: `sa_attendance_filter_bar.dart`,
  `otp_screen.dart`, `create_permission_bottom_sheet.dart`,
  `employee_card.dart`, `bonuses_screen.dart`, `mission_*_section.dart`,
  `task_chips.dart`, `status_tabs_bar.dart`, `help_support_screen.dart`,
  `unified_request_card.dart` (!! — the shared card), `penalties_screen.dart`.
- `margin/padding …left/right` literal matches: ~30 more in 26 files (some are
  the same sites; dedupe during fix pass).
- Forced direction blocks:
  - `organization_chart_widget.dart:248-249` — `Directionality(ltr)` around the
    whole chart. Probably intentional (graph layout), but labels inside will
    need per-locale text while layout stays LTR — explicit decision needed.
  - `otp_screen.dart:378-379` — `Directionality(ltr)` for PIN boxes. Correct to
    keep LTR in both locales (digits entry), verify backspace/focus order.
  - `network_connectivity_banner.dart:65-70`, `task_filters_sheet.dart:46-47`,
    `searchable_dropdown_field.dart:130-131`, `holiday_form_dialog.dart:121`,
    `admin_requests_screen.dart:507`, `edit_profile_screen.dart:406` — forced
    `rtl`. Each becomes `Directionality(textDirection: Directionality.of(context))`
    or deleted after migration.
- Icons — mirror (use `Directionality`-aware or `matchTextDirection: true`):
  back arrows, forward chevrons, "go to details" arrows, progress/stepper
  direction, swipe hints, `openDrawer` affordances
  (`organization_chart_screen.dart:88,122`). Do NOT mirror: logos, clock,
  calendar, biometric/location/camera glyphs, download/upload (vertical),
  brand art (`whatsapp.png` **[UNVERIFIED]** intent).
- Layout fragility: `unified_request_card.dart` (used by leaves/permissions/
  missions/requests/admin lists) has fixed 44px icon wells, `maxLines: 1` +
  ellipsis titles, and a 4-side `BorderRadius.only` inner container — English
  strings (often 30–60% longer than Arabic, e.g. `الإذونات` → `Permissions`)
  will overflow exactly here first. Golden/layout QA must start with this card.
  `TabBarView` order (`missions_screen.dart:131`, `leaves_screen.dart:221`,
  `permissions_screen.dart:152`, …) auto-mirrors under RTL — verify tab order
  expectations in English.

---

## 6. Fonts & typography

- **Single family: `IBMPlexSansArabic`** (400/500/600/700,
  `pubspec.yaml` fonts section; applied globally in
  `app_theme.dart:24` as `fontFamily`). No Latin companion family declared.
- IBM Plex Sans Arabic does ship Latin glyphs, so English will render — but
  weight/width rhythm differs from Plex Sans Latin, and there is no per-locale
  `ThemeData.fontFamily` switch. Recommend: keep Plex Arabic for `ar`, add
  `IBMPlexSans` (or system fallback) for `en`/others, selected via
  `ThemeData` per locale (or `fontFamilyFallback`).
- Sizes/line-heights are tuned for Arabic script (taller glyphs, diacritics).
  English at the same sizes looks smaller/looser — plan a typography QA pass,
  not a blind 1:1 reuse. No per-locale text-scale logic exists today.
- **[UNVERIFIED]** whether `assets/fonts/` contains hinting/kerning issues for
  Latin at small sizes — render check in Phase 3.

---

## 7. Assets & non-code content

| Area | Finding |
|---|---|
| Images with text | `assets/images/`: `Khusm Logo.png`, `lLogo.png`, `whatsapp.png`. **[UNVERIFIED]** whether any embeds Arabic text (filenames suggest logos/social icon — likely safe, but visually confirm). No localized asset variants exist. |
| Splash / onboarding | No localized splash assets found; native splash uses default Flutter drawable. If onboarding screens are added later, they need per-locale assets. |
| PDFs (payslips) | Payslip renders in-app (`payslip_screen.dart`); no PDF template found in `lib/` or `assets/`. If server generates PDF payslips, that pipeline needs its own locale param — **ask backend** (§11 Q3). |
| Emails | None client-side. |
| Push templates | Client renders server payload verbatim (§3.3). Needs `titleAr/titleEn/bodyAr/bodyEn` or loc-key contract. |
| `AndroidManifest.xml` | `android:label="Medi HR"` (neutral ✅); `configChanges` already includes `locale\|layoutDirection` (line 29) so rotation/locale change won't-KILL the activity — good. No per-locale `values-ar/strings.xml` for native strings **[UNVERIFIED — `android/app/src/main/res` not inspected at file level]**. |
| `Info.plist` | `CFBundleDisplayName = "Medi HR"` (neutral ✅); **permission strings are Arabic-only**: `NSFaceIDUsageDescription` (`نحتاج Face ID…`), `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationWhenInUseUsageDescription`. Need `InfoPlist.strings` (`ar`/`en`) + `CFBundleLocalizations`. Android permission rationale strings (if any custom) need the same treatment. |
| Firebase | `firebase_core` + `firebase_messaging` + `flutter_local_notifications`. Titles/bodies are server-produced; FCM needs locale awareness (see §3.3). Topic subscriptions per language (e.g. `news_ar`/`news_en`) **[UNVERIFIED — no topic code found in the lines read]**. |

---

## 8. Testing & CI impact

- Tests: **17 files**, all unit/widget logic tests, **0 golden files**.
  - `unified_request_card_test.dart` — asserts on rendered times (`08:17`) and
    midnight hiding; already broke once during the AM/PM change. Every widget
    test asserting Arabic text or `findsOneWidget` on time strings will need a
    locale-parameterized variant.
  - `recent_activity_mapping_test.dart` — asserts Arabic titles
    (`'تأخير صباحي'`) — must become locale-parameterized.
  - `notification_date_test.dart`, `push_notification_delivery_test.dart`,
    `payslip_period_test.dart`, server-clock/shift-resolver tests — safe unless
    they assert rendered strings (spot-check in Phase 0).
- Goldens: none exist, so nothing breaks — but this is also the gap: add
  RTL+LTR golden variants for at minimum `UnifiedRequestCard`, auth screens,
  and the admin request card **before** flipping any layout code.
- CI: **no `.github/workflows`, `codemagic.yaml`, or `fastlane/` found.**
  Whatever runs tests today needs: `flutter gen-l10n` (or equivalent) before
  `analyze/test`, plus a "missing-translation" gate (gen-l10n fails on missing
  keys only with strict config; `slang` validates out of the box).

---

## 9. Approach recommendation

### Recommendation for THIS codebase: **Flutter official `gen-l10n` (.arb + `intl`)**

Reasons specific to what was read:

1. **Zero new dependencies, zero new build magic.** `flutter_localizations` +
   `intl` are already in `pubspec.yaml`; `gen-l10n` ships with the SDK
   (installed 3.44.1). `easy_localization` would add a loader + asset pipeline
   and a second source of truth; `slang` is excellent but adds codegen +
   team learning curve for marginal gain here.
2. **Bloc-centric app.** `gen-l10n`'s `AppLocalizations.of(context)` fits the
   existing `BuildContext`-heavy widget tree with no architecture change; a
   `LocaleCubit` rebuilds `MaterialApp` exactly like auth state already does.
3. **ICU plural/gender/placeholders are first-class** (`{count, plural,
   =0{…} =1{…} =2{…} few{…} many{…} other{…}}`), which the 243 interpolation
   lines and Arabic's 6 plural categories demand. `easy_localization` plural
   support is thinner for Arabic.
4. **Tooling/CI story is standard**: `flutter gen-l10n`, missing-key errors,
   per-locale `.arb` deltas translators already understand.

Use `slang` only if the team later wants type-safe string access and JSON
workflows — not worth it for v1.

### Proposed structure

```text
lib/l10n/
  app_ar.arb            # template (source of truth = Arabic, current UX unchanged)
  app_en.arb
l10n.yaml               # arb-dir, template-arb-file, output-localization-file,
                        # preferred-supported-locales: [ar, en], use-deferred-loading: false
lib/src/core/locale/
  locale_cubit.dart     # LocaleCubit + LocaleState, persists via SharedPreferences
  app_locale.dart       # helpers: isArabic, displayName, date/number locale tag
```

`main.dart` wiring: `LocaleCubit` above `MaterialApp.router` →
`BlocBuilder` sets `locale: state.locale`, adds
`AppLocalizations.delegate` FIRST in `localizationsDelegates`,
`localeResolutionCallback` falls back to `ar`.

### Conventions

- **Keys:** `snake_case`, `<feature>_<screen>_<element>_<role>` —
  e.g. `leaves_list_empty_title`, `permissions_card_created_at_label`,
  `common_action_approve`, `auth_login_password_hint`, `errors_network_retry`.
  Shared keys live under `common_*`.
- **Placeholders:** named, typed —
  `"{count, plural, =0{لا توجد طلبات} =1{طلب واحد} =2{طلبان} few{# طلبات} many{# طلبًا} other{# طلب}}"`; dates/amounts passed as **typed args**
  (`{date, date, medium}`, `{amount, number}`), never pre-formatted strings.
- **Gender:** avoid where possible (use neutral phrasing); where unavoidable
  (`employeeNameAr` contexts), ICU `select`.
- **Periods:** never hardcode `صباحاً/AM` — locale's day-period via
  `DateFormat.jm(locale)` or `.arb` dayPeriod strings.
- **Persistence:** `SharedPreferences['language']` (`StorageKeys.language`
  already reserved) storing `ar`/`en`; default = device locale if
  `ar`/`en`, else `ar` (fallback = current UX). Switching = cubit event →
  rebuild; no restart required (manifest `configChanges` already safe).
- **Backend strings:** client maps codes→`.arb` keys; free text passes through;
  errors become `AppError(code, args)` instead of `AppException(message)`.

---

## 10. Risks & edge cases

1. `AppException` Arabic substring matching (§1.3) — refactor to codes BEFORE
   any `.arb` work; every `contains('…')` is a landmine.
2. Strings inside models/enums/constants: `PermissionKind` labels, `TaskLabels`
   (70 Arabic lines of label maps), `attendance_formatters` day/month arrays,
   `OvertimeRequest.timeRangeText`, `RecentActivity` titles — these need
   `BuildContext`/delegate access; pure-model getters can't call
   `AppLocalizations.of`. Pattern: move to extension-on-`BuildContext` or
   pass labels in from widgets.
3. Cached rendered text (`hrEmployeesList`, `userProfile`, attendance caches,
   notification history) goes stale on mid-session switch — either re-fetch or
   store codes only.
4. Mid-session switch with pending forms/validators: `TextFormField.validator`
   closures capture old strings; rebuild handles it if validators read
   `AppLocalizations.of(context)` at call time (not cached in state).
5. `go_router` route-level builders caching widgets across locale change —
   ensure no `const` subtree freezes a localized string (audit `const Text(`).
6. FCM data-only messages arriving in background isolate have no `BuildContext`
   — localize at *display* time with stored locale, or ship both languages.
7. Deep links carrying display text (none found, but enforce: IDs only).
8. Search/filter over Arabic names (`organization` search bar, 17 files) —
   normalization (alef/hamza, teh-marbuta, diacritics) differs per locale;
   keep search locale-agnostic (normalize both sides).
9. `TabBarView`/stepper/page order auto-mirrors in LTR — product must confirm
   whether tab order should mirror or stay fixed.
10. Translators will mistranslate ICU syntax (`{`, `#`, `plural`) — enforce
    `gen-l10n` strict validation in CI and keep `app_ar.arb` as the guarded
    template.
11. Third-party native sheets (file_picker, image_picker, permission_handler,
    local_auth biometrics): system UI follows device locale, not app locale —
    acceptable, but document it (app locale ≠ system dialogs).
12. `sms_autofill`, `fluttertoast` messages, Sentry breadcrumbs — audit each for
    locale assumptions in Phase 0.

---

## 11. Effort estimate & migration plan

Basis: ~2,775 Arabic lines / 224 files / 64 screens / ~1,255 `Text(` sites /
243 ICU lines / ~240 directional-code sites / 17 test files.

| Phase | Content | Effort* | Deps / parallelizable |
|---|---|---|---|
| **0 — Setup + infra** | `l10n.yaml`, `lib/l10n/app_ar.arb` scaffold, `LocaleCubit` + persistence, `main.dart` wiring (delegate, resolution, fallback), CI `gen-l10n` + missing-key gate, error-code refactor of `AppException` matching | **5–8 days** | First; unblocks all. Error-code refactor can parallelize with scaffold |
| **1 — Shared/common** | `core` (84 lines/10 files: `app_exception`, `app_formatters`, `date_utils`), `shared` widgets (41/9), `UnifiedRequestCard` + `RecentActivity`, toasts/snackbars/validators/empty-states | **5–7 days** | After 0. Highest leverage — one card serves 4+ screens |
| **2 — Feature-by-feature** | 25 features in density order: payslip → admin → hr → attendance → tasks → requests/profile/home/leaves/org → … → splash | **15–25 days** (1–2 days/feature cluster; translators async) | After 0+1; parallelizable per feature across engineers |
| **3 — RTL→LTR fixes** | ~240 directional sites (EdgeInsets 19, Alignment 125, Positioned 26, BorderRadius 27), 67 icon triage, forced-`Directionality` removal, `UnifiedRequestCard` + tab-order + drawer QA, EN goldens | **8–12 days** | After 1 (needs real EN strings to judge overflow); parallel with late Phase 2 |
| **4 — Native + push + backend contract** | `InfoPlist.strings` ar/en, Android `values-*/strings.xml` audit, `Accept-Language` interceptor, FCM dual-language payloads, payslip-PDF question, error-code backend map | **5–8 days** + backend team time | Needs backend answers (§12); client + native parallelizable |
| **5 — QA & rollout** | locale-matrix tests (17 files updated + EN variants), RTL+LTR goldens, night-shift/timezone regression, beta EN cohort, staged rollout | **5–8 days** | Last |

\* Single-engineer days, assuming translators deliver `.arb` deltas async.
**Total ≈ 43–68 eng-days ≈ 7–10 weeks @ 1–2 engineers.**

### Branch / PR strategy (no broken Arabic at any point)

- `feat/l10n-infra` (Phase 0) → merge first; zero UI change (Arabic output
  byte-identical — enforce with goldens on `UnifiedRequestCard`).
- One PR per feature cluster (`feat/l10n-payslip`, `…-admin`, …), each:
  Arabic-only behavioral no-op + EN `.arb` keys added; CI fails on missing keys.
- `feat/ltr-fixes` stacked after; `feat/l10n-native-push` last.
- Feature-flag the language *switcher UI* (not the infra) so `en` ships to
  internal testers before public toggle.

### Top 10 highest-risk files/screens

1. `lib/src/features/requests/widgets/unified_request_card.dart` — shared card,
   `EdgeInsets.only`, fixed widths, `BorderRadius.only`; every EN overflow lands here
2. `lib/src/core/utils/app_exception.dart` — Arabic substring matching; refactor before all
3. `lib/src/features/payslip/payslip_screen.dart` — 121 AR lines, currency+dates in sentences
4. `lib/src/features/tasks/utils/task_labels.dart` — 70 AR lines in label maps (model-layer strings)
5. `lib/src/features/home/services/home_notification_service.dart` — hand-rolled plurals ×4
6. `lib/src/core/utils/date_utils.dart` — AM/PM vs صباحاً split-brain; single choke point, get it right once
7. `lib/src/features/organization/widgets/organization_chart_widget.dart` — forced LTR graph + drawer
8. `lib/src/features/auth/otp_screen.dart` — forced LTR PIN + localized hints/errors
9. `lib/main.dart` — the one wiring point; a mistake here breaks both locales
10. `lib/src/core/services/push_notification_service.dart` + `dio_client.dart` — server-text passthrough + missing `Accept-Language`

---

## 12. Open questions (need answers, esp. backend)

1. **Backend locale contract:** will the API honor `Accept-Language`, or ship
   `messageAr/messageEn` (or `*_loc_key`) fields? Who owns translation of
   server strings, and what is the fallback when a language is missing?
2. **Status/reason vocabulary:** is there a closed enum of server statuses, or
   can new Arabic status strings appear at runtime? (Determines code-map vs
   passthrough design.)
3. **Payslip PDFs / emails:** does any server job generate Arabic PDFs or
   emails? If yes, what locale param does it take, and who translates the template?
4. **Push:** FCM payload format change (dual-language vs loc-keys) — approved?
   Topics per language? What renders a notification received while the app
   killed and locale is `en`?
5. **Digits & dates policy:** `ar` keeps Western digits + `dd/MM/yyyy` (current
   behavior) or moves to ٠١٢٣٤٥٦٧٨٩? Does `en` use `MM/dd/yyyy`? (Affects
   `DateFormat` patterns per locale and QA expectations.)
6. **Day-period policy:** confirm `صباحاً/مساءً` (ar) + `AM/PM` (en) and kill
   the current mixed state (§4.1)?
7. **Scope of v1:** Arabic + English only? Which screens are must-have in EN for
   launch (all 64, or employee-facing subset first)?
8. **Org-chart direction:** keep graph LTR in both locales with translated
   labels, or mirror?
9. **Cached data:** acceptable to re-fetch on language switch, or must cached
   screens switch instantly offline?

---

*End of audit. All counts measured on the working tree at audit time with
full-`lib/` scans (not samples). Numbers will drift as the tree changes —
re-run the scan commands in §3–§5 before committing to dates.*
