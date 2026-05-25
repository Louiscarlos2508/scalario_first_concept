import 'package:scalario/core/sync/sync_api_client.dart';

class FakeSyncApiClient extends SyncApiClient {
  FakeSyncApiClient()
      : super(
          baseUrl: 'http://test.local',
          tokenProvider: () async => 'test-token',
        );

  BatchSyncResponse? response;
  Object? shouldThrow;
  List<SyncMutationPayload> receivedMutations = [];

  @override
  Future<BatchSyncResponse> postMutations({
    required String tenantSlug,
    required List<SyncMutationPayload> mutations,
  }) async {
    receivedMutations = List<SyncMutationPayload>.from(mutations);

    if (shouldThrow != null) {
      throw shouldThrow!;
    }

    return response ?? BatchSyncResponse(results: []);
  }
}
