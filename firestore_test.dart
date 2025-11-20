// ملف اختبار الـ Firebase Structure
// استخدم الملف ده عشان تتأكد إن الـ Firebase شغال صح

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTest {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  // اختبار حفظ كونتاكت
  Future<void> testSaveContact() async {
    try {
      final currentUserId = auth.currentUser!.uid;
      final contactId = "test_contact_id";
      
      print("📝 Testing save contact...");
      print("Current User ID: $currentUserId");
      print("Path: users/$currentUserId/contacts/$contactId");
      
      await db
          .collection("users")
          .doc(currentUserId)
          .collection("contacts")
          .doc(contactId)
          .set({
        'id': contactId,
        'name': 'Test Contact',
        'email': 'test@test.com',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print("✅ Contact saved successfully!");
      
    } catch (ex) {
      print("❌ Error: $ex");
    }
  }

  // اختبار قراءة الكونتاكتس
  Future<void> testReadContacts() async {
    try {
      final currentUserId = auth.currentUser!.uid;
      
      print("📖 Testing read contacts...");
      print("Current User ID: $currentUserId");
      print("Path: users/$currentUserId/contacts/");
      
      final snapshot = await db
          .collection("users")
          .doc(currentUserId)
          .collection("contacts")
          .get();
      
      print("✅ Found ${snapshot.docs.length} contacts");
      
      for (var doc in snapshot.docs) {
        print("  - ${doc.id}: ${doc.data()}");
      }
      
    } catch (ex) {
      print("❌ Error: $ex");
    }
  }

  // اختبار حذف كونتاكت
  Future<void> testDeleteContact() async {
    try {
      final currentUserId = auth.currentUser!.uid;
      final contactId = "test_contact_id";
      
      print("🗑️ Testing delete contact...");
      print("Current User ID: $currentUserId");
      print("Path: users/$currentUserId/contacts/$contactId");
      
      await db
          .collection("users")
          .doc(currentUserId)
          .collection("contacts")
          .doc(contactId)
          .delete();
      
      print("✅ Contact deleted successfully!");
      
    } catch (ex) {
      print("❌ Error: $ex");
    }
  }

  // اختبار الـ Stream
  void testContactsStream() {
    try {
      final currentUserId = auth.currentUser!.uid;
      
      print("📡 Testing contacts stream...");
      print("Current User ID: $currentUserId");
      print("Path: users/$currentUserId/contacts/");
      
      db
          .collection("users")
          .doc(currentUserId)
          .collection("contacts")
          .snapshots()
          .listen((snapshot) {
        print("📥 Stream update: ${snapshot.docs.length} contacts");
        
        for (var doc in snapshot.docs) {
          print("  - ${doc.id}: ${doc.data()['name']}");
        }
      }, onError: (error) {
        print("❌ Stream error: $error");
      });
      
    } catch (ex) {
      print("❌ Error: $ex");
    }
  }

  // تشغيل كل الاختبارات
  Future<void> runAllTests() async {
    print("🧪 Starting Firebase tests...\n");
    
    await testSaveContact();
    print("\n");
    
    await Future.delayed(Duration(seconds: 1));
    await testReadContacts();
    print("\n");
    
    await Future.delayed(Duration(seconds: 1));
    testContactsStream();
    print("\n");
    
    await Future.delayed(Duration(seconds: 2));
    await testDeleteContact();
    print("\n");
    
    await Future.delayed(Duration(seconds: 1));
    await testReadContacts();
    
    print("\n✅ All tests completed!");
  }
}

// استخدام:
// final tester = FirestoreTest();
// await tester.runAllTests();
