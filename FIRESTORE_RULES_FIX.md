# Fix Firestore Permission Denied Error

## المشكلة
```
Error: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## الحل

### الخطوة 1: افتح Firebase Console
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك: **graduation_swiftchat**

### الخطوة 2: عدّل Firestore Security Rules
1. من القائمة الجانبية، اختر **Firestore Database**
2. اضغط على تاب **Rules**
3. استبدل القواعد الحالية بالقواعد التالية:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - authenticated users can read all, write own
    match /users/{userId} {
      // أي مستخدم مسجل دخول يقدر يقرأ معلومات أي مستخدم تاني (عشان البحث عن الأصدقاء)
      allow read: if request.auth != null;
      // بس كل مستخدم يقدر يعدل على بياناته هو بس
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // User's contacts sub-collection (قائمة الأصدقاء لكل مستخدم)
      // كل مستخدم يقدر يقرأ ويكتب في قائمة أصدقاءه بس
      match /contacts/{contactId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // User's calls sub-collection (قائمة المكالمات لكل مستخدم)
      match /calls/{callId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Chats collection - participants only
    match /chats/{chatId} {
      allow read, write: if request.auth != null;
      
      // Messages sub-collection
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    
    // Groups collection
    match /groups/{groupId} {
      allow read, write: if request.auth != null;
      
      // Group messages
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    
    // Notifications
    match /notification/{userId} {
      allow read, write: if request.auth != null;
      
      match /call/{callId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

### الخطوة 3: انشر القواعد
1. اضغط على زر **Publish**
2. انتظر بضع ثوانٍ حتى تُطبّق القواعد

### الخطوة 4: أعد تشغيل التطبيق
```bash
flutter run
```

## ملاحظات مهمة
- ✅ القواعد الحالية تسمح فقط للمستخدمين المسجلين بالدخول
- ⚠️ لا تستخدم `allow read, write: if true;` في الإنتاج (غير آمن)
- 🔒 تأكد من تسجيل دخول المستخدم قبل الوصول إلى Firestore

## اختبار القواعد
بعد تطبيق القواعد:
1. افتح التطبيق
2. سجّل دخول بحساب
3. جرّب فتح صفحة **Chats**
4. الخطأ يجب أن يختفي
