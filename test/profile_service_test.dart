import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendor/services/api_client.dart';
import 'package:vendor/services/profile_service.dart';

void main() {
  test('Profile loads shared identity and saves only editable fields',
      () async {
    final api = ApiClient(
        baseUrl: 'http://localhost',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/onboarder/profile');
          expect(request.headers['Authorization'], 'Bearer agent-token');
          if (request.method == 'PUT') {
            expect(jsonDecode(request.body), {
              'name': 'Updated Agent',
              'email': 'agent@example.test',
              'bio': 'Lagos'
            });
          }
          return http.Response(
              jsonEncode({
                'profile': {
                  'name': 'Updated Agent',
                  'email': 'agent@example.test',
                  'phone': '+2348031234567',
                  'bio': 'Lagos'
                }
              }),
              200);
        }));
    final service = ProfileService(api: api);
    final loaded = await service.load('agent-token');
    expect(loaded.value('phone'), '+2348031234567');
    final saved = await service.save('agent-token', {
      'name': ' Updated Agent ',
      'email': 'agent@example.test',
      'bio': ' Lagos ',
      'role': 'admin',
      'phone': 'unverified',
      'user_id': '999'
    });
    expect(saved.value('name'), 'Updated Agent');
  });
}
