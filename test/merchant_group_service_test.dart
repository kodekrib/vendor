import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendor/services/api_client.dart';
import 'package:vendor/services/merchant_group_service.dart';

void main() {
  test('A missing onboarder route uses the existing shared catalog', () async {
    final paths = <String>[];
    final service = MerchantGroupService(
        api: ApiClient(
            baseUrl: 'https://example.test',
            httpClient: MockClient((request) async {
              paths.add(request.url.path);
              if (paths.length == 1) {
                expect(request.headers['Authorization'], 'Bearer agent-token');
                return http.Response('Not Found', 404);
              }
              expect(request.headers['Authorization'], isNull);
              return http.Response(
                  jsonEncode({
                    'groups': [
                      {
                        'slug': 'restaurants',
                        'name': 'Restaurants',
                        'service_only': false
                      },
                      {
                        'slug': 'custom-admin-group',
                        'name': 'Admin group',
                        'service_only': false
                      },
                      {
                        'slug': 'packages',
                        'name': 'Packages',
                        'service_only': true
                      },
                    ]
                  }),
                  200);
            })));
    final groups = await service.load('agent-token');
    expect(paths, [
      '/api/v1/onboarder/merchant-groups',
      '/api/v1/customer/merchant-groups'
    ]);
    expect(groups.map((group) => group['slug']),
        ['restaurants', 'custom-admin-group']);
  });

  test('The current onboarder route is used without a fallback', () async {
    var calls = 0;
    final service = MerchantGroupService(
        api: ApiClient(httpClient: MockClient((request) async {
      calls++;
      return http.Response(
          jsonEncode({
            'groups': [
              {'slug': 'shops', 'name': 'Shops', 'service_only': false}
            ]
          }),
          200);
    })));
    expect((await service.load('token')).single['slug'], 'shops');
    expect(calls, 1);
  });

  for (final status in [401, 403, 500]) {
    test('HTTP $status is surfaced without a fallback', () async {
      var calls = 0;
      final service =
          MerchantGroupService(api: ApiClient(httpClient: MockClient((_) async {
        calls++;
        return http.Response('{}', status);
      })));
      await expectLater(service.load('token'), throwsA(isA<ApiException>()));
      expect(calls, 1);
    });
  }

  test('Missing both routes gives an actionable API update message', () async {
    final service = MerchantGroupService(
        api: ApiClient(
            httpClient: MockClient((_) async => http.Response('{}', 404))));
    await expectLater(
        service.load('token'),
        throwsA(isA<ApiException>().having((error) => error.message, 'message',
            contains('Update the API server'))));
  });
}
