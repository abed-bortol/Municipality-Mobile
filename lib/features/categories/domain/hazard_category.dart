import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/utils/json_readers.dart';

part 'hazard_category.freezed.dart';
part 'hazard_category.g.dart';

/// Health / environmental hazard category with its baseline risk weight.
@freezed
abstract class HazardCategory with _$HazardCategory {
  const factory HazardCategory({
    @JsonKey(readValue: readId) required String id,
    @Default('') String name,
    @Default('') String code,
    @Default('') String description,
    @Default(10) double baseWeight,
    @Default('AlertCircle') String icon,
    @Default(true) bool isActive,
  }) = _HazardCategory;

  factory HazardCategory.fromJson(Map<String, dynamic> json) =>
      _$HazardCategoryFromJson(json);
}
