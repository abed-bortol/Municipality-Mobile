import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/categories/domain/hazard_category.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categories_repository.g.dart';

@Riverpod(keepAlive: true)
CategoriesRepository categoriesRepository(Ref ref) =>
    CategoriesRepository(ref.watch(dioProvider));

/// Active categories, used by the report form and filters. Cached for the
/// session; invalidate after an admin edits categories.
@Riverpod(keepAlive: true)
Future<List<HazardCategory>> activeCategories(Ref ref) =>
    ref.watch(categoriesRepositoryProvider).getCategories();

/// `/api/categories` (server/src/routes/category.routes.js).
class CategoriesRepository {
  CategoriesRepository(this._dio);

  final Dio _dio;

  /// Administrators can pass [includeInactive] to also get disabled ones.
  Future<List<HazardCategory>> getCategories({bool includeInactive = false}) =>
      apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/categories',
          queryParameters: includeInactive ? {'all': 'true'} : null,
        );
        return jsonList(res.data, 'categories')
            .map(HazardCategory.fromJson)
            .toList();
      });

  Future<HazardCategory> createCategory({
    required String name,
    required double baseWeight,
    String? description,
    String? icon,
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/categories', data: {
          'name': name,
          'baseWeight': baseWeight,
          'description': ?description,
          'icon': ?icon,
        });
        return HazardCategory.fromJson(jsonObject(res.data, 'category'));
      });

  Future<HazardCategory> updateCategory(
    String id, {
    double? baseWeight,
    String? description,
    String? icon,
    bool? isActive,
  }) =>
      apiCall(() async {
        final res =
            await _dio.put<Map<String, dynamic>>('/categories/$id', data: {
          'baseWeight': ?baseWeight,
          'description': ?description,
          'icon': ?icon,
          'isActive': ?isActive,
        });
        return HazardCategory.fromJson(jsonObject(res.data, 'category'));
      });
}
