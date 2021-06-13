import 'package:app_http_client/app_http_client.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDio extends Mock implements Dio {}

class MockDioOptions extends Mock implements Options {}

class MockDioCancelToken extends Mock implements CancelToken {}

class MockDioResponse<T> extends Mock implements Response<T> {}

class MockDioError extends Mock implements DioError {}

void main() {
  group('AppHttpClient', () {
    late AppHttpClient client;
    late Dio dio;
    late Options options;
    late CancelToken cancelToken;
    const path = 'https://test.com/';
    const data = <String, dynamic>{};

    late ProgressCallback onSendProgress;
    late ProgressCallback onReceiveProgress;

    setUp(() {
      // Additional setup goes here.
      dio = MockDio();
      options = MockDioOptions();
      cancelToken = MockDioCancelToken();
      onSendProgress = (_, __) {};
      onReceiveProgress = (_, __) {};
      client = AppHttpClient(client: dio);
    });

    test('instantiates', () {
      expect(client, isA<AppHttpClient>());
    });

    group('http method wrappers', () {
      test('Passes parameters for http GET', () async {
        when(
          () => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          ),
        ).thenAnswer((_) async => MockDioResponse());
        await client.get(
          path,
          queryParameters: data,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
        verify(
          () => dio.get(
            path,
            queryParameters: data,
            options: options,
            cancelToken: cancelToken,
            onReceiveProgress: onReceiveProgress,
          ),
        );
      });

      test('Passes parameters for http POST', () async {
        when(
          () => dio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          ),
        ).thenAnswer((_) async => MockDioResponse());
        await client.post(
          path,
          data: data,
          queryParameters: data,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
        verify(
          () => dio.post(
            path,
            data: data,
            queryParameters: data,
            options: options,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          ),
        );
      });

      test('Passes parameters for http PUT', () async {
        when(
          () => dio.put(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          ),
        ).thenAnswer((_) async => MockDioResponse());
        await client.put(
          path,
          data: data,
          queryParameters: data,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
        verify(
          () => dio.put(
            path,
            data: data,
            queryParameters: data,
            options: options,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          ),
        );
      });

      test('Passes parameters for http HEAD', () async {
        when(
          () => dio.head(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => MockDioResponse());
        await client.head(
          path,
          data: data,
          queryParameters: data,
          options: options,
          cancelToken: cancelToken,
        );
        verify(
          () => dio.head(
            path,
            data: data,
            queryParameters: data,
            options: options,
            cancelToken: cancelToken,
          ),
        );
      });

      test('Passes parameters for http DELETE', () async {
        when(
          () => dio.delete(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => MockDioResponse());
        await client.delete(
          path,
          data: data,
          queryParameters: data,
          options: options,
          cancelToken: cancelToken,
        );
        verify(
          () => dio.delete(
            path,
            data: data,
            queryParameters: data,
            options: options,
            cancelToken: cancelToken,
          ),
        );
      });

      test('Passes parameters for http PATCH', () async {
        when(
          () => dio.patch(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          ),
        ).thenAnswer((_) async => MockDioResponse());
        await client.patch(
          path,
          data: data,
          queryParameters: data,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
        verify(
          () => dio.patch(
            path,
            data: data,
            queryParameters: data,
            options: options,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          ),
        );
      });
    });

    group('basic exception mapping', () {
      test('wraps unrecognized exceptions', () async {
        when(() => dio.get(any())).thenThrow(Exception());

        expect(
          () async => await client.get(path),
          throwsA(isA<AppHttpClientException>()),
        );
      });

      test('wraps an unknown DioError', () async {
        final mockError = MockDioError();
        when(() => mockError.type).thenReturn(DioErrorType.other);
        when(() => dio.get(any())).thenThrow(mockError);

        expect(
          () async => await client.get(path),
          throwsA(isA<AppHttpClientException>()),
        );
      });

      test('wraps a cancellation DioError', () async {
        final mockError = MockDioError();
        when(() => mockError.type).thenReturn(DioErrorType.cancel);
        when(() => dio.get(any())).thenThrow(mockError);

        expect(
          () async => await client.get(path),
          throwsA(
            isA<AppNetworkException>().having(
              (e) => e.reason,
              'reason',
              equals(AppNetworkExceptionReason.canceled),
            ),
          ),
        );
      });

      test('wraps a timeout DioError', () async {
        final mockError = MockDioError();
        when(() => mockError.type).thenReturn(DioErrorType.sendTimeout);
        when(() => dio.get(any())).thenThrow(mockError);

        expect(
          () async => await client.get(path),
          throwsA(
            isA<AppNetworkException>().having(
              (e) => e.reason,
              'reason',
              equals(AppNetworkExceptionReason.timedOut),
            ),
          ),
        );
      });
    });

    group('response exception mapping', () {
      test('wraps a malformed response error', () async {
        final mockError = MockDioError();
        when(() => mockError.type).thenReturn(DioErrorType.response);
        when(() => dio.get(any())).thenThrow(mockError);

        expect(
          () async => await client.get(path),
          throwsA(
            isA<AppNetworkResponseException>()
                .having(
                  (e) => e.reason,
                  'reason',
                  equals(AppNetworkExceptionReason.responseError),
                )
                .having((e) => e.exception, 'exception', equals(mockError))
                .having((e) => e.hasData, 'hasData', isFalse)
                .having((e) => e.data, 'data', isNull)
                .having((e) => e.statusCode, 'statusCode', isNull)
                .having(
                  (e) => e.validateStatusCode((_) => true),
                  'validateStatusCode',
                  isFalse,
                ),
          ),
        );
      });

      test('wraps a malformed response error with wrong data type', () async {
        final mockError = MockDioError();
        when(() => mockError.type).thenReturn(DioErrorType.response);
        when(() => mockError.response).thenReturn(MockDioResponse<String>());
        when(() => dio.get(any())).thenThrow(mockError);

        expect(
          () async => await client.get<int>(path),
          throwsA(
            isA<AppNetworkResponseException>()
                .having(
                  (e) => e.reason,
                  'reason',
                  equals(AppNetworkExceptionReason.responseError),
                )
                .having((e) => e.exception, 'exception', equals(mockError))
                .having((e) => e.hasData, 'hasData', isFalse)
                .having((e) => e.data, 'data', isNull)
                .having((e) => e.statusCode, 'statusCode', isNull)
                .having(
                  (e) => e.validateStatusCode((_) => true),
                  'validateStatusCode',
                  isFalse,
                ),
          ),
        );
      });

      test('prioritizes custom exceptionMapper', () async {
        final underlyingException = Exception('something awful');
        client = AppHttpClient(
          client: dio,
          exceptionMapper: <T>(response, exception) {
            expect(exception, isA<Exception>());
            expect(response, isA<MockDioResponse>());
            return AppNetworkResponseException(exception: underlyingException);
          },
        );
        final mockError = MockDioError();
        final mockResponse = MockDioResponse();
        when(() => mockError.type).thenReturn(DioErrorType.response);
        when(() => mockError.response).thenReturn(mockResponse);

        when(() => dio.get(any())).thenThrow(mockError);

        expect(
          () async => await client.get(path),
          throwsA(isA<AppNetworkResponseException>()
              .having(
                (e) => e.reason,
                'reason',
                equals(AppNetworkExceptionReason.responseError),
              )
              .having(
                (e) => e.exception,
                'exception',
                equals(underlyingException),
              )),
        );
      });

      test('wraps a well-formed response error', () async {
        final mockError = MockDioError();
        final mockResponse = MockDioResponse();
        const mockData = 'mock data';
        const statusCode = 404;
        when(() => mockError.type).thenReturn(DioErrorType.response);
        when(() => mockError.response).thenReturn(mockResponse);
        when(() => mockResponse.data).thenReturn(mockData);
        when(() => mockResponse.statusCode).thenReturn(statusCode);
        when(() => dio.get(any())).thenThrow(mockError);

        expect(
          () async => await client.get(path),
          throwsA(
            isA<AppNetworkResponseException>()
                .having(
                  (e) => e.reason,
                  'reason',
                  equals(AppNetworkExceptionReason.responseError),
                )
                .having((e) => e.exception, 'exception', equals(mockError))
                .having((e) => e.hasData, 'hasData', isTrue)
                .having((e) => e.data, 'data', equals(mockData))
                .having((e) => e.statusCode, 'statusCode', equals(statusCode))
                .having(
                  (e) => e.validateStatusCode((code) => code == 404),
                  'validateStatusCode',
                  isTrue,
                ),
          ),
        );
      });
    });
  });
}
