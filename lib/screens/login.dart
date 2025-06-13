import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'signup.dart';
import 'find_password.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid',
    ],
    signInOption: SignInOption.standard,
    forceCodeForRefreshToken: true,
  );
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'CustomFont',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 2,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              hintText: 'ID',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock),
                              hintText: 'Password',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '로그인이 안되시나요?\nSNS로 간편 로그인하고 간단하게 이용해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Image.asset('assets/images/google.png'),
                          iconSize: 50,
                          onPressed: _handleGoogleSignIn,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupPage(),
                              ),
                            );
                          },
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              color: Color.fromARGB(255, 14, 27, 36),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailSignIn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // 온라인 로그인 시도
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user == null) throw Exception('로그인 실패: 사용자 정보 없음');

        // 로그인 성공 시 사용자 정보 저장 시도
        try {
          await LocalStorage.saveUserData(email, password);
        } catch (e) {
          print('사용자 정보 저장 실패 (비치명적): $e');
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
          (route) => false,
        );
        return;
      } catch (e) {
        if (e is! FirebaseAuthException || 
            !e.message!.contains('network')) {
          rethrow; // 네트워크 오류가 아닌 경우 다시 throw
        }
        print('온라인 로그인 실패, 오프라인 로그인 시도');
      }

      // 오프라인 로그인 시도
      final isValid = await LocalStorage.verifyOfflineLogin(email, password);
      if (!isValid) {
        throw Exception('오프라인 로그인 실패: 잘못된 인증 정보');
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
    } catch (e) {
      print('로그인 오류: $e');
      String message = '로그인에 실패했습니다.';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          message = '존재하지 않는 이메일입니다.';
        } else if (e.code == 'wrong-password') {
          message = '잘못된 비밀번호입니다.';
        } else if (e.code == 'invalid-email') {
          message = '유효하지 않은 이메일 형식입니다.';
        } else if (e.message?.contains('network') ?? false) {
          message = '네트워크 연결을 확인해주세요.';
        }
      } else if (e.toString().contains('오프라인 로그인 실패')) {
        message = '오프라인 로그인 실패: 저장된 정보와 일치하지 않습니다.';
      }
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 기존 세션 클리어
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      
      print('2. 구글 로그인 시도...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('- 구글 로그인 취소됨');
        return;
      }

      print('3. 구글 인증 정보 획득 시도...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;
      
      print('- ID Token 존재: ${idToken != null}');
      print('- ID Token 길이: ${idToken?.length ?? 0}');
      print('- Access Token 존재: ${accessToken != null}');
      print('- Access Token 길이: ${accessToken?.length ?? 0}');

      if (idToken == null) {
        throw Exception('ID Token을 받지 못했습니다. 설정을 확인해주세요.');
      }

      // Firebase 인증
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase 인증 실패: 사용자 정보 없음');
      }
      
      print('6. Firestore 데이터 저장...');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'provider': 'google',
      }, SetOptions(merge: true));

      if (!mounted) return;
      
      print('7. 메인 페이지로 이동...');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
      
      print('구글 로그인 완료!');

      // 로그인 성공 시 로컬에 사용자 데이터 저장
      await _saveUserDataLocally(googleUser.email, googleAuth.accessToken!);
      
    } catch (e) {
      print('로그인 오류: $e');
      // 에러 처리
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserDataLocally(String email, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_token', token);
      print('사용자 데이터 로컬 저장 완료');
    } catch (e) {
      print('사용자 데이터 저장 실패: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
