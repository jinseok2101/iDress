import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddClothingPage extends StatefulWidget {
  final Map<String, dynamic> childInfo; // 자녀 정보 추가

  const AddClothingPage({
    Key? key,
    required this.childInfo, // 생성자에 자녀 정보 매개변수 추가
  }) : super(key: key);

  @override
  State<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends State<AddClothingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  String selectedCategory = '전체';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<Map<String, dynamic>> categories = [
    {'label': '상의', 'icon': Icons.checkroom},
    {'label': '하의', 'icon': Icons.checkroom},
    {'label': '신발', 'icon': Icons.checkroom},
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null || _userId.isEmpty) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String uuid = const Uuid().v4();
      final String extension = path.extension(_imageFile!.path);
      final String fileName = '${_userId}_${widget.childInfo['childId']}_${timestamp}_$uuid$extension';

      // Storage 경로를 자녀별로 구분
      final Reference storageRef = _storage
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .child(widget.childInfo['childId'])
          .child('clothing')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(
        _imageFile!,
        SettableMetadata(
          contentType: 'image/${extension.substring(1)}',
          customMetadata: {
            'userId': _userId,
            'childId': widget.childInfo['childId'],
            'uploadedAt': DateTime.now().toIso8601String(),
            'category': selectedCategory,
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 중 오류가 발생했습니다')),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _saveClothing() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 선택해주세요')),
      );
      return;
    }

    if (nameController.text.isEmpty || sizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요')),
      );
      return;
    }

    try {
      final imageUrl = await _uploadImage();
      if (imageUrl != null) {
        // Database 경로를 자녀별로 구분
        final databaseRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(_userId)
            .child('children')
            .child(widget.childInfo['childId'])
            .child('clothing');

        await databaseRef.push().set({
          'name': nameController.text,
          'size': sizeController.text,
          'category': selectedCategory,
          'imageUrl': imageUrl,
          'createdAt': ServerValue.timestamp,
          'childId': widget.childInfo['childId'],
        });

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중 오류가 발생했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.childInfo['childName']}의 옷 추가', // 자녀 이름 표시
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 선택 영역
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        '사진 가져오기',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),

            // 카테고리 선택 영역
            Text(
              '카테고리',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  bool isSelected = selectedCategory == category['label'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedCategory = category['label'];
                        });
                      },
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              category['icon'],
                              size: 32,
                              color: isSelected ? Colors.blue : Colors.grey[600],
                            ),
                            SizedBox(height: 6),
                            Text(
                              category['label'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.blue : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 40),

            // 이름 입력
            Text(
              '이름',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: '옷 이름을 입력하세요',
              ),
            ),
            SizedBox(height: 24),

            // 사이즈 입력
            Text(
              '사이즈',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: sizeController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: '사이즈를 입력하세요',
              ),
            ),
            SizedBox(height: 40),

            // 등록 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : () => _saveClothing(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF9B9B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  '등록',
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
    );
  }
}