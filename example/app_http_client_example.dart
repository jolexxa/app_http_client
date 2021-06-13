import 'package:app_http_client/app_http_client.dart';
import 'package:dio/dio.dart';

class TeaService {
  TeaService({required this.client});

  final AppHttpClient client;

  Future<Map<String, dynamic>?> brewTea() async {
    final response = await client.post<Map<String, dynamic>>(
      '/tea',
      data: {
        'brew': 'coffee',
      },
    );
    return response.data;
  }
}

class TeapotResponseException extends AppNetworkResponseException {
  TeapotResponseException({
    required this.message,
    required Exception exception,
  }) : super(exception: exception);

  final String message;
}

void main() async {
  final client = AppHttpClient(
    client: Dio(),
    exceptionMapper: <T>(Response<T> response, exception) {
      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        // We only map 418 responses that have json response data:
        return TeapotResponseException(
          message: data['message'] ?? 'I\'m a teapot',
          exception: exception,
        );
      }
      return null;
    },
  );

  final teaService = TeaService(client: client);

  try {
    await teaService.brewTea();
  } on TeapotResponseException catch (e) {
    print(e.message);
  } catch (_) {
    print('Some other error');
  }

  assert(client is AppHttpClient);
}
