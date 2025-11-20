# 🔥 Firebase Firestore Rules - إصلاح مشكلة المكالمات

## ❌ المشكلة:
```
W/Firestore: Write failed at users/ZupUkg4bGng3zrgfnmQZC8pHx6s2/calls/...
Status{code=PERMISSION_DENIED}
```

التطبيق بيحاول يكتب في مجموعة المكالمات بس Firebase Rules مش بتسمح!

---

## ✅ الحل:

### الخطوة 1: افتح Firebase Console
1. روح على: https://console.firebase.google.com/
2. اختار مشروع `graduation_swiftchat`
3. من القائمة الجانبية اختار: **Firestore Database**
4. اضغط على تاب **Rules**

### الخطوة 2: استبدل الـ Rules بالكود ده:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== قواعد المستخدمين =====
    match /users/{userId} {
      // السماح بالقراءة لأي مستخدم مسجل
      allow read: if request.auth != null;
      
      // السماح بالكتابة فقط للمستخدم نفسه
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // ===== قواعد الكونتاكتس (sub-collection) =====
      match /contacts/{contactId} {
        allow read: if request.auth != null && request.auth.uid == userId;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      
      // ===== قواعد المكالمات (sub-collection) ✅ الجديد =====
      match /calls/{callId} {
        // السماح بالقراءة للمستخدم نفسه
        allow read: if request.auth != null && request.auth.uid == userId;
        
        // السماح بالكتابة:
        // 1. المستخدم يكتب في calls الخاصة بيه
        // 2. أو أي مستخدم تاني بيعمل مكالمة ليه (caller)
        allow write: if request.auth != null && (
          request.auth.uid == userId ||  // المستخدم نفسه
          request.auth.uid == request.resource.data.callerUid  // المتصل
        );
        
        // السماح بالحذف للمستخدم نفسه بس
        allow delete: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // ===== قواعد المحادثات =====
    match /chats/{chatId} {
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.sender.id ||
        request.auth.uid == resource.data.receiver.id
      );
      
      allow create: if request.auth != null && (
        request.auth.uid == request.resource.data.sender.id ||
        request.auth.uid == request.resource.data.receiver.id
      );
      
      allow update: if request.auth != null && (
        request.auth.uid == resource.data.sender.id ||
        request.auth.uid == resource.data.receiver.id
      );
      
      // ===== قواعد الرسائل داخل المحادثة =====
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }
    
    // ===== قواعد المجموعات =====
    match /groups/{groupId} {
      allow read: if request.auth != null;
      
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.createdBy;
      
      allow update: if request.auth != null && 
        request.auth.uid in resource.data.members;
      
      // ===== قواعد رسائل المجموعات =====
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }
  }
}
```

### الخطوة 3: انشر الـ Rules
1. اضغط على زر **Publish** (أو **نشر**)
2. استنى لحد ما تظهر رسالة "Rules published successfully"

---

## 📝 شرح القواعد الجديدة:

### قواعد المكالمات:
```javascript
match /calls/{callId} {
  // قراءة: المستخدم يشوف المكالمات بتاعته بس
  allow read: if request.auth.uid == userId;
  
  // كتابة: المستخدم أو اللي بيتصل بيه
  allow write: if request.auth.uid == userId || 
                 request.auth.uid == request.resource.data.callerUid;
  
  // حذف: المستخدم بس
  allow delete: if request.auth.uid == userId;
}
```

### ليه القاعدة دي مهمة؟
- لما **Mahmoud** بيتصل بـ **aaa**
- التطبيق بيكتب في: `users/aaa/calls/{callId}`
- القاعدة القديمة كانت بترفض لأن Mahmoud مش aaa
- القاعدة الجديدة بتسمح لأن `callerUid == Mahmoud`

---

## ✅ اختبار الحل:

بعد ما تنشر الـ Rules:
1. شغّل التطبيق تاني
2. جرب تعمل مكالمة صوتية
3. لو شفت اللوج ده يبقى تمام:
```
I/flutter: 🔔 Call notification sent successfully
```

4. لو لسه فيه خطأ:
```
E/flutter: [cloud_firestore/permission-denied]
```
يبقى في حاجة غلط في الـ Rules - تأكد إنك نسختهم صح!

---

## 🚨 ملاحظات مهمة:

1. **النشر بياخد وقت**: 
   - ممكن يحتاج 1-2 دقيقة لحد ما القواعد تتفعل

2. **تأكد من userId**:
   - القاعدة `match /users/{userId}/calls/{callId}` لازم تطابق الـ path بالظبط

3. **Security**:
   - القواعد دي آمنة: كل مستخدم يقدر يشوف المكالمات بتاعته بس
   - المتصل (caller) يقدر يكتب notification للمستقبل (receiver)

---

## 📞 المشاكل الشائعة:

### لو قابلتك مشكلة "permission-denied":
- تأكد إنك ناشر الـ Rules صح
- تأكد إن المستخدم مسجل دخول (`request.auth != null`)
- تأكد إن `callerUid` موجود في البيانات

### لو المكالمة مش واصلة:
- تأكد إن Zego Cloud مظبوط (App ID و App Sign)
- تأكد إن الـ permissions (Microphone/Camera) موافق عليهم
- تأكد إن النت شغال عند الطرفين

---

## 📚 مصادر إضافية:

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Zego Cloud Setup Guide](./ZEGO_SETUP_GUIDE.md)
- [Online/Offline Status Guide](./ONLINE_OFFLINE_STATUS.md)
