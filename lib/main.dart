import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'package:last3/screens/authentication/login_screen.dart';  // 실제 경로로 수정
import 'package:last3/screens/authentication/signup_screen.dart';
import 'package:last3/screens/start_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:last3/screens/closet_main_screen.dart';
import 'package:last3/screens/home/child_register_screen.dart';
import 'package:last3/screens/home/home_screen.dart';
import 'package:last3/screens/my_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: 'f4bd39482f6c679992c8be8837224f51',
  );

  // Firebase 인증 상태 확인
  final user = FirebaseAuth.instance.currentUser;

  // 인증 상태에 따라 초기 화면 결정
  String initialRoute = (user == null) ? '/start' : '/home';

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Our Kids Closet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(path: '/start',
              builder: (context, state) => StartScreen()),
          GoRoute(path: '/login',
              builder: (context, state) => LoginScreen()),
          GoRoute(path: '/signup',
              builder: (context, state) => SignupScreen()),
          GoRoute(path: '/main',
              builder: (context, state) => MainScreen()),
          GoRoute(path: '/home',
              builder: (context, state) => HomeScreen()),
          GoRoute(path: '/register',
              builder: (context, state) => RegisterScreen()),
          GoRoute(path: '/mypage',
              builder: (context, state) => MyPage()),
        ],
      ),
    );
  }
}
