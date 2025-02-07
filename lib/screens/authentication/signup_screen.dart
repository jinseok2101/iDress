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
  String? profileImageUrl,
}) async {
  final databaseRef = FirebaseDatabase.instance.ref("users/$uid");
  final timestamp = DateTime.now().toIso8601String();

  await databaseRef.set({
    "username": username,
    "phone": phone,
    "createdAt": timestamp,
    if (profileImageUrl != null) "profileImageUrl": profileImageUrl,
  });
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isUsernameDuplicated = true; // 닉네임 중복 여부 상태 추가
  XFile? _profileImage;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 닉네임 중복 검사 함수 수정
  Future<bool> isUsernameDuplicated(String username) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref("users");
      // 모든 사용자 데이터를 가져옴
      final snapshot = await databaseRef.get();

      if (!snapshot.exists) return false;

      // 데이터를 Map으로 변환
      final data = snapshot.value as Map<dynamic, dynamic>;

      // 모든 사용자를 순회하면서 username 비교
      bool isDuplicated = false;
      data.forEach((key, value) {
        if (value is Map && value['username'] == username) {
          isDuplicated = true;
        }
      });

      debugPrint('닉네임 중복 검사 결과: $isDuplicated');
      return isDuplicated;

    } catch (e) {
      debugPrint('닉네임 중복 확인 중 오류 발생: $e');
      return false; // 에러 발생 시 false 반환하도록 수정
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

  Future<String?> _uploadImageToFirebase(XFile imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('사용자가 인증되지 않았습니다.');

      // 수정된 저장 경로
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)  // userId 폴더
          .child('parent_profile_images')
          .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_at': DateTime.now().toIso8601String(),
          'purpose': 'profile_image'
        },
      );

      final uploadTask = await storageRef.putFile(
        File(imageFile.path),
        metadata,
      );

      if (uploadTask.state == TaskState.success) {
        return await storageRef.getDownloadURL();
      }
      return null;
    } catch (e) {
      debugPrint('프로필 이미지 업로드 실패: $e');
      rethrow;
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

      final username = _usernameController.text.trim();

      // 병렬 처리를 위한 Future 리스트 생성
      final futures = <Future>[];

      // 1. 닉네임 중복 검사
      futures.add(
          isUsernameDuplicated(username).then((isDuplicated) {
            if (isDuplicated) {
              throw Exception('이미 사용 중인 닉네임입니다.');
            }
          })
      );

      // 2. 이미지 업로드 (있는 경우에만)
      String? profileImageUrl;
      if (_profileImage != null) {
        futures.add(
            _uploadImageToFirebase(_profileImage!).then((url) {
              profileImageUrl = url;
            })
        );
      }

      // 3. 전화번호 형식 검증
      futures.add(
          Future(() {
            final phoneRegExp = RegExp(r'^\d{3}-\d{3,4}-\d{4}$');
            if (!phoneRegExp.hasMatch(_phoneController.text.trim())) {
              throw Exception('올바른 전화번호 형식이 아닙니다.');
            }
          })
      );

      // 모든 병렬 작업 실행 및 대기
      await Future.wait(futures);

      // 4. 사용자 정보 저장 (병렬 작업들이 모두 완료된 후)
      await saveUserToFirebase(
        uid: user.uid,
        username: username,
        phone: _phoneController.text.trim(),
        profileImageUrl: profileImageUrl,
      );

      if (mounted) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


// _buildUsernameInputField 함수 수정
  Widget _buildUsernameInputField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: '사용할 닉네임',
        prefixIcon: const Icon(Icons.account_circle_outlined),

        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.check_circle_outline,
            color: _isUsernameDuplicated ? Colors.grey : Colors.green,
          ),
          onPressed: () async {
            final username = _usernameController.text.trim();

            if (username.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('닉네임을 입력해주세요'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final idRegExp = RegExp(r'^[가-힣a-zA-Z0-9]+$');
            if (!idRegExp.hasMatch(username)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('닉네임은 한글, 영문, 숫자만 사용 가능합니다'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            setState(() => _isLoading = true);

            try {
              final isDuplicated = await isUsernameDuplicated(username);

              setState(() {
                _isUsernameDuplicated = isDuplicated;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isDuplicated ? '이미 사용 중인 닉네임입니다.' : '사용 가능한 닉네임입니다.',
                    ),
                    backgroundColor: isDuplicated ? Colors.red : Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('닉네임 중복 확인 중 오류가 발생했습니다.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '닉네임을 입력해주세요';
        }
        final idRegExp = RegExp(r'^[가-힣a-zA-Z0-9]+$');
        if (!idRegExp.hasMatch(value)) {
          return '한글, 영문, 숫자만 사용 가능합니다';
        }
        return null;
      },
      onChanged: (value) {
        // 닉네임이 변경되면 중복 확인 상태 초기화
        setState(() => _isUsernameDuplicated = true);
      },
    );
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

                  _buildImagePicker(),
                  const SizedBox(height: 24),

                  _buildUsernameInputField(),
                  const SizedBox(height: 24),

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
