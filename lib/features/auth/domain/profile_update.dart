import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_update.freezed.dart';
part 'profile_update.g.dart';

/// Body of `PUT /users/me` (website UserProfileModal). The email is the
/// login and can't be changed; an empty [avatarUrl] clears the picture.
@Freezed(fromJson: false, toJson: true)
abstract class ProfileUpdate with _$ProfileUpdate {
  const factory ProfileUpdate({
    required String name,
    @Default('') String phone,
    required String district,
    @Default('') String title,
    @Default('') String bio,
    @Default('') String avatarUrl,
  }) = _ProfileUpdate;
}
