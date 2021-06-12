# App HTTP Client

![Coverage][coverage-badge]

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
We plan on reusing this project, so let's make a separate package for it. This is pretty elementary, so we don't need to create a flutter app—just a dart package. We'll call it `app_http_client` so we can use it in our apps, but you can call yours whatever you want ;)

```sh
dart create --template package-simple app_http_client
cd app_http_client
git init
# Open VS Code from the Terminal, if you've installed the VS Code Shell Extensions:
code . 
```

To run tests with coverage, you'll need to do a few things.

Right now, you just need to add the following to the `.gitignore` file:

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
  very_good_analysis: ^2.1.1
```

Make sure you've removed the `pedantic` development dependency from `pubspec.yaml` that Dart automatically adds when you create a new project.

Replace the contents of `analysis_options` with the following:

```
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







---

## Usage

A simple usage example:

```dart
import 'package:app_http_client/app_http_client.dart';

main() {
  var awesome = new Awesome();
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[coverage-badge]: coverage_badge.svg
[tracker]: http://example.com/issues/replaceme
[dio]: https://pub.dev/packages/dio
[bloc]: https://pub.dev/packages/flutter_bloc
[very-good-analysis]: https://pub.dev/packages/very_good_analysis
[mocktail]: https://pub.dev/packages/mocktail
[mockito]: https://pub.dev/packages/mockito
[test-coverage]: https://pub.dev/packages/test_coverage
