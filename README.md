# درع التاجر — Flutter Scaffold: السوق + التسجيل + الشات + الصور + الطلبات + Firebase

هذا سكيلتون فعلي (مو Mock) لأول خمس مراحل من تطبيق درع التاجر:

- **المرحلة 1:** هيكلة المشروع، شاشة السوق (بحث + فلترة + بطاقة منتج +
  تفاصيل)، الاتصال بـ Firestore لسحب الأسعار لحظيًا (features #1–#4).
- **المرحلة 2:** تسجيل الدخول ببريد إلكتروني/رقم جوال (OTP)/جوجل
  (feature #31)، ونموذج "إضافة منتج" فعلي مربوط بهوية التاجر المسجّل
  (يكمل feature #3)، وقواعد أمان Firestore تمنع أي تاجر يعدّل منتج تاجر
  ثاني.
- **المرحلة 3:** نظام شات مباشر لكل صفقة (feature #12)، مع مؤشر "تم
  القراءة" (feature #15)، وزر "اطلب عرض سعر" صار فعلي بيفتح محادثة حقيقية
  (يكمل feature #5)، وشاشة "محادثاتي" بعدّاد غير مقروء.
- **المرحلة 4:** رفع صور فعلي عبر Firebase Storage — صورة المنتج
  (feature #34) وصور داخل الشات (يكمل feature #13)، مع قواعد أمان
  Storage منفصلة عن Firestore.
- **المرحلة 5:** هيكلة الطلبات والضمان المالي (features #6, #7, #9, #11) —
  زر "إتمام الشراء"، شاشة دفع بخيار كامل/عربون، شاشة "طلباتي". ⚠️ **مهم
  جدًا:** هاي المرحلة تسجّل نية شراء فقط — الدفع الفعلي عبر PayTabs
  **غير مربوط**، وده مقصود. اقرأ قسم "الدفع والضمان" بالأسفل قبل ما
  تكمل عليها.

> ⚠️ **مهم:** هذا الكود اتكتب بدون اتصال إنترنت (بيئة العمل ما فيها شبكة)،
> فما قدرت أشغّل `flutter pub get` ولا أتأكد من أرقام نسخ الحزم على
> pub.dev، ولا أختبر الكود فعليًا على جهاز/محاكي. راجعته يدويًا بالكامل
> بعد كل مرحلة (توازن الأقواس، صحة الـ imports، تطابق كل استدعاء لأي
> شاشة مع المعاملات المطلوبة فعليًا، اكتمال كل تنفيذ لواجهاته المجردة) —
> بس هذا مش بديل عن تجربة فعلية. لو طلع أي خطأ عندك وقت `flutter run`،
> ابعتلي نص الخطأ كامل وبنصلحه.

---

## 1) قبل ما تبدأ

تحتاج تكون مثبت عندك:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (قناة stable)
- [Firebase CLI](https://firebase.google.com/docs/cli) + أداة [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)
- حساب Firebase (مجاني يكفي للبداية — خطة Spark)

تأكد إنه كل شي شغال:
```bash
flutter doctor
firebase --version
```

## 2) تثبيت الحزم

```bash
cd tajer_shield_app
flutter pub get
flutter pub outdated   # تأكد إنه ما في نسخ حزم قديمة/متعارضة
```

⚠️ حزمة `google_sign_in` مثبّتة على خط `^6.2.1` بالذات — هاي الحزمة
غيّرت الـ API بشكل كبير بنسخة 7. إذا `flutter pub get` طلعلك نسخة 7.x
لسبب ما، الكود بـ `lib/services/firebase_auth_repository.dart` رح
يحتاج تعديل (فيه تعليق بالملف يشرح الفرق).

## 3) ربط Firebase

```bash
firebase login
flutterfire configure
```

هاي الأمر رح:
- يخليك تختار أو تنشئ مشروع Firebase
- ينشئ `lib/firebase_options.dart` تلقائيًا
- يضيف ملفات الإعداد لكل منصة (Android/iOS/Web/Desktop)

بعدها، عدّل `lib/main.dart`: بدل
```dart
await Firebase.initializeApp();
```
حطّ
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```
واستورد `firebase_options.dart` في أعلى الملف.

## 4) تفعيل طرق تسجيل الدخول

من Firebase Console → Authentication → Sign-in method، فعّل الثلاثة:

**البريد الإلكتروني/كلمة المرور** — تفعيل بضغطة واحدة، ما بيحتاج إعداد إضافي.

**جوجل** —
1. فعّلها من نفس الصفحة، واختر "support email".
2. **أندرويد:** لازم تضيف SHA-1 fingerprint لمشروعك بإعدادات Firebase
   (Project settings → Your apps → Android app). احصل عليه بـ:
   ```bash
   cd android && ./gradlew signingReport
   ```
   بعد ما تضيفه، نزّل `google-services.json` المحدّث من نفس الصفحة
   وحطه مكان الملف القديم بـ `android/app/`.
3. **iOS:** تأكد إنه `REVERSED_CLIENT_ID` من `GoogleService-Info.plist`
   مضاف بـ `ios/Runner/Info.plist` ضمن `CFBundleURLSchemes` (خطوة
   قياسية بدليل `google_sign_in` الرسمي — flutterfire configure غالبًا
   بيسويها تلقائيًا).

**رقم الجوال (OTP)** —
1. فعّلها من نفس الصفحة.
2. وقت التطوير، أضف "Phone numbers for testing" (رقم + كود ثابت) من
   نفس الشاشة عشان تختبر بدون ما تستهلك SMS حقيقي كل مرة.
3. **أندرويد:** غالبًا يشتغل بدون إعداد إضافي (Play Integrity/SafetyNet
   بيتدبّر تلقائيًا مع `flutterfire configure`).
4. **iOS/الويب:** يحتاج إعداد reCAPTCHA/APNs إضافي — راجع
   [توثيق Firebase الرسمي لـ Phone Auth](https://firebase.google.com/docs/auth/flutter/phone-auth)
   إذا واجهت مشكلة هون تحديدًا.

## 5) إنشاء Firestore + رفع قواعد الأمان

```bash
firebase init firestore    # لو أول مرة
firebase deploy --only firestore:rules
```

## 5.5) إنشاء Storage + رفع قواعده (جديد بالمرحلة 4)

```bash
firebase init storage    # لو أول مرة — ينشئ Storage bucket
firebase deploy --only storage
```

`storage.rules` يسمح برفع صورة منتج بس لصاحبها (حسب uid بالمسار)، وصور
شات بس لمشاركي تلك المحادثة تحديدًا — وفيه تحقق من نوع الملف (صورة فقط)
وحجمه (أقل من 5MB). لاحظ إنه قاعدة الشات فيها استعلام Firestore داخل
Storage rules (cross-service rules) للتأكد من هوية المشاركين — تأكد
إنك فعّلت Firestore *قبل* Storage عشان هاي الميزة تشتغل صح.

قواعد المرحلة 3 (`firestore.rules`) تغطي ثلاث مجموعات:
- **`products`:** قراءة مفتوحة، وكتابة مربوطة بهوية التاجر (نفس المرحلة 2).
- **`conversations`:** يقدر يشوفها بس المشتري والبائع المشاركين فيها، وكل
  طرف يقدر يعدّل حقل "تمت القراءة" تبعه هو بس — مش تبع الطرف التاني.
- **`conversations/{id}/messages`:** رسائل غير قابلة للتعديل بعد الإرسال،
  ومحصورة بمشاركين المحادثة، و`senderId` لازم يطابق هوية المرسِل الحقيقية
  (يمنع انتحال شخصية بإرسال رسالة باسم شخص ثاني).

صلاحية الإدمن (feature #36، ومركز النزاعات #24) لسه TODO لحد ما نبني
لوحة الإدمن بمرحلة لاحقة — التفاصيل موجودة بآخر `firestore.rules`.

## 6) تعبئة بيانات تجريبية حقيقية (اختياري لكن يستحسن)

التطبيق فيه "وضع تجريبي" تلقائي (بيانات محفوظة بالكود) يشتغل لو
Firebase مو مربوط. بس عشان تتأكد إنه الاتصال الحقيقي بـ Firestore شغال:

1. افتح Firebase Console → Firestore Database
2. أنشئ collection اسمها `products`
3. استخدم البيانات الموجودة في `firestore.seed.json` كنموذج (لاحظ
   ملاحظة `updatedAt` بآخر الملف — ضروري تضيفه يدويًا لو أدخلت البيانات
   بإيدك من الكونسول)

أو أسهل: بعد ما تربط تسجيل الدخول (خطوة 4)، شغّل التطبيق وسجّل دخول
واستخدم زر "إضافة منتج" أو "اطلب عرض سعر" مباشرة من الواجهة — هذا بيكتب
فعليًا بـ Firestore (بما فيه محادثات حقيقية بـ `conversations`).

## 7) شغّل التطبيق

```bash
flutter run
```

لو ظهر شريط ذهبي فوق شاشة السوق يقول "وضع تجريبي" — معناته Firebase مو
مربوط صح، رجّع لخطوة 3. لو ضغطت "تسجيل الدخول" وطلعتلك رسالة حمراء
"تسجيل الدخول غير متاح حاليًا" — نفس السبب بالضبط.

---

## شو موجود لحد هلأ

```
lib/
  main.dart                      نقطة الدخول + تهيئة Firebase (مع fallback لكل الخدمات)
  app.dart                       MaterialApp، الثيم، دعم RTL/عربي، إعداد intl
  core/
    theme.dart                   ألوان وخطوط الهوية (كحلي #0B1F3A + ذهبي #C98A2C)
    constants.dart                فئات المنتجات + أسماء الـ collections
  models/
    product.dart                  موديل المنتج + تحويل من/إلى Firestore
    app_user.dart                 موديل المستخدم المسجّل دخول
    conversation.dart             موديل المحادثة (صفقة واحدة = محادثة واحدة)
    chat_message.dart             موديل الرسالة (نص و/أو صورة)
    order.dart                    موديل الطلب/الضمان + حساب العمولة 2%
  services/
    market_repository.dart              الواجهة المجردة لبيانات السوق
    firestore_market_repository.dart    التنفيذ الحقيقي عبر Firestore
    sample_market_repository.dart       بيانات تجريبية بالذاكرة (fallback)
    auth_repository.dart                الواجهة المجردة للتسجيل
    firebase_auth_repository.dart       التنفيذ الحقيقي (بريد + جوال OTP + جوجل)
    disabled_auth_repository.dart       fallback لما Firebase مو مربوط
    chat_repository.dart                الواجهة المجردة للشات
    firestore_chat_repository.dart      التنفيذ الحقيقي عبر Firestore
    sample_chat_repository.dart         شات تجريبي بالذاكرة (fallback)
    storage_repository.dart             الواجهة المجردة لرفع الصور
    firebase_storage_repository.dart    التنفيذ الحقيقي عبر Firebase Storage
    disabled_storage_repository.dart    fallback لما Firebase مو مربوط
    order_repository.dart               الواجهة المجردة للطلبات — سطح كتابة ضيّق عن قصد
    firestore_order_repository.dart     التنفيذ الحقيقي (إنشاء + قراءة + إلغاء بس)
    sample_order_repository.dart        طلبات تجريبية بالذاكرة (fallback)
  features/
    market/
      market_screen.dart          شاشة السوق: بحث + فلترة + قائمة + أيقونات الحساب/الشات/الطلبات
      product_detail_screen.dart  تفاصيل المنتج + "اطلب عرض سعر" + "إتمام الشراء"
      add_product_screen.dart     نموذج إضافة منتج (يحتاج تسجيل دخول)
      widgets/
        product_card.dart
        category_filter.dart
    auth/
      login_screen.dart           تبويبين (بريد/جوال) + زر جوجل
      phone_otp_screen.dart       إدخال رمز التحقق SMS
      widgets/
        google_sign_in_button.dart
    chat/
      conversations_list_screen.dart   "محادثاتي" — كل صفقاتك بمكان واحد
      chat_screen.dart                 محادثة صفقة واحدة + مؤشر "تم القراءة" + إرسال صور
    checkout/
      checkout_screen.dart        ملخص الطلب + Escrow + كامل/عربون — ⚠️ يسجّل نية شراء بس
      orders_list_screen.dart     "طلباتي" — سجل المعاملات وحالة كل صفقة
    profile/
      profile_screen.dart         بيانات الحساب + تسجيل خروج
    shared/
      image_picker_field.dart     ودجت مشترك: كاميرا/معرض → رفع → رابط الصورة

firestore.rules                  قواعد أمان Firestore (سوق + تسجيل + شات + طلبات)
firestore.seed.json              بيانات تجريبية لاختبار Firestore الحقيقي
storage.rules                    قواعد أمان Firebase Storage (صور المنتجات والشات)
functions/
  package.json                   اعتماديات Cloud Functions (firebase-admin + firebase-functions)
  index.js                       ⚠️ هيكلة الدفع فقط — بدون تكامل PayTabs فعلي، اقرأ التعليق بأعلاه
```

### قرارات تصميم مقصودة

- **نمط Repository لكل من السوق والتسجيل والشات:** الشاشات ما بتحكي
  مباشرة مع `cloud_firestore` أو `firebase_auth` — بتحكي مع interfaces
  (`MarketRepository`, `AuthRepository`, `ChatRepository`). هيك لما
  نضيف الدفع والضمان بمرحلة لاحقة، ما رح نحتاج نعيد كتابة الشاشات
  الموجودة.
- **Fallback تلقائي للكل:** لو Firebase مو مربوط، التطبيق ما بينهار —
  السوق بيشتغل ببيانات جاهزة، وأزرار تسجيل الدخول والشات بتوريك رسالة
  واضحة بدل ما تكسر التطبيق.
- **محادثة واحدة لكل صفقة، مش صندوق رسائل عام:** المحادثة مربوطة بمنتج
  محدد + مشتري + بائع — نفس منطق "شات مباشر بين التاجر والمشتري داخل كل
  صفقة" المكتوب بعرض المستثمرين حرفيًا. الضغط على "اطلب عرض سعر" لنفس
  المنتج مرتين ما بينشئ محادثتين — بيرجّعك لنفس المحادثة.
- **"تم القراءة" بدون تكلفة كتابة إضافية لكل رسالة:** بدل ما نسجّل حالة
  قراءة لكل رسالة على حدة (كتابة كثيرة)، كل محادثة فيها `lastReadAt`
  لكل طرف، وأي رسالة أقدم من وقت آخر قراءة للطرف التاني تعتبر مقروءة.
  هذا يعني معرفة "قرأ ولا لأ" بقراءة وحدة بدل كتابة لكل رسالة.
- **الإشعارات الفورية (FCM، feature #14) لسه مو موجودة:** الشات شغال
  بالكامل وقت التطبيق مفتوح (Firestore realtime)، بس ما في push
  notification لما يوصل رد وأنت خارج التطبيق — هذا يحتاج إعداد Cloud
  Messaging + Cloud Functions، محجوز لمرحلة لاحقة قريبة.
- **حجم الصور محدود بـ 5MB ونوعها لازم يكون image/*:** مفروض من طرفين —
  `storage.rules` (على مستوى السيرفر، هذا هو الفرض الحقيقي) و
  `ImagePickerTile`/`ChatScreen` (ضغط الصورة لعرض أقصى 1600px قبل الرفع،
  تحسين لتقليل حجم الرفع مش فرض أمان).

---

## ⚠️ الدفع والضمان (Escrow) — اقرأ هذا قبل أي شي

المرحلة 5 بنت **الهيكلة** بس، مش نظام دفع فعلي شغال. بالتحديد:

**اللي فعلي وشغال:**
- إنشاء سجل "طلب" حقيقي بـ Firestore (`orders` collection) لما تضغط
  "ادفع الآن" — بحالة `pendingPayment`. ما في أي فلوس تتحرك.
- شاشة "طلباتي" بتعرض هاي السجلات الحقيقية وحالتها.
- قواعد أمان Firestore تمنع التطبيق (Client) من كتابة أي حالة تانية غير
  `pendingPayment` → `cancelled` مباشرة — أي تحويل تاني (`paid`,
  `shipped`, `delivered`, `refunded`) لازم يجي من Cloud Function موقّعة،
  مو من التطبيق نفسه. هذا مقصود ومهم أمنيًا: لو حدا عدّل نسخة من
  التطبيق، ما يقدر يمنح نفسه "دفع ناجح" مجانًا.

**اللي مو موجود (وليش):**
- `functions/index.js` فيه **هيكلة** الدوال المطلوبة (`createPaymentSession`,
  `paytabsWebhook`, `confirmDelivery`, `requestRefund`) بس بدون تكامل
  حقيقي مع PayTabs. تحديدًا **التحقق من توقيع الـ webhook** (signature
  verification) متروك TODO عن قصد — لو غلطت فيه، أي حدا عالإنترنت يقدر
  يبعت طلب مزوّر يقول "تم الدفع" ويفرّغ الضمان بدون ما يدفع فلس. هاي
  نقطة أمان حرجة لازم تُكتب وتُختبر ضد بيئة PayTabs التجريبية (sandbox)
  الحقيقية، مو تُخمَّن من مساعد ذكاء اصطناعي ما إله وصول لتوثيق PayTabs
  الحالي أو بيئة اختبار حقيقية.

**قبل ما تشتغل بفلوس حقيقية، الخطوات المطلوبة:**
1. افتح حساب PayTabs واحصل على بيانات اعتماد بيئة الاختبار (sandbox).
2. اقرأ توثيق PayTabs الحالي لـ REST API + Webhooks:
   https://support.paytabs.com/
3. اكتب واختبر `createPaymentSession` و`paytabsWebhook` ضد الـ sandbox.
4. خصّص وقت لمراجعة أمان مخصصة للتحقق من التوقيع تحديدًا — هاي أهم نقطة
   بكل نظام الدفع.
5. بس بعدها بدّل بيانات الاختبار ببيانات الإنتاج الحقيقية.

هذا مو تقصير أو كسل مني — هذا هو المعيار الصناعي القياسي لأي نظام دفع
حقيقي: منطق التحقق من الدفع لازم يكون من طرف السيرفر فقط، ومُختبر ضد
بيئة حقيقية، ومراجَع أمنيًا، قبل ما يوصل فلوس حقيقية.

---

## المرحلة الجاية (Phase 6 مقترحة)

بناءً على ترتيب الميزات بعرض المستثمرين، الأنسب بعد هذا:
1. **إشعارات FCM** (feature #14) — تنبيه فوري لما يوصل رد على الشات أو
   تحديث حالة طلب، وأنت خارج التطبيق.
2. **لوحة تحكم الإدمن** (features #21–#26) — إدارة الأسعار والمستخدمين
   ومركز النزاعات. هاي بتحتاج custom claims حقيقية (تحديد مين "إدمن")
   وواجهة منفصلة، مذكورة كـ TODO بكل من `firestore.rules` و
   `functions/index.js` الحاليين.
3. **إكمال تكامل PayTabs الفعلي** حسب الخطوات الموثقة بقسم "⚠️ الدفع
   والضمان" فوق — هاي بتحتاج وقتك المباشر (حساب PayTabs، بيانات
   اعتماد، مراجعة أمان)، مو شي أقدر أكمله بمفردي من هون.

قوللي وين بدك تكمل ونبني هيكلة المرحلة الجاية بنفس الطريقة.
