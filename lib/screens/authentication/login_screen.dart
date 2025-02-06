import 'package:flutter/material.dart';
import 'package:last3/screens/authentication/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth import 추가

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Auth _authService = Auth();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();


  @override
  void initState() {
    super.initState();

    // 앱 실행 시 로그인 상태 확인
    _checkIfUserIsLoggedIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Firebase에서 사용자가 로그인했는지 확인
  Future<void> _checkIfUserIsLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;

    // 이미 로그인한 사용자가 있다면 홈 화면으로 이동
    if (user != null) {
      debugPrint('이미 로그인된 사용자: ${user.email}');
      context.go('/home');  // 로그인 후 홈 화면으로 이동
    }
  }



  Future<void> _handleGoogleSignIn() async {
    try {
      await _authService.signInWithGoogle(context);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('구글 로그인 중 오류가 발생했습니다.');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade300,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF0), // 부드러운 베이지색 배경
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                // 로고 섹션
                Center(
                  child: Image.asset(
                    'assets/images/logo2.png', // logo2.png 경로
                    width: 300, // 이미지 너비 조정
                    height: 300, // 이미지 높이 조정
                    fit: BoxFit.contain, // 이미지 비율 유지
                  ),
                ),
                const SizedBox(height: 200),



                // 간편 로그인 섹션
                const Center(
                  child: Text(
                    '간편 로그인',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kakao 로그인 버튼
                _buildSocialLoginButton(
                  'assets/images/kakao.png',
                  const Color(0xFFFEE500),
                      () async {
                    print('Kakao 버튼 클릭됨');
                    await _authService.signInWithKakao(context);
                  },
                ),

                const SizedBox(height: 12),
                // Google 로그인 버튼
                _buildSocialLoginButton(
                  'assets/images/google.png',
                  Colors.white,
                  _handleGoogleSignIn,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton(
      String iconPath,
      Color backgroundColor,
      VoidCallback onPressed, {
        Border? border,
      }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        border: border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 400, // 아이콘 크기
            height: 400,
          ),
        ),
      ),
    );
  }
}
