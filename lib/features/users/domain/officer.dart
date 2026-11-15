import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/utils/json_readers.dart';

part 'officer.freezed.dart';
part 'officer.g.dart';

/// Active health officer, as listed by `GET /users/officers`.
@freezed
abstract class Officer with _$Officer {
  const factory Officer({
    @JsonKey(readValue: readId) required String id,
    @Default('') String name,
    @Default('') String badgeNumber,
    @Default('') String district,
    @JsonKey(readValue: readNonEmpty) String? title,
  }) = _Officer;

  factory Officer.fromJson(Map<String, dynamic> json) =>
      _$OfficerFromJson(json);
}
