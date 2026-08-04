# Home Dashboard Redesign Spec

هذا الملف يحدد تصورًا عمليًا لإعادة تصميم شاشات:

- `Employee Home`
- `HR Home`
- `Admin Home`
- `Super Admin Home`

الهدف ليس فقط تحسين الشكل، لكن أيضًا جعل كل شاشة تعكس دور المستخدم بوضوح وتعرض أهم المعلومات بأولوية صحيحة.

## 1. المشكلة الحالية

الوضع الحالي جيد من ناحية الفصل البرمجي بين الأدوار، لكن بصريًا ما زالت عدة شاشات تعتمد على نفس البلوكات الأساسية، خصوصًا:

- `QuickActionsSection`
- `StatisticsSection`
- `RecentActivitySection`
- `UpcomingLeaveSection`

هذا ظاهر بشكل مباشر في:

- `lib/src/features/home/home_screen.dart`
- `lib/src/features/hr/hr_home_screen.dart`
- `lib/src/features/admin/admin_home_screen.dart`

النتيجة:

- الشاشات متشابهة أكثر من اللازم.
- الإحساس الإداري ضعيف في `HR` و`Admin`.
- لا يوجد تدرج بصري قوي بين "معلومة مهمة جدًا" و"معلومة ثانوية".
- الصفحة تبدو كأنها مجموعة كروت مرصوصة بدل Dashboard مقصودة.

## 2. مبادئ التصميم الجديدة

كل Dashboard يجب أن يتبع نفس الإطار العام، لكن بمحتوى وشخصية مختلفة:

1. `Hero Section`
يعرض أهم معلومة أو حالة حالية للمستخدم.

2. `KPI Row`
يعرض أرقام سريعة مختصرة ومباشرة.

3. `Action Center`
يعرض أكثر الأفعال استخدامًا.

4. `Attention / Queue`
يعرض ما يحتاج تدخل سريع.

5. `Live Feed`
يعرض الأنشطة أو التحديثات الأخيرة.

## 3. لغة التصميم المقترحة

### الألوان

الألوان الحالية في `lib/src/core/theme/app_colors.dart` مناسبة كبداية جدًا، لكن يفضّل استخدامها بشكل أكثر وضوحًا:

- `primary`: للهوية الرئيسية والعناوين المهمة
- `primaryLight` و`primaryTint`: لخلفيات الـ hero cards والـ badges
- `success`, `warning`, `error`: للحالات فقط وليس للزينة

اقتراح عملي:

- `Employee`: أزرق + أبيض + لمسات خضراء للحضور
- `HR`: أزرق + slate + amber للتعامل مع الحالات المعلقة
- `Admin`: أزرق غامق + أبيض + درجات محايدة أكثر رسمية
- `Super Admin`: أزرق غامق + بطاقات richer + مؤشرات ملونة حسب مستوى الخطر

### المسافات والزوايا

استخدم القيم الموجودة في:

- `lib/src/core/theme/app_spacing.dart`

لكن مع تفعيل أوضح:

- padding أساسي للشاشة: `24`
- spacing بين sections: `24`
- hero card radius: `20`
- stat card radius: `16`

### النصوص

ملف:

- `lib/src/core/theme/app_text_styles.dart`

يحتوي styles جيدة، لكن يفضّل الالتزام بهذا التدرج:

- عنوان الشاشة: `headlineMedium`
- عنوان القسم: `titleLarge`
- رقم KPI: `headlineSmall`
- وصف مختصر: `bodyMedium`
- badge / label: `labelMedium`

## 4. Employee Home

### الهدف

مساعدة الموظف على فهم "حالته اليوم" وإنجاز المهام اليومية بسرعة.

### الهيكل المقترح

1. `Hero Attendance Card`
- الترحيب باسم الموظف
- حالة اليوم: `Checked in / Checked out / Not checked in`
- وقت الحضور والانصراف
- مؤشر المسافة من المكتب
- زر رئيسي واضح: `تسجيل حضور` أو `تسجيل انصراف`

2. `Quick Actions Grid`
- طلب إجازة
- إذن خروج
- المأموريات
- الهيكل التنظيمي

بدل layout خطي، يفضّل grid من 2x2.

3. `Mini KPI Row`
- عدد أيام الحضور هذا الشهر
- الطلبات المعلقة
- ساعات العمل

4. `Upcoming Item`
- الإجازة أو العطلة القادمة

5. `Recent Requests Timeline`
- آخر 3 طلبات مع status pill واضح

### تحسين بصري مهم

بدل فصل `DistanceIndicatorWidget` و`TodayAttendanceCard` و`QuickActionsSection` كعناصر منفصلة، الأفضل دمج أول عنصرين داخل hero واحد كبير أعلى الصفحة.

### ملفات مرشحة للتنفيذ

- `lib/src/features/home/home_screen.dart`
- `lib/src/features/home/widgets/header_section.dart`
- `lib/src/features/home/widgets/today_attendance_card.dart`
- `lib/src/features/home/widgets/distance_indicator_widget.dart`
- `lib/src/features/home/widgets/quick_actions_section.dart`

## 5. HR Home

### الهدف

شاشة تشغيل يومي للموارد البشرية، تركيزها على الأشخاص والحالات التي تحتاج متابعة.

### المشكلة الحالية

`HR Home` أقرب حاليًا إلى `Employee Home` مع إضافات بسيطة، وهذا لا يعكس دور HR الحقيقي.

### الهيكل المقترح

1. `HR Hero Summary`
- عدد الموظفين النشطين اليوم
- عدد الغائبين
- عدد الطلبات المعلقة
- عدد الموظفين الجدد أو pending registrations

2. `Attention Queue`
- موظفون يحتاجون استكمال بيانات
- طلبات تتطلب قرارًا
- حالات تأخير اليوم
- clearance أو مشاكل أمنية

3. `People Snapshot`
- كروت صغيرة حسب الفئة:
  - `On Time`
  - `Late`
  - `On Leave`
  - `Pending Approval`

4. `Primary Actions`
- إدارة الموظفين
- التعيينات / assignments
- الحضور والانصراف
- الهيكل التنظيمي

5. `HR Activity Feed`
- بدل recent activity العامة، تكون feed موجهة: `من قدم طلبًا؟ من تأخر؟ من تمت إضافته؟`

### تحسين بصري مهم

يجب أن تظهر الشاشة وكأنها "مركز متابعة" وليس home شخصية.

اقتراح واجهة:

- Hero بعرض كامل
- تحته صف KPI cards
- ثم section بعنوان واضح: `تحتاج متابعة الآن`

### Widgets مقترحة جديدة

- `hr_dashboard_hero.dart`
- `hr_kpi_row.dart`
- `hr_attention_queue.dart`
- `hr_people_snapshot.dart`

### ملفات مرشحة للتنفيذ

- `lib/src/features/hr/hr_home_screen.dart`
- `lib/src/features/hr/widgets/hr_header_section.dart`

## 6. Admin Home

### الهدف

مساعدة المدير على اتخاذ قرارات سريعة داخل القسم ومتابعة صحة الفريق.

### المشكلة الحالية

الشاشة تمزج بين منطق إداري فعلي وبين widgets عامة، فالشكل لا يعطي ثقلًا كافيًا لدور المدير.

### الهيكل المقترح

1. `Department Hero`
- اسم القسم
- عدد الطلبات المعلقة
- نسبة الالتزام اليوم
- مختصر سريع عن الفريق

2. `Pending Approvals`
- أهم 3 إلى 5 طلبات تحتاج قرارًا الآن
- أزرار `قبول / رفض / مراجعة`

3. `Department Health`
- attendance rate
- open requests
- workload indicator

4. `Team Snapshot`
- الموظفون الموجودون
- المتأخرون
- الغائبون

5. `Admin Shortcuts`
- التقارير
- الطلبات
- الهيكل التنظيمي
- المأموريات

6. `Recent Activity`
- مختصرة جدًا وبعد الأقسام الأهم

### تحسين بصري مهم

بدل إظهار قوائم عادية مباشرة، اعرض summary cards قبل lists حتى يشعر المستخدم أنه في dashboard وليس صفحة إدارة تقليدية.

### Widgets مقترحة جديدة

- `admin_department_hero.dart`
- `admin_pending_approvals_section.dart`
- `admin_health_overview.dart`
- `admin_team_snapshot.dart`

### ملفات مرشحة للتنفيذ

- `lib/src/features/admin/admin_home_screen.dart`
- `lib/src/features/admin/widgets/admin_header_section.dart`
- `lib/src/features/admin/widgets/admin_department_users_list.dart`
- `lib/src/features/admin/widgets/admin_department_requests_list.dart`

## 7. Super Admin Home

### الهدف

شاشة قيادة عليا تعطي نظرة شاملة على النظام كله، وتظهر أين المشكلة قبل الدخول في التفاصيل.

### المشكلة الحالية

`SuperAdminHomeScreen` بسيط جدًا حاليًا: header ثم departments list فقط. هذا جيد كبداية تقنية لكنه ضعيف بصريًا ووظيفيًا.

### الهيكل المقترح

1. `Global Executive Hero`
- إجمالي الموظفين
- الطلبات المفتوحة
- نسبة الالتزام العامة
- عدد الأقسام النشطة

2. `System Alerts`
- أقسام بها تأخير مرتفع
- طلبات متراكمة
- خلل في بيانات أو approvals

3. `Performance Overview`
- cards أو chart صغيرة:
  - أعلى قسم أداءً
  - أقل قسم أداءً
  - أكثر قسم عليه ضغط

4. `Departments Grid`
- كل قسم في card منفصلة
- يظهر فيها:
  - اسم القسم
  - عدد الموظفين
  - pending count
  - status badge

5. `Quick Access`
- الموظفون
- الطلبات
- الإحصائيات
- الإعدادات

### تحسين بصري مهم

`Super Admin` يجب أن يكون له أكبر تباين بصري:

- hero أقوى
- grid أوضح
- مؤشرات حالة richer
- أقل اعتماد على lists الطويلة

### Widgets مقترحة جديدة

- `super_admin_executive_hero.dart`
- `super_admin_alerts_section.dart`
- `super_admin_performance_strip.dart`
- `super_admin_departments_grid.dart`

### ملفات مرشحة للتنفيذ

- `lib/src/features/admin/super_admin_home_screen.dart`
- `lib/src/features/admin/widgets/admin_header.dart`
- `lib/src/features/admin/widgets/super_admin_departments_list.dart`

## 8. اقتراحات UX مشتركة

### أولوية المعلومات

في كل شاشة:

- أهم شيء يظهر فوق
- أقل شيء أهمية ينزل تحت
- أي عنصر يحتاج action يظهر قبل analytics

### الـ badges

استخدم badges صغيرة واضحة:

- `معلق`
- `مقبول`
- `مرفوض`
- `متأخر`
- `نشط`

### Empty States

بدل الفراغ أو القوائم الفارغة:

- رسالة قصيرة
- أيقونة بسيطة
- CTA واضح

### Loading States

يُفضّل استخدام skeletons أكثر من `CircularProgressIndicator` في الـ dashboards، خصوصًا في:

- `HR`
- `Admin`
- `Super Admin`

## 9. ترتيب التنفيذ المقترح

### المرحلة الأولى

إعادة تصميم بدون تغيير كبير في الداتا:

1. `Employee Home`
2. `HR Home`
3. `Admin Home`
4. `Super Admin Home`

### المرحلة الثانية

استخراج widgets مستقلة بدل reuse العام.

### المرحلة الثالثة

إضافة:

- charts خفيفة
- priority queues
- skeleton loaders مخصصة لكل dashboard

## 10. توصية التنفيذ الأولى

أفضل بداية عملية الآن:

1. تنفيذ `Employee Home` جديد كمرجع بصري
2. بعدها `HR Home` لأن الفرق فيها سيكون واضح جدًا
3. ثم `Admin Home`
4. وأخيرًا `Super Admin Home`

## 11. ملاحظة مهمة

لتحسين الإحساس العام بسرعة، لا تبدأ بتغيير الألوان فقط.

الأثر الحقيقي سيأتي من:

- إعادة ترتيب sections
- تكبير الـ hero card
- تقليل التكرار
- تخصيص widgets لكل Role

لو بدأنا بهذه النقاط، شكل التطبيق سيقفز مباشرة من "مرتب لكنه عادي" إلى "نظام داخلي احترافي وواضح".
