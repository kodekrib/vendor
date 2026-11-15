import 'api_client.dart';

class AgentProfile {
  const AgentProfile(this.data);
  final Map<String, dynamic> data;
  String value(String key) => data[key]?.toString() ?? '';
}

class ProfileService {
  ProfileService({ApiClient? api}) : api = api ?? ApiClient();
  final ApiClient api;

  Future<AgentProfile> load(String token) async {
    final result = await api.get('/api/v1/onboarder/profile',
        headers: {'Authorization': 'Bearer $token'});
    return AgentProfile(Map<String, dynamic>.from(result['profile'] as Map));
  }

  Future<AgentProfile> save(String token, Map<String, String> fields) async {
    const allowed = [
      'name',
      'email',
      'address',
      'bio',
      'instagram_handle',
      'twitter_handle',
      'linkedin_handle',
      'facebook_handle',
      'tiktok_handle'
    ];
    final result = await api.put('/api/v1/onboarder/profile', headers: {
      'Authorization': 'Bearer $token'
    }, body: {
      for (final key in allowed)
        if (fields.containsKey(key)) key: fields[key]!.trim()
    });
    return AgentProfile(Map<String, dynamic>.from(result['profile'] as Map));
  }
}
