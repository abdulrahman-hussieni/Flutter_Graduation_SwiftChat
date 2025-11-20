// ignore_for_file: no_leading_underscores_for_local_identifiers

class UserModel {
  String? id;
  String? name;
  String? email;
  String? profileImage;
  String? phoneNumber;
  String? about;
  String? createdAt;
  String? lastOnlineStatus;
  String? status;
  String? role;
  String? gender;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.profileImage,
    this.phoneNumber,
    this.about,
    this.createdAt,
    this.lastOnlineStatus,
    this.status,
    this.role,
    this.gender,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    email = json["email"];
    profileImage = json["profileImage"];
    phoneNumber = json["phoneNumber"];
    about = json["About"];
    createdAt = json["CreatedAt"];
    lastOnlineStatus = json["LastOnlineStatus"];
    status = json["Status"];
    role = json["role"];
    gender = json["gender"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["name"] = name;
    _data["email"] = email;
    _data["profileImage"] = profileImage;
    _data["phoneNumber"] = phoneNumber;
    _data["About"] = about;
    _data["CreatedAt"] = createdAt;
    _data["LastOnlineStatus"] = lastOnlineStatus;
    _data["Status"] = status;
    _data["role"] = role;
    _data["gender"] = gender;
    return _data;
  }
}
