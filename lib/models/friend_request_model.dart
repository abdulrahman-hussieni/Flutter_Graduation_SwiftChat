// filepath: lib/models/friend_request_model.dart
// Simple model to represent a friend request document stored under: /users/{receiverId}/friend_requests/{requesterId}
class FriendRequestModel {
  final String requesterId; // user who sent the request
  final String receiverId; // user who receives the request (owner of subcollection)
  final String status; // pending | accepted | rejected
  final String timestamp; // ISO string
  final String? requesterName;
  final String? requesterImage;

  FriendRequestModel({
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.timestamp,
    this.requesterName,
    this.requesterImage,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requesterId: json['requesterId'],
      receiverId: json['receiverId'],
      status: json['status'],
      timestamp: json['timestamp'] ?? '',
      requesterName: json['requesterName'],
      requesterImage: json['requesterImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status,
      'timestamp': timestamp,
      'requesterName': requesterName,
      'requesterImage': requesterImage,
    };
  }
}

