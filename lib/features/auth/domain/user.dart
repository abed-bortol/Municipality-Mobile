import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Roles from the website's `USER_ROLES` (APIConst.ts).
@JsonEnum(alwaysCreate: true)
enum UserRole {
  @JsonValue('CITIZEN')
  citizen,
  @JsonValue('HEALTH_OFFICER')
  healthOfficer,
  @JsonValue('ADMINISTRATOR')
  administrator;

  String get apiValue => _$UserRoleEnumMap[this]!;
}

/// Signed-in user, normalized like `toUser()` in the website's
/// `utils/normalize.ts`. Reads server documents (`_id`, `avatar`) as well
/// as its own [toJson] output (stored session).
@freezed
abstract class User with _$User {
  const factory User({
    @JsonKey(readValue: _readId) required String id,
    @Default('') String name,
    @Default('') String email,
    @JsonKey(unknownEnumValue: UserRole.citizen)
    @Default(UserRole.citizen)
    UserRole role,
    @Default('') String phone,
    @JsonKey(readValue: _readNonEmpty) @Default('Al-Tal') String district,
    @JsonKey(readValue: _readNonEmpty) String? badgeNumber,
    @JsonKey(readValue: _readNonEmpty) String? title,
    @JsonKey(readValue: _readAvatar) String? avatarUrl,
    @JsonKey(readValue: _readNonEmpty) String? bio,
    bool? isActive,
    DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

Object? _readId(Map<dynamic, dynamic> json, String key) =>
    (json['_id'] ?? json['id'] ?? '').toString();

Object? _readNonEmpty(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  return value is String && value.isEmpty ? null : value;
}

Object? _readAvatar(Map<dynamic, dynamic> json, String key) =>
    _readNonEmpty(json, 'avatar') ?? _readNonEmpty(json, 'avatarUrl');
