import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'fittingroom/fitting_result_page.dart';

class FittingRoomPage extends StatefulWidget {
  final String? fullBodyImageUrl;

  const FittingRoomPage({
    Key? key,
    this.fullBodyImageUrl,
  }) : super(key: key);

  @override
  State<FittingRoomPage> createState() => _FittingRoomPageState();
}

class _FittingRoomPageState extends State<FittingRoomPage> {
  File? topImage;
  File? bottomImage;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isUploading = false;

  Future<void> _pickImage(String type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (type == 'top') {
            topImage = File(pickedFile.path);
          } else {
            bottomImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.checkroom, color: Colors.black),
            SizedBox(width: 8),
            Text(
              '피팅룸',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 피팅 기록보기 기능 구현
            },
            child: const Text(
              '피팅 기록보기',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 메인 이미지 영역
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.fullBodyImageUrl != null
                    ? Image.network(
                  widget.fullBodyImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 하단 버튼들
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.add_photo_alternate,
                  label: '상의',
                  image: topImage,
                  onTap: () => _pickImage('top'),
                ),
                _buildFittingButton(),
                _buildActionButton(
                  icon: Icons.add_photo_alternate,
                  label: '하의',
                  image: bottomImage,
                  onTap: () => _pickImage('bottom'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    File? image,
  }) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: _isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.file(
                  image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, size: 32, color: Colors.grey[600]),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFittingButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (topImage == null || bottomImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('상의와 하의 이미지를 모두 선택해주세요'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FittingResultPage(
                    topImageFile: topImage!,
                    bottomImageFile: bottomImage!,
                  ),
              opaque: false,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom,
              size: 32,
              color: Colors.white,
            ),
            SizedBox(height: 4),
            Text(
              '피팅하기',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}