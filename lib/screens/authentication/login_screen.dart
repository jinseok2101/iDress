import 'package:flutter/material.dart';
import 'package:last3/screens/authentication/auth_service.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Auth _authService = Auth();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final id = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (await _authService.signInWithID(id, password)) {
      debugPrint('로그인 성공');
      context.go('/home'); // 로그인 성공 시 홈 화면으로 이동
    } else {
      debugPrint('로그인 실패: ID = $id, 비밀번호 불일치');
      _showErrorSnackbar('로그인 정보가 올바르지 않습니다.');
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
      backgroundColor: const Color(0xFFF2E4C4), // 배경 수정
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // 로고 섹션
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100, // 로고 크기 유지
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),

                // 이메일 입력 필드
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Your Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력 필드
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                // 아이디/비밀번호 찾기
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      '아이디/비밀번호 찾기',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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
      height: 48,
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
