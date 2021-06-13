/// Base exception for all exceptions thrown by AppHttpClient.
/// You can create instances of this to create "unknown" error exceptions.
///
/// ```
///   ┌──────────────────────────┐
///   │  AppHttpClientException  │
///   └──────────────────────────┘
///                 ▲
///                 │
///   ┌──────────────────────────┐
///   │   AppNetworkException    │
///   └──────────────────────────┘
///                 ▲
///                 │
/// ┌───────────────────────────────┐
/// │  AppNetworkResponseException  │
/// └───────────────────────────────┘
/// ```
class AppHttpClientException<OriginalException extends Exception>
    implements Exception {
  /// Create a new application http client exception with the specified
  /// underlying [exception].
  AppHttpClientException({required this.exception});

  /// Exception which was caught.
  final OriginalException exception;
}

/// Reason for a network exception.
enum AppNetworkExceptionReason {
  /// A request cancellation is responsible for the exception.
  canceled,

  /// A timeout error is responsible for the exception.
  timedOut,

  /// A response error is responsible for the exception.
  responseError
}

/// Network error.
class AppNetworkException<OriginalException extends Exception>
    extends AppHttpClientException<OriginalException> {
  /// Create a network exception.
  AppNetworkException({
    required this.reason,
    required OriginalException exception,
  }) : super(exception: exception);

  /// The reason the network exception ocurred.
  final AppNetworkExceptionReason reason;
}

/// Response exception.
class AppNetworkResponseException<OriginalException extends Exception, DataType>
    extends AppNetworkException<OriginalException> {
  /// Create a new response exception with the specified [statusCode],
  /// original [exception], and response [data].
  AppNetworkResponseException({
    required OriginalException exception,
    this.statusCode,
    this.data,
  }) : super(
          reason: AppNetworkExceptionReason.responseError,
          exception: exception,
        );

  /// Response data, if any.
  final DataType? data;

  /// HTTP status code, if any.
  final int? statusCode;

  /// True if the response contains data.
  bool get hasData => data != null;

  /// If the status code is null, returns false. Otherwise, allows the
  /// given closure [evaluator] to validate the given http integer status code.
  ///
  /// Usage:
  /// ```
  /// final isValid = responseException.validateStatusCode(
  ///   (statusCode) => statusCode >= 200 && statusCode < 300,
  /// );
  /// ```
  bool validateStatusCode(bool Function(int statusCode) evaluator) {
    final statusCode = this.statusCode;
    if (statusCode == null) return false;
    return evaluator(statusCode);
  }
}
