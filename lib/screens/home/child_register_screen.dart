import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String? _selectedAge;
  String? _selectedGender;
  String? _selectedClothingSize;
  File? _profileImage;
  File? _fullBodyImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickFullBodyImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _fullBodyImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _registerChild() async {
    if (_nameController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _selectedAge == null ||
        _selectedGender == null ||
        _selectedClothingSize == null ||
        _profileImage == null ||
        _fullBodyImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필드를 입력하고 사진을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      if (_userId.isEmpty) throw Exception('사용자가 인증되지 않았습니다.');

      // 1. Realtime Database에 먼저 child 노드 생성하여 childId 얻기
      final childRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .push();

      final childId = childRef.key!;

      // 2. 이미지 업로드
      final profileImageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .child(childId)
          .child('child_profile_images')
          .child('profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(_profileImage!.path)}');

      final fullBodyImageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .child(childId)
          .child('child_fullbody_images')
          .child('fullbody_${DateTime.now().millisecondsSinceEpoch}${path.extension(_fullBodyImage!.path)}');

      // 이미지 업로드 실행
      final profileUpload = await profileImageRef.putFile(_profileImage!);
      final fullBodyUpload = await fullBodyImageRef.putFile(_fullBodyImage!);

      // URL 가져오기
      final profileImageUrl = await profileUpload.ref.getDownloadURL();
      final fullBodyImageUrl = await fullBodyUpload.ref.getDownloadURL();

      // 3. child 데이터 저장
      await childRef.set({
        'childId': childId,
        'name': _nameController.text,
        'age': _selectedAge,
        'gender': _selectedGender,
        'height': _heightController.text,
        'clothingSize': _selectedClothingSize,
        'profileImageUrl': profileImageUrl,
        'fullBodyImageUrl': fullBodyImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('아이 등록이 완료되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('등록 중 오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2E4C4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2B2B2B), size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          '아이 등록',
          style: TextStyle(
            color: Color(0xFF2B2B2B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '프로필 사진',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickProfileImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    image: _profileImage != null
                        ? DecorationImage(
                      image: FileImage(_profileImage!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _profileImage == null
                      ? const Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Colors.grey,
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('이름', '아이의 이름을 입력하세요', _nameController),
              _buildDropdownField('나이', '아이의 나이를 선택하세요',
                  ['1세', '2세', '3세', '4세', '5세'],
                      (value) => setState(() => _selectedAge = value)),
              _buildDropdownField('성별', '아이의 성별을 선택하세요',
                  ['남자', '여자'],
                      (value) => setState(() => _selectedGender = value)),
              _buildTextField('신장(cm)', '아이의 신장을 입력하세요', _heightController),
              _buildDropdownField('옷의 사이즈', '아이의 옷 사이즈를 선택하세요',
                  ['90', '100', '110', '120', '130'],
                      (value) => setState(() => _selectedClothingSize = value)),
              const SizedBox(height: 20),
              const Text(
                '전신 사진',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickFullBodyImage,
                child: Container(
                  width: 200,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _fullBodyImage != null
                      ? Image.file(
                    _fullBodyImage!,
                    fit: BoxFit.cover,
                  )
                      : const Icon(
                    Icons.add_a_photo,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _registerChild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '등록하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
      String label, String hint, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: options
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}