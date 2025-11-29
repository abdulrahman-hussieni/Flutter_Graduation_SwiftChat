// filepath: lib/pages/FriendRequests/friend_requests_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/controllers/contact_controller.dart';
import 'package:graduation_swiftchat/models/friend_request_model.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestsPage extends StatelessWidget {
  FriendRequestsPage({super.key});
  final ContactController contactController = Get.put(ContactController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: StreamBuilder<List<FriendRequestModel>>(
        stream: contactController.getIncomingFriendRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (req.requesterImage != null && req.requesterImage!.startsWith('http'))
                        ? NetworkImage(req.requesterImage!)
                        : null,
                    child: (req.requesterImage == null || !req.requesterImage!.startsWith('http'))
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(req.requesterName ?? 'User'),
                  subtitle: Text('Requested ${_relativeTime(req.timestamp)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          // Load requester user doc to accept
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(req.requesterId).get();
                          if (!userDoc.exists) return;
                          final requesterModel = UserModel.fromJson(userDoc.data()!);
                          await contactController.acceptFriendRequest(requesterModel);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await contactController.rejectFriendRequest(req.requesterId);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

