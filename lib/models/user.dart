import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String username;
  
  User({
    required this.id,
    required this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() => 'User(id: $id, username: $username)';
}

@JsonSerializable()
class InsertUser {
  final String username;
  final String password;

  InsertUser({
    required this.username,
    required this.password,
  });

  factory InsertUser.fromJson(Map<String, dynamic> json) =>
      _$InsertUserFromJson(json);
  Map<String, dynamic> toJson() => _$InsertUserToJson(this);

  @override
  String toString() => 'InsertUser(username: $username)';
}
