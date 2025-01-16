import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:last3/screens/authentication/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

// Firebase Realtime Database에 사용자 정보 저장 함수
Future<void> saveUserToFirebase({
  required String uid,
  required String username,
  required String phone,
  String? id,
  String? passwordHash,
  String? profileImageUrl,
}) async {
  final databaseRef = FirebaseDatabase.instance.ref("users/$uid");
  final timestamp = DateTime.now().toIso8601String();

  await databaseRef.set({
    "username": username,
    "phone": phone,
    if (id != null) "id": id, // 일반 로그인 사용자만 저장
    if (passwordHash != null) "passwordHash": passwordHash, // 일반 로그인 사용자만 저장
    "createdAt": timestamp,
    if (profileImageUrl != null) "profileImageUrl": profileImageUrl, // 프로필 이미지 URL 추가
  });
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  XFile? _profileImage; // 선택한 프로필 이미지 파일

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 이미지 선택 함수
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

  // 이미지 업로드 함수
  Future<String?> _uploadImageToFirebase(XFile imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final profileImagesRef = storageRef.child("parent_profile/${DateTime.now().millisecondsSinceEpoch}.jpg");

      // 이미지 업로드
      final uploadTask = profileImagesRef.putFile(File(imageFile.path));
      final snapshot = await uploadTask;

      // 업로드 후 이미지 URL을 가져옴
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      debugPrint("이미지 업로드 실패: $e");
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('사용자가 인증되지 않았습니다.');
      }

      final uid = user.uid; // Firebase Authentication에서 고유 UID 가져오기

      String? profileImageUrl;
      if (_profileImage != null) {
        // Firebase Storage에 이미지 업로드하고 URL 받아오기
        profileImageUrl = await _uploadImageToFirebase(_profileImage!);
      }

      await saveUserToFirebase(
        uid: uid,
        username: _usernameController.text,
        phone: _phoneController.text,
        id: _idController.text,
        passwordHash: Auth().hashPassword(_passwordController.text), // 비밀번호 해시 추가 필요
        profileImageUrl: profileImageUrl,
      );
      debugPrint('회원가입: 저장된 해시 비밀번호 = ${Auth().hashPassword(_passwordController.text)}');

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 중 오류가 발생했습니다')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    '회원가입',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF7165D6),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // 이미지 선택 UI 추가
                  _buildImagePicker(),
                  const SizedBox(height: 24),

                  // 기존 입력 필드들
                  _buildInputField(
                    controller: _usernameController,
                    label: '닉네임',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '닉네임을 입력해주세요';
                      }
                      if (value.length < 2) {
                        return '닉네임은 2자 이상이어야 합니다';
                      }
                      final nameRegExp = RegExp(r'^[가-힣a-zA-Z0-9]+$');
                      if (!nameRegExp.hasMatch(value)) {
                        return '한글, 영문, 숫자만 사용 가능합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _phoneController,
                    label: '전화번호',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '전화번호를 입력해주세요';
                      }
                      final phoneRegExp = RegExp(r'^\d{3}-\d{3,4}-\d{4}$');
                      if (!phoneRegExp.hasMatch(value)) {
                        return '올바른 전화번호 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _idController,
                    label: '사용할 ID',
                    prefixIcon: Icons.account_circle_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ID를 입력해주세요';
                      }
                      final idRegExp = RegExp(r'^[가-힣a-zA-Z0-9]+$');
                      if (!idRegExp.hasMatch(value)) {
                        return '한글, 영문, 숫자만 사용 가능합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _passwordController,
                    label: '비밀번호',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _confirmPasswordController,
                    label: '비밀번호 확인',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 다시 입력해주세요';
                      }
                      if (value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7165D6),
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: _isLoading ? 0 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 이미지 선택 UI
  Widget _buildImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            child: _profileImage == null
                ? Icon(
              Icons.camera_alt,
              color: Colors.grey.shade600,
              size: 40,
            )
                : ClipOval(
              child: Image.file(
                File(_profileImage!.path),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '프로필 사진을 추가하세요',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
