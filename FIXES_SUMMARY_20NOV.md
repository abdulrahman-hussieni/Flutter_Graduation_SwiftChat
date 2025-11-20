# 🔧 تقرير المشاكل والحلول - 20 نوفمبر 2025

## 📋 ملخص المشاكل اللي اتحلت:

### 1. ❌ **مشكلة Permission Denied في المكالمات**
**الخطأ:**
```
W/Firestore: Write failed at users/ZupUkg4bGng3zrgfnmQZC8pHx6s2/calls/...
Status{code=PERMISSION_DENIED}
```

**السبب:**
- Firebase Rules كانت بترفض كتابة المكالمات
- لما Mahmoud يتصل بـ aaa، بيحاول يكتب في `users/aaa/calls/`
- القاعدة القديمة كانت بتسمح بس لـ aaa نفسه

**الحل:**
✅ **تم تحديث `firestore.rules`**
```javascript
match /calls/{callId} {
  // السماح بالكتابة للمستخدم أو المتصل
  allow write: if request.auth.uid == userId || 
                 request.auth.uid == request.resource.data.callerUid;
}
```

**الخطوة المطلوبة منك:**
🔴 **لازم تنشر الـ Rules في Firebase Console!**
1. افتح: https://console.firebase.google.com/
2. اختار المشروع → Firestore Database → Rules
3. انسخ المحتوى من `firestore.rules`
4. اضغط **Publish**

---

### 2. 🎤 **مشكلة Microphone Permission**
**الخطأ:**
```
E/PLogger: Permission.microphone permission not granted
E/AudioRecord: Cannot create AudioRecord
```

**السبب:**
- Zego SDK بيحتاج إذن الميكروفون عشان المكالمات
- التطبيق ماطلبش الإذن من المستخدم

**الحل:**
✅ **تم إضافة Permissions في 3 أماكن:**

1. **AndroidManifest.xml** - تم إضافة:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

2. **AudioCallPage.dart** - تم تحويلها لـ StatefulWidget مع:
```dart
Future<void> _checkPermissions() async {
  var micStatus = await Permission.microphone.request();
  // لو مرفوض، يظهر شاشة تطلب من المستخدم يروح Settings
}
```

3. **VideoCallPage.dart** - نفس الفكرة مع Camera + Microphone

**النتيجة:**
- دلوقتي لما تضغط على زر المكالمة، هيظهرلك popup يطلب الإذن
- لو رفضت، هيظهرلك شاشة فيها زر "Open Settings"

---

### 3. 📶 **مشكلة Online/Offline بيعتمد على Login بس**
**المشكلة:**
```dart
// كان بيحدث Online بس لما المستخدم يعمل login
await updateUserStatus(isOnline: true);
```
- لو المستخدم قفل النت → لسه Online!
- لو المستخدم قفل التطبيق → لسه Online!
- الـ Status بيتغير بس لما يعمل Login/Logout

**الحل:**
✅ **تم إضافة Connectivity Listener في ProfileController:**

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ProfileController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      bool hasConnection = results.any((result) => result != ConnectivityResult.none);
      
      if (hasConnection) {
        print("✅ Internet connected - Setting Online");
        updateUserStatus(isOnline: true);
      } else {
        print("❌ Internet disconnected - Setting Offline");
        updateUserStatus(isOnline: false);
      }
    });
  }
}
```

**النتيجة:**
- دلوقتي التطبيق بيراقب حالة النت **في الوقت الفعلي**
- لو قطعت الواي فاي → فوراً Offline
- لو فتحت الواي فاي → فوراً Online
- لو قفلت التطبيق → Offline (من خلال AppLifecycleState)

**كيف بيشتغل:**
1. **App Lifecycle** (main.dart):
   - `AppLifecycleState.resumed` → Online
   - `AppLifecycleState.paused` → Offline

2. **Connectivity Listener** (ProfileController):
   - `ConnectivityResult.wifi` أو `mobile` → Online
   - `ConnectivityResult.none` → Offline

3. **Login/Logout** (AuthController):
   - Login → Online
   - Logout → Offline

---

### 4. 🔔 **مشكلة المكالمات بتظهر كأن الطرف التاني رد**
**الملاحظة من اللوج:**
```
I/flutter: [INFO] onRoomOnlineUserCountUpdate count: 1
```
- لما Mahmoud يتصل بـ aaa
- بيظهر إن الـ room فيها 1 user (Mahmoud)
- لكن التطبيق بيفكر إن aaa رد!

**السبب المحتمل:**
- CallController بيستخدم Firestore Notifications
- الـ notification بتتكتب في `users/aaa/calls/{callId}`
- **لكن aaa مش مفتوح التطبيق!**
- Zego SDK بيعمل room ويستنى
- لما مفيش حد يدخل بعد 20 ثانية → timeout

**الحل:**
⚠️ **لازم تتأكد من:**
1. الـ Firestore Rules متنشرة (عشان الـ notification توصل)
2. الطرف التاني (aaa) فاتح التطبيق
3. الـ `getCallsNotification()` شغال عند الطرف التاني

**تحقق من الكود:**
```dart
// في CallController
getCallsNotification().listen((List<CallModel> callList) {
  if (callList.isNotEmpty) {
    var callData = callList[0];
    if (callData.type == "audio") {
      audioCallNotification(callData);  // بيظهر SnackBar
    }
  }
});
```

**الحل المقترح:**
- لازم تجرب المكالمات مع **جهازين مختلفين**
- أو تعمل **two accounts** على جهازين مختلفين
- أو تستخدم **Emulator + Real Device**

---

## ✅ الخطوات التالية:

### 1. نشر Firebase Rules (مهم جداً!)
```bash
1. افتح: https://console.firebase.google.com/
2. اختار المشروع
3. Firestore Database → Rules
4. انسخ من firestore.rules
5. Publish
```

### 2. اختبار الحلول:
```bash
# تأكد إن Permissions بتطلب صح
flutter run

# لما تضغط على زر المكالمة:
# - لازم يظهرلك "Allow Microphone?"
# - لو رفضت → "Open Settings" button
# - لو قبلت → المكالمة تبدأ
```

### 3. اختبار Online/Offline:
```bash
# افتح التطبيق
# اقطع الواي فاي
# شوف اللوج:
❌ Internet disconnected - Setting Offline

# فتح الواي فاي
✅ Internet connected - Setting Online
```

### 4. اختبار المكالمات (مع جهازين):
```bash
Device 1: Login as Mahmoud2@gmail.com
Device 2: Login as aaa@gmail.com

# من Device 1:
اضغط على Audio Call لـ aaa

# Device 2 لازم يظهر:
Incoming Audio Call from Mahmoud
[Accept] [Reject]
```

---

## 📊 ملخص التعديلات:

| الملف | التعديل | السبب |
|------|---------|-------|
| `ProfileController.dart` | إضافة Connectivity Listener | مراقبة حالة النت |
| `AndroidManifest.xml` | إضافة Permissions | إذن الميكروفون والكاميرا |
| `AudioCallPage.dart` | تحويل لـ StatefulWidget + Permission Request | طلب الأذونات |
| `VideoCallPage.dart` | تحويل لـ StatefulWidget + Permission Request | طلب الأذونات |
| `firestore.rules` | **يحتاج نشر في Console** | السماح بكتابة المكالمات |

---

## 🚨 ملاحظات مهمة:

1. **Firebase Rules لازم تتنشر يدوياً** - مش هتشتغل من الملف لوحده!
2. **الأذونات لازم المستخدم يوافق عليها** - أول مرة بس
3. **المكالمات تحتاج جهازين** - عشان تختبرها صح
4. **Connectivity Listener شغال دلوقتي** - بيراقب النت تلقائياً

---

## 📞 لو لسه في مشاكل:

### المكالمات مش شغالة:
1. تأكد إن Firebase Rules متنشرة
2. تأكد إن Zego Config صح (App ID & App Sign)
3. تأكد إن الطرفين عندهم نت
4. تأكد إن الأذونات موافق عليها

### Online/Offline مش بيتحدث:
1. تأكد إن `connectivity_plus` متنزل في pubspec.yaml
2. شوف اللوجات في Console
3. تأكد إن Firebase Rules بتسمح بـ update على status

### Permission مش بتطلب:
1. تأكد إن `permission_handler` متنزل
2. تأكد إن AndroidManifest.xml فيه الـ permissions
3. جرب تعمل Clean & Rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ الخلاصة:

**تم حل:**
- ✅ Microphone Permission Issue
- ✅ Online/Offline Tracking (بناءً على النت)
- ✅ Firebase Rules للمكالمات (في الكود)

**لازم تعمل:**
- 🔴 نشر Firebase Rules في Console
- 🔴 اختبار المكالمات مع جهازين
- 🔴 التأكد من الأذونات بتطلب صح
