import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [DancesClient].
class DancesDataSource {
  DancesDataSource(this._client);

  final RestClient _client;

  Future<List<DanceResponse>> listDances() async {
    try {
      return await _client.dances.listDancesApiV1DancesGet();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
