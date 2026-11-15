import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_request.freezed.dart';
part 'register_request.g.dart';

/// Body of `POST /auth/register` (the server always creates a CITIZEN).
@Freezed(fromJson: false, toJson: true)
abstract class RegisterRequest with _$RegisterRequest {
  @JsonSerializable(includeIfNull: false)
  const factory RegisterRequest({
    required String name,
    required String email,
    required String password,
    @Default('') String phone,
    String? district,
  }) = _RegisterRequest;
}
