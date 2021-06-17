# App HTTP Client

![Coverage][coverage-badge] [![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

App HTTP Client is a wrapper around the HTTP library Dio to make network requests and error handling simpler, more predictable, and less verbose. 

## Tutorial

_Note: This tutorial is the first of a multipart series where we craft an auth-enabled app that provides both anonymous and authenticated user flows while storing data in the cloud. The author makes her best attempt to provide insight into best practices whenever and wherever possible._

Ever wondered how to build a simple HTTP client for your Flutter application? In this tutorial, we'll create a wrapper around the multi-platform http library [Dio][dio], which supports interceptors, global configuration, form data, request cancellation, file downloading, and timeouts—just about everything you'll ever need.

### Why?

Why create an http client wrapper? The answer is essentially "to make error handling easy and predictable." A typical state-driven application benefits from a clearly defined, finite set of errors.

As part of this app development series, we will leverage this client in a later tutorial to build our application service layer, domain layer, and state management—all of which will benefit from the error resolution this wrapper will provide.

By carefully catching Dio errors and transforming them into simple errors that our application cares about, we can drastically simplify error handling in our application state—and, as you know, simple code is easier to test. Since we use [Bloc][bloc] for our state management, we will construct our wrapper in such a way that makes error handling inside our blocs painless.

Even if you're taking a different approach, we hope you will find the organizational techniques presented here useful for your application, regardless of the http library and state management framework you are using.

### Create a Dart Package
We plan on reusing this http client wrapper, so let's make it a package. All we need to do is create a Dart package (not a Flutter one). We'll call it `app_http_client` so we can use it in our apps, but you can call yours whatever you want. 😉 

Creating a package with Dart is fairly straightforward (once you know the required command line flags):

```sh
dart create --template package-simple app_http_client
cd app_http_client
git init
# Open VS Code from the Terminal, if you've installed the VS Code Shell Extensions:
code . 
```

To run tests with coverage, you will need to add the following to the `.gitignore` file:

```conf
# Code coverage
coverage/
test/.test_coverage.dart
```
### Dependencies

Before we start coding, let's setup our dependencies.

#### Production Dependencies

- [Dio][dio]—Since we're creating a wrapper for Dio, we'll need to include it.

#### Development Dependencies

- [test_coverage][test-coverage]—Allows us to easily gather test coverage.
- [Very Good Analysis][very-good-analysis]—we'll use these linter rules as a development dependency to keep our codebase clean and consistent looking.
- [Mocktail][mocktail]—provides null-safe mocking capabilities, inspired by [Mockito][mockito].

Let's add the dependencies to the pubspec.yaml:

```yaml
dependencies:
  dio: ^4.0.0

dev_dependencies:
  test: ^1.16.0
  test_coverage: ^0.5.0
  mocktail: ^0.1.4
  very_good_analysis: ^2.1.2
```

Make sure you've removed the `pedantic` development dependency from `pubspec.yaml` that Dart automatically adds when you create a new project.

Replace the contents of `analysis_options` with the following:

```yaml
include: package:very_good_analysis/analysis_options.yaml
```

Finally, you may want to create a `.vscode` folder in the root of the project with a `launch.json` file so that you can run tests:

```json
{
	"version": "0.2.0",
	"configurations": [
		{
			"name": "Run Tests",
			"type": "dart",
			"request": "launch",
			"program": "./test/"
		},
	]
}
```


Run the following and you've got yourself a new project:

```sh
flutter pub get
git add . # Add all files
git commit -m "Initial commit"
```

To run tests with test coverage, you can use the following:

```sh
dart run test_coverage && genhtml -o coverage coverage/lcov.info
open coverage/index.html
```

### The Problem

Imagine you have a very simple service class which fetches data from your team's backend servers, perhaps something like this:

```dart
import 'package:dio/dio.dart';

class UserService {
  UserService({required this.client});

  final Dio client;

  Future<Map<String, dynamic>?> createUser({
    required String email,
    required String password,
  }) async {
    final response = await client.post<Map<String, dynamic>>('/users', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }
}
```

While this code is simple and friendly looking, it is lacking a few critical details. Notably, there is no easy way to handle errors it throws. Catching errors inside each of the service's methods would likely result in duplicate code, and catching the errors above the service would force the abstraction layers above the service layer to handle Dio-specific errors.

Currently, any errors thrown by the http library—in this case, Dio—will propagate upwards to the function where the `UserService` is being called. Such error propagation is often intended—but what if your server produces validation errors that you want to catch? Where do you intercept those?

To complicate matters further, how do you go distinguish between expected validation errors from your server which might contain certain failing http status codes on purpose, and other failing requests—such as network errors or other runtime errors—thrown by your http client library?

Because backend error responses are often consistent across multiple API routes, the practice of always handling errors on a case-by-case basis can result in redundant code that is painful to test.

What follows is what each service method might look like if we put a `try`/`catch` clause in it. For the sake of brevity, we've omitted any custom error handling that might be necessary and left a comment and a `rethrow` statement where you might otherwise find more error handling in a real application.

```dart
  Future<Map<String, dynamic>?> createUser({
    required String email,
    required String password,
  }) async {
    try {
    final response = await client.post<Map<String, dynamic>>('/users', data: {
      'email': email,
      'password': password,
    });
    return response.data;
    } catch (e) {
      // Check which type of error e is, unwrap error response data, 
      // throw custom exceptions, etc
      rethrow;
    }
  }
```

Programmers often avoid this problem—like any other architecture problem—by introducing another abstraction layer. You may recognize this as the classic [adapter][adapter-pattern] or [decorator pattern][decorator-pattern]. 

In this case, we avoid most redundant error handling clauses in a rather elementary way by simply creating a class that wraps the http library of choice.

While it is a bit tedious, it can make error handling code much simpler and more concise. Additionally, the developers creating services which use the wrapper to make network requests don't need to remember the details of backend services which utilize common response schemas.

If we make it easy for the wrapper to handle errors with enough flexibility, we can drastically reduce the complexity of error handling for a given app. If needed, each service can utilize a different http client wrapper to provide custom error handling for groups of API requests which may have similar backend response schemas.

Hopefully, the code presented here will prevent you from having to suffer through much of the required monotony, as you may copy and paste to your liking freely under the MIT license.

### Considering Errors

To catch an error, one must understand the kinds of errors which can be caught. Let's pause for a moment and describe the errors a network application might be interested in.

At its core, our applications are interested in 3 basic kinds of errors:

- Network Errors
  - Sometimes well-formed requests fail through no fault of their own, due to extraneous network conditions, dropped packets, poor signals, busy servers, etc.

- Response Errors
  - The request was received by the server, but the server returned a bad response—presumably with an [http status code][status-codes] indicative of the problem. Validation errors, redirects, poorly formed requests, requests without proper authorization, etc, can all be responsible for rejection from the server.
  - As far as application state logic is concerned, these errors are most likely to have a practical use. Perhaps your backend form validation system relies on certain error schemas to be returned from your servers to describe invalid fields that were submitted.

- Other / Runtime Errors
  - Other errors in the http library or service layer code can cause problems—tracking these is important for developers, but as far as users are concerned, these are largely equivalent to a network error if it doesn't completely break the application.

We want errors generated by our http library to be transformed into one of these 3 types of errors. To facilitate this, we need to create 3 error classes.

For the sake of convenient error handling in our application, we consider a response error a subtype of a network error. Placing errors into the following class hierarchy should allow for greatly simplified state management:

```
   ┌──────────────────────────┐
   │  AppHttpClientException  │
   └──────────────────────────┘
                 ▲
                 │
   ┌──────────────────────────┐
   │   AppNetworkException    │
   └──────────────────────────┘
                 ▲
                 │
 ┌───────────────────────────────┐
 │  AppNetworkResponseException  │
 └───────────────────────────────┘
```

`AppHttpClientException` is the base class. For any error generated by our wrapper, the expression `(error is AppHttpClientException)` should always be `true`.

Let's take a look at the implementation:

```dart
class AppHttpClientException<OriginalException extends Exception>
    implements Exception {
  AppHttpClientException({required this.exception});
  final OriginalException exception;
}
```

Pretty straightforward—we require the original exception in the constructor of `AppHttpClientException` so that developers are able to easily debug errors specific to the http library being used.

Additionally, developers writing app-specific subclasses of `AppHttpClientException` can pass other exceptions in which further represent the type of error, if needed.

We can describe the network exception just as simply:

```dart
enum AppNetworkExceptionReason {
  canceled,
  timedOut,
  responseError
}

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
```

Finally, we can create a class for network response errors:

```dart
class AppNetworkResponseException<OriginalException extends Exception, DataType>
    extends AppNetworkException<OriginalException> {
  AppNetworkResponseException({
    required OriginalException exception,
    this.statusCode,
    this.data,
  }) : super(
          reason: AppNetworkExceptionReason.responseError,
          exception: exception,
        );

  final DataType? data;
  final int? statusCode;
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
```

Developers are encouraged to subclass `AppNetworkResponseException` for app-specific response errors. More on that later.

Now that our basic error hierarchy is in place, it's time to create the http client wrapper class.

### Creating the HTTP Client Wrapper

We want our wrapper to receive a pre-configured Dio instance so that the code instantiating the wrapper has full control over network requests. By injecting a Dio instance into our wrapper, it encourages developers to take advantage of everything Dio has to offer—like request interceptors.

Our wrapper should provide a method for each http request method like `GET`, `POST`, `PUT`, `PATCH`, etc. These methods should pass their parameters through to the Dio instance and perform relevant error handling by catching errors in a uniform way.

_Note: Dio exposes a lot of methods, but we are only interested in wrapping the methods that use a `String` path as opposed to a `Uri`, which seems overly complex in this scenario._

Let's make a class that meets our criteria:

```dart
/// A callback that returns a Dio response, presumably from a Dio method
/// it has called which performs an HTTP request, such as `dio.get()`,
/// `dio.post()`, etc.
typedef HttpLibraryMethod<T> = Future<Response<T>> Function();

/// Function which takes a Dio response object and optionally maps it to an
/// instance of [AppHttpClientException].
typedef ResponseExceptionMapper = AppNetworkResponseException? Function<T>(
  Response<T>,
  Exception,
);

class AppHttpClient {
  AppHttpClient({required Dio client, this.exceptionMapper}) : _client = client;

  final Dio _client;

  final ResponseExceptionMapper? exceptionMapper;

    /// HTTP GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _mapException(
      () => _client.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  // ...
  // 
  // see repository for full implementation
  // 
  // ...

  Future<Response<T>> _mapException<T>(HttpLibraryMethod<T> method) async {
    try {
      return await method();
    } on DioError catch (exception) {
      switch (exception.type) {
        case DioErrorType.cancel:
          throw AppNetworkException(
            reason: AppNetworkExceptionReason.canceled,
            exception: exception,
          );
        case DioErrorType.connectTimeout:
        case DioErrorType.receiveTimeout:
        case DioErrorType.sendTimeout:
          throw AppNetworkException(
            reason: AppNetworkExceptionReason.timedOut,
            exception: exception,
          );
        case DioErrorType.response:
          // For DioErrorType.response, we are guaranteed to have a
          // response object present on the exception.
          final response = exception.response;
          if (response == null || response is! Response<T>) {
            // This should never happen, judging by the current source code
            // for Dio.
            throw AppNetworkResponseException(exception: exception);
          }
          throw exceptionMapper?.call(response, exception) ??
              AppNetworkResponseException(
                exception: exception,
                statusCode: response.statusCode,
                data: response.data,
              );
        case DioErrorType.other:
        default:
          throw AppHttpClientException(exception: exception);
      }
    } catch (e) {
      throw AppHttpClientException(
        exception: e is Exception ? e : Exception('Unknown exception ocurred'),
      );
    }
  }
}
```

### The Error Handling Mechanism

The real meat-and-potatoes of our wrapper is hiding in the private method `_mapException()`. It takes one parameter named `method` which is a callback (that should call a Dio method).

The `_mapException` proceeds to return the awaited callback's result via `return await method();`, catching any errors in the process. If no errors occur, it just returns whatever the callback returned (which in this case will be the response object returned by the Dio method that the callback called).

If an error occurs, things get much more interesting. The error handling that takes place inside the wrapper is dependent on your http library of choice. Since we're using Dio, we know that Dio already wraps all of its errors into `DioError` objects.

Dio's errors are perfectly decent, but we don't want the error handling our app's codebase to be directly tied to any particular http library. If you need to change the http library you're using, it's much easier to write another wrapper class which satisfies a similar interface than it is to hunt for http-library-specific error handling throughout the app's code.

_Note: There is one caveat—because our methods directly wrap Dio's methods, the parameters have types which are only found inside the Dio library, such as `Options`, `CancelToken`, `ProgressCallback`, etc. Our app's service code which calls our wrapper will still be tied to Dio when it passes in these objects, but changing such details strictly within the service layer should be fairly straightforward in the event of swapping over to another wrapper and http library._

_We could have stopped and written a platform-agnostic http request interface library, but the payoff for doing so would be minimal compared to the enormous effort required. While it would spare you from having to touch any service code at all if you suddenly switched http libraries, swapping dependencies like that just doesn't seem like a frequent enough occurrence to merit an entire library of carefully constructed interfaces. You'd also have to create and maintain the mappings from the platform-agnostic classes to the platform specific ones for every http library you intended to support..._

The rest of `_mapException` proceeds to map each type of Dio error into one of the 3 types of errors we care about. Everything is fairly straightforward, with the exception of response errors.

Our wrapper would not be very useful if that was all it did. The main reason we created the wrapper is to allow the code using the wrapper to provide custom response error handling. The `_mapException` method uses some optional chaining and null coalescing operators to delegate any Dio response error containing a valid response object (with the expected response type) to an optional mapping function—if such a callback is provided in the wrapper's constructor: `ResponseExceptionMapper? exceptionMapper`.

The `exceptionMapper` function receives two arguments: the first is the Dio response object of type `Response<T>` (where `T` is the type of data passed into the wrapper, usually `Map<String, dynamic>` for JSON) and the second is the original exception which was caught.

In case you weren't sure, you can specify the type of the type of the data you expect Dio to return by passing in the expected type when you call our wrapper's generic delegate methods:

```dart
// Perform a GET request with a JSON return type: Map<String, dynamic>
final response = appHttpClient.get<Map<String, dynamic>>('url');
```

The following are some of the response types Dio supports:

```dart
client.get<Map<String, dynamic>>() // JSON data
client.get<String>()               // Plain text data
client.get<ResponseBody>()         // Response stream
client.get<List<int>>()            // Raw binary data (as list of bytes)
```

You can implement the `exceptionMapper` function however you like. If you don't know what to do with the Dio response, simply return `null` to let `AppHttpClient` wrap the response error using the default error handling logic. If your `exceptionMapper` function is able to recognize a certain kind of response, it is welcome to return an instance or subclass of `AppNetworkResponseException` which better represents the error.

In the next section, we will construct an example `exceptionMapper` which unwraps a certain kind of backend error it receives.

### Handling the Errors

Imagine you've defined the following service which calls your internet-of-things-enabled teapot and tells it to brew `coffee` erroneously:

```dart
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
```

Because you've made the wrong request, the teapot should respond back with a [418 I'm a Teapot][teapot-error] error. Perhaps it even replies with json data in its response body:

```json
{
  "message": "I can't brew 'coffee'"
}
```

Let's pretend, while we're at it, that you want to catch these specific errors and wrap them in an error class, preserving the server's error message so that you can show it to the user of your remote tea-brewing app.

This is all you have to do:

```dart
class TeapotResponseException extends AppNetworkResponseException {
  TeapotResponseException({
    required String message,
  }) : super(exception: Exception(message));
}

final client = AppHttpClient(
  client: Dio(),
  exceptionMapper: <T>(Response<T> response) {
    final data = response.data;
    if (data != null && data is Map<String, dynamic>) {
      // We only map responses containing data with a status code of 418:
      return TeapotResponseException(
        message: data['message'] ?? 'I\'m a teapot',
      );
    }
    return null;
  },
);
```

_Note: Because [Dart generic types are reified][reified-types], you can check the type of the response data inside the `exceptionMapper` function._

To use your service and consume teapot errors, this is all you need to do:

```dart
final teaService = TeaService(client: client);

try {
  await teaService.brewTea();
} on TeapotResponseException catch (teapot) {
  print(teapot.exception.toString()); 
} catch (e) {
  print('Some other error');
}
```

Note that you can access the error's data since you created a custom `TeapotResponseException` class. On top of that, it integrates seamlessly with [Dart's try/catch clauses][catch-error]. The `try`/`catch` clauses Dart provides out of the box are incredibly useful for catching specific types of errors—exactly what our wrapper helps us with!  

So that's pretty much it—I like to think it's worth the hassle of creating a custom http client wrapper. 😜

### Testing

A wrapper whose sole job is to wrap errors would be completely useless if there were mistakes in its code which caused it to throw errors that didn't get wrapped. Whew, that was a mouthful. We can prevent just such a catastrophe by keeping the wrapper code as simple as possible and testing all of its functionality.

To prevent such a catastrophe, I have tried to reduce the wrapper's code as much as possible and have tested it to the best of my ability. Because of the code's simplicity, you can [check the tests here](/test) to ensure that you are satisfied with its functionality.

### About

Thank you for reading this tutorial! If you have anything you'd like to share, feel free to make a pull request or file an issue.

You can find the fully tested and documented version of the Dio wrapper here in this repository for your convenience.

Looking to make an app? Perhaps you'd like to get in touch with the [leading Flutter app development and consultancy company][vgv].

[coverage-badge]: coverage_badge.svg
[dio]: https://pub.dev/packages/dio
[bloc]: https://pub.dev/packages/flutter_bloc
[very-good-analysis]: https://pub.dev/packages/very_good_analysis
[mocktail]: https://pub.dev/packages/mocktail
[mockito]: https://pub.dev/packages/mockito
[test-coverage]: https://pub.dev/packages/test_coverage
[adapter-pattern]: https://en.wikipedia.org/wiki/Adapter_pattern
[decorator-pattern]: https://en.wikipedia.org/wiki/Decorator_pattern
[status-codes]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
[vgv]: https://verygood.ventures/
[teapot-error]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/418
[reified-types]: https://itnext.io/flutter-methodchannel-dart-generic-and-type-casting-54ca48e6d3ad
[catch-error]: https://dart.dev/guides/language/language-tour#catch
