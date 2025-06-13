import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'main_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    print('LoadingScreen initState 호출');
    // 약간의 지연 후 인증 상태 확인
    Future.delayed(Duration.zero, () {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    print('인증 상태 확인 시작');
    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Firebase 인증 상태 강제 새로고침
      await FirebaseAuth.instance.currentUser?.reload();

      final user = FirebaseAuth.instance.currentUser;
      print('현재 사용자: ${user?.email ?? "없음"}');

      if (!mounted) return;

      // 사용자가 없으면 로그인 페이지로, 있으면 메인 페이지로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              user == null ? const LoginPage() : const MainPage(),
        ),
      );
    } catch (e) {
      print('인증 상태 확인 오류: $e');
      // 오류 발생시 로그인 페이지로
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TICKTRIP',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
