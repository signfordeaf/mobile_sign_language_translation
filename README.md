<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# SignForDeaf Mobile Sign Language

## 🧑🏻💻 Usage

###  📄main.dart
   Wrap your MaterialApp with the SignForDeaf widget and enter the required information
```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SignForDeaf(
      requestKey: 'YOUR_API_KEY',
      requestUrl: 'YOUR_API_URL',
      child: MaterialApp(
        title: 'Flutter App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        ...
      ),
    );
  }
}
```
![Image](https://imgur.com/JqwGw2k.png)

## ⚠️Warning
   If you use multiple other pages or alternative router structures in your application, ensure the 
   widget's build on every page by rebuilding the structure!
### Example-1 (MaterialApp.builder)
 ```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      builder: (context, child) {
        return SignForDeaf(
          requestKey: 'YOUR_API_KEY',
          requestUrl: 'YOUR_API_URL',
          child: child!,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      ...
    );
  }
}
 ```
### Example-2 (AutoRoute)
#### Route Config
```dart
@AutoRouterConfig()
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [...routesList];

  static PageRouteBuilder signForDeafBuilder(BuildContext context, Widget child,
      Page<dynamic> page, RouteTransitionsBuilder transitionsBuilder) {
    return PageRouteBuilder(
      settings: page,
      pageBuilder: (_, __, ___) {
        return SignForDeaf(
          requestKey: 'YOUR_API_KEY',
          requestUrl: 'YOUR_API_URL',
          child: child!,
        );
      },
      transitionsBuilder: transitionsBuilder,
    );
  }
}
```
#### Route List
```dart
List<AutoRoute> routesList = [
  CustomRoute(
    page: Route.page,
    customRouteBuilder: (context, child, page) => AppRouter.signForDeafBuilder(
        context, child, page, TransitionsBuilders.fadeIn),
  ),
];
```