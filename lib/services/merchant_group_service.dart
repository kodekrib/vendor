import 'api_client.dart';

class MerchantGroupService {
  MerchantGroupService({required this.api});
  final ApiClient api;

  Future<List<Map<String, dynamic>>> load(String token) async {
    Map<String, dynamic> data;
    try {
      data = await api.get('/api/v1/onboarder/merchant-groups',
          headers: {'Authorization': 'Bearer $token'});
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      // Older API builds expose the same admin-managed catalog through the
      // public customer route. Only a missing route triggers this fallback.
      try {
        data = await api.get('/api/v1/customer/merchant-groups');
      } on ApiException catch (fallbackError) {
        if (fallbackError.statusCode != 404) rethrow;
        throw const ApiException(
            'Merchant groups are unavailable on this API version. Update the API server and retry.',
            statusCode: 404);
      }
    }
    final raw = data['groups'];
    if (raw is! List) {
      throw const ApiException('Could not read merchant groups. Please retry.');
    }
    final groups = raw.whereType<Map<String, dynamic>>().where((group) {
      return group['service_only'] != true &&
          group['slug'] is String &&
          (group['slug'] as String).isNotEmpty &&
          group['name'] is String &&
          (group['name'] as String).isNotEmpty;
    }).toList();
    if (groups.isEmpty) {
      throw const ApiException(
          'No merchant groups are available. Contact admin.');
    }
    return groups;
  }
}
