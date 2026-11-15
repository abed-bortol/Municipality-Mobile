import 'package:municipality/features/categories/data/categories_repository.dart';
import 'package:municipality/features/categories/domain/hazard_category.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categories_admin_providers.g.dart';

/// Every category, including disabled ones (administrators only).
@riverpod
Future<List<HazardCategory>> allCategories(Ref ref) => ref
    .watch(categoriesRepositoryProvider)
    .getCategories(includeInactive: true);

/// Server weight bounds (Category model: min 1, max 25).
const minCategoryWeight = 1;
const maxCategoryWeight = 25;

/// Website "Algorithm Impact" tiers.
enum WeightTier {
  high,
  standard,
  normal;

  static WeightTier of(num weight) => weight >= 14
      ? high
      : weight >= 10
      ? standard
      : normal;
}

/// Category changes. All throw `ApiException`; on success both the admin
/// list and the report form's categories are refreshed.
@Riverpod(keepAlive: true)
class CategoryAdminActions extends _$CategoryAdminActions {
  @override
  void build() {}

  Future<HazardCategory> create({
    required String name,
    required int baseWeight,
    String description = '',
  }) => _run(
    () => ref
        .read(categoriesRepositoryProvider)
        .createCategory(
          name: name.trim(),
          baseWeight: baseWeight
              .clamp(minCategoryWeight, maxCategoryWeight)
              .toDouble(),
          description: description.trim(),
          icon: 'AlertCircle',
        ),
  );

  Future<HazardCategory> setWeight(HazardCategory category, int weight) => _run(
    () => ref
        .read(categoriesRepositoryProvider)
        .updateCategory(
          category.id,
          baseWeight: weight
              .clamp(minCategoryWeight, maxCategoryWeight)
              .toDouble(),
        ),
  );

  Future<HazardCategory> setActive(HazardCategory category, bool active) =>
      _run(
        () => ref
            .read(categoriesRepositoryProvider)
            .updateCategory(category.id, isActive: active),
      );

  Future<HazardCategory> _run(Future<HazardCategory> Function() call) async {
    final category = await call();
    ref
      ..invalidate(allCategoriesProvider)
      ..invalidate(activeCategoriesProvider);
    return category;
  }
}
