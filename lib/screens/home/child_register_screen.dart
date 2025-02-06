import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  DateTime? _selectedBirthdate;
  String? _selectedGender;
  File? _profileImage;
  File? _fullBodyImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickFullBodyImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
      maxHeight: 1920,
    );

    if (pickedFile != null) {
      setState(() {
        _fullBodyImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildProfileImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickProfileImage,
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
                _profileImage!,
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

  void _showDatePicker(BuildContext context) async {
    DateTime? selectedDate = await showOmniDateTimePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 50),
      lastDate: DateTime.now(),
      is24HourMode: false,
      isShowSeconds: false,
      minutesInterval: 1,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 500,
      ),
      type: OmniDateTimePickerType.date,
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(
            Tween(
              begin: 0,
              end: 1,
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      selectableDayPredicate: (dateTime) {
        return true;
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedBirthdate = selectedDate;
      });
    }
  }

  Future<void> _registerChild() async {
    if (_nameController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _selectedBirthdate == null ||
        _selectedGender == null ||
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

      final childRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .push();

      final childId = childRef.key!;

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

      final uploadTasks = await Future.wait([
        profileImageRef.putFile(_profileImage!),
        fullBodyImageRef.putFile(_fullBodyImage!),
      ]);

      final urls = await Future.wait([
        uploadTasks[0].ref.getDownloadURL(),
        uploadTasks[1].ref.getDownloadURL(),
      ]);

      final profileImageUrl = urls[0];
      final fullBodyImageUrl = urls[1];

      String formattedBirthdate = DateFormat('yyyy-MM-dd').format(_selectedBirthdate!);

      await childRef.set({
        'childId': childId,
        'name': _nameController.text,
        'birthdate': formattedBirthdate,
        'gender': _selectedGender,
        'height': _heightController.text,
        'weight': _weightController.text,
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
              _buildProfileImagePicker(),
              const SizedBox(height: 20),
              _buildTextField('이름', '아이의 이름을 입력하세요', _nameController),
              _buildBirthdateField('생년월일', '아이의 생년월일을 선택하세요', _showDatePicker),
              _buildDropdownField('성별', '아이의 성별을 선택하세요',
                  ['남자', '여자'], (value) => setState(() => _selectedGender = value)),
              _buildTextField('신장(cm)', '아이의 신장을 입력하세요', _heightController),
              _buildTextField('체중(kg)', '아이의 체중을 입력하세요', _weightController),
              const SizedBox(height: 20),
              const Text(
                '전신 사진',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width * 1.2,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: GestureDetector(
                  onTap: _pickFullBodyImage,
                  child: _fullBodyImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      _fullBodyImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 50,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '전신 사진을 추가하세요',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _registerChild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7165D6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '등록하기',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: label.contains("신장") || label.contains("체중")
                ? TextInputType.number
                : TextInputType.text,
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

  Widget _buildBirthdateField(
      String label, String hint, Function(BuildContext) onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => onTap(context),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Text(
                _selectedBirthdate != null
                    ? DateFormat('yyyy-MM-dd').format(_selectedBirthdate!)
                    : hint,
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String hint, List<String> options,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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