// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
    };

InsertUser _$InsertUserFromJson(Map<String, dynamic> json) => InsertUser(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$InsertUserToJson(InsertUser instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };
