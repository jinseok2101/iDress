import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:last3/screens/authentication/auth_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

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
    if (id != null) "id": id,
    if (passwordHash != null) "passwordHash": passwordHash,
    if (profileImageUrl != null) "profileImageUrl": profileImageUrl,
    "createdAt": timestamp,
  });
}

Future<String> uploadProfileImage(File imageFile) async {
  final storageRef = FirebaseStorage.instance.ref();
  final fileName = 'profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final uploadTask = storageRef.child(fileName).putFile(imageFile);
  final snapshot = await uploadTask;
  return await snapshot.ref.getDownloadURL();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
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

      String? profileImageUrl;
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        profileImageUrl = await uploadProfileImage(_selectedImage!);
        setState(() => _isUploadingImage = false);
      }

      final uid = user.uid;
      await saveUserToFirebase(
        uid: uid,
        username: _usernameController.text,
        phone: _phoneController.text,
        id: _idController.text,
        passwordHash: Auth().hashPassword(_passwordController.text),
        profileImageUrl: profileImageUrl,
      );

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
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                      _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  if (_isUploadingImage)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                  const SizedBox(height: 16),
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
