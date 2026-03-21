# FCM إعداد النوتيفيكيشنز باستخدام

## 📋 قائمة المتطلبات

✅ **تم بالفعل:**
- تحديث `pubspec.yaml` - إضافة firebase_messaging، حذف local_notifications و timezone
- تعديل `push_notification_service.dart` - استخدام FCM بدل local notifications
- إنشاء Cloud Functions في `functions/index.js` و `functions/package.json`

## 🔧 الخطوات التالية

### **الخطوة 1: تحديث Flutter Dependencies**

```bash
cd d:\flutterrr-main\myproj
flutter pub get
```

### **الخطوة 2: إعداد Firebase Console**

1. اذهب إلى [firebase.google.com](https://firebase.google.com)
2. اختر مشروعك من Firebase Console
3. اضغط على **⚙️ Project Settings** في الأسفل اليسار
4. اختر تبويب **Apps** وتأكد أن تطبيقك موجود
5. اذهب للـ **Service Accounts** tab
6. اضغط **Generate new private key** واحفظ الملف (سيحتاج في الخطوة 4)

### **الخطوة 3: إعداد Cloud Functions في Firebase**

#### أ) تثبيت Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

#### ب) تحضير Functions Directory
```bash
cd d:\flutterrr-main\myproj\functions
npm install
```

#### ج) ربط مشروعك بـ Firebase
```bash
cd d:\flutterrr-main\myproj
firebase init functions --project YOUR_PROJECT_ID
```
حيث `YOUR_PROJECT_ID` هو معرف مشروعك في Firebase

**ملاحظة:** إذا سألك عن استبدال الملفات، اختر **No** عشان نحافظ على `index.js` و `package.json` الموجودين

#### د) نشر Functions على Firebase
```bash
cd d:\flutterrr-main\myproj
firebase deploy --only functions --project YOUR_PROJECT_ID
```

### **الخطوة 4: اختبار الإشعارات**

#### أ) بناء وتثبيت APK
```bash
cd d:\flutterrr-main\myproj
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

#### ب) فتح التطبيق
- اضغط على التطبيق لفتحه
- سيطلب منك إذن الإشعارات - اختر **Allow**
- هتشوف في Console:
  ```
  [FCM] Device Token: ... (token طويل)
  [FCM] Subscribed to daily_notifications topic
  ```

#### ج) اختبار دليل
في Firebase Console، اتبع الخطوات:

1. اضغط على **Messaging** من القائمة اليسار
2. اضغط **Create campaign** أو **Send first message**
3. الصق الـ JSON التالي في **Custom data**:

```json
{
  "notification": {
    "title": "Safe Space Test",
    "body": "This is a test notification!"
  },
  "data": {
    "type": "test"
  }
}
```

4. اختر **Send to Topic** وادخل: `daily_notifications`
5. اضغط **Send**

إذا شغال التطبيق → الإشعار يظهر فوراً ✅
إذا مقفول التطبيق → الإشعار يظهر في notification tray ✅

### **الخطوة 5: التحقق من التشغيل اليومي**

الـ Cloud Functions تعمل بجدول زمني:
- **الصبح (9:00 AM UTC)**: `sendMorningNotification`
- **الليل (9:00 PM UTC = 21:00)**: `sendNightNotification`

للتحقق من التشغيل، اذهب إلى Firebase Console:
1. **Functions** → **Logs** (قائمة اليسار)
2. ستشوف رسائل مثل:
   ```
   Morning notification sent successfully. Message ID: cff...
   Night notification sent successfully. Message ID: dgg...
   ```

## 🛠️ تصحيح المشاكل

### المشكلة: "Functions not deploying"
- تأكد من `firebase login` بنجاح
- تأكد من صحة `YOUR_PROJECT_ID`
- شغل: `firebase deploy --only functions --debug`

### المشكلة: "Topic subscription failed"
- تأكد من تثبيت firebase_messaging في pubspec.yaml ✓
- تأكد من Permission granted في app ✓
- اعد start التطبيق

### المشكلة: "Notifications not arriving"
- تأكد من عدم إيقاف Firebase في الـ battery settings
- اختبر مع التطبيق مفتوح أولاً
- اختبر الموضوع من Firebase Console

## 📱 الملخص

```
App (Flutter)
    ↓ (subscribes to 'daily_notifications' topic)
Firebase Messaging Service
    ↑ (receives from)
Cloud Functions (scheduled tasks)
    ↑ (checks time every minute)
Cloud Scheduler (UTC timezone)
```

**الآن كل المستخدمين اللي عندهم التطبيق سيستقبلون:**
- ✅ إشعار الصبح (9:00 AM) برسالة مختلفة كل يوم
- ✅ إشعار الليل (9:00 PM) برسالة مختلفة كل يوم
- ✅ الإشعار يوصل حتى لو التطبيق مقفول 🎉

---

**ملاحظات إضافية:**
- الأوقات بـ UTC - إذا كنت في timezone مختلف، اضبط الساعات في Cloud Functions
- بتقدر تعدل الرسائل في `morningMessages` و `nightMessages` شوقت ما بدك
- بتقدر تضيف أوقات إضافية بنفس الطريقة
