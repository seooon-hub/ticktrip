import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ticktrip/screens/loading.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ticktrip/screens/emergencycountrylist.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SSL 인증서 검증 우회를 위한 클래스 추가
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    // 오프라인 로그인 시도
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('user_email');
    final storedToken = prefs.getString('user_token');

    if (storedEmail != null && storedToken != null) {
      try {
        // 저장된 토큰으로 Firebase 인증 시도
        await FirebaseAuth.instance.signInWithCustomToken(storedToken);
        print('오프라인 로그인 성공: $storedEmail');
      } catch (e) {
        print('오프라인 로그인 실패: $e');
      }
    }

    // 만료된 로컬 파일 정리 시도
    try {
      await LocalStorage.cleanExpiredFiles();
      print('만료된 로컬 파일 정리 완료');
    } catch (e) {
      print('로컬 파일 정리 중 오류 발생: $e');
      // 로컬 파일 정리 실패는 앱 실행에 치명적이지 않으므로 계속 진행
    }

    print('Firebase 초기화 성공');

    final user = FirebaseAuth.instance.currentUser;
    print('초기 사용자 상태: ${user?.email ?? "로그인 안됨"}');

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        print('로그인 상태: ${user.email}');
      } else {
        print('로그아웃 상태');
      }
    });

    await initializeDateFormatting('ko_KR', null);

    runApp(const MyApp());
  } catch (e) {
    print('초기화 실패: $e');
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('앱 초기화 중 오류가 발생했습니다.\n다시 시도해주세요.'),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TICKTRIP',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}
