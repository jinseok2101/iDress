import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'fitting_in_closet_pants.dart';

class FittingInClosetTop extends StatefulWidget {
  final String userId;
  final String childId; // 추가: 자녀 ID
  final List<Map<dynamic, dynamic>> topClothes;

  const FittingInClosetTop({
    Key? key,
    required this.userId,
    required this.childId, // 추가
    required this.topClothes,
  }) : super(key: key);

  @override
  State<FittingInClosetTop> createState() => _FittingInClosetTopState();
}

class _FittingInClosetTopState extends State<FittingInClosetTop> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? selectedTopId;

  Future<void> _uploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
        });

        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String uuid = const Uuid().v4();
        final String extension = path.extension(pickedFile.path);
        final String fileName = '${widget.userId}_${widget.childId}_top_${timestamp}_$uuid$extension';

        // 수정: Storage 경로에 childId 추가
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(widget.userId)
            .child('children')
            .child(widget.childId)
            .child('clothing')
            .child(fileName);

        final UploadTask uploadTask = storageRef.putFile(
          File(pickedFile.path),
          SettableMetadata(
            contentType: 'image/${extension.substring(1)}',
            customMetadata: {
              'userId': widget.userId,
              'childId': widget.childId,
              'category': '상의',
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // 수정: Database 경로에 childId 추가
        final databaseRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(widget.userId)
            .child('children')
            .child(widget.childId)
            .child('clothing');

        await databaseRef.push().set({
          'imageUrl': downloadUrl,
          'category': '상의',
          'name': '새 상의',
          'size': '',
          'createdAt': ServerValue.timestamp,
          'childId': widget.childId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지가 업로드되었습니다')),
        );
      }
    } catch (e) {
      print('이미지 업로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 중 오류가 발생했습니다')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '상의',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () async {
                try {
                  final clothingRef = FirebaseDatabase.instance
                      .ref()
                      .child('users')
                      .child(widget.userId)
                      .child('clothing');

                  final snapshot = await clothingRef.get();
                  if (snapshot.exists) {
                    final data = snapshot.value as Map<dynamic, dynamic>;

                    final pantsClothes = data.entries
                        .where((entry) {
                      final clothing = entry.value as Map<dynamic, dynamic>;
                      return clothing['category'] == '하의';
                    })
                        .map((entry) => entry.value as Map<dynamic, dynamic>)
                        .toList();

                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FittingInClosetPants(
                            userId: widget.userId,
                            pantsClothes: pantsClothes,
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  print('데이터 로드 오류: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다')),
                  );
                }
              },
              child: Text(
                '건너뛰기 >',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: widget.topClothes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return InkWell(
                    onTap: _isUploading ? null : _uploadImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _isUploading
                          ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.black87,
                            size: 30,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '새로 가져오기',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final clothing = widget.topClothes[index - 1];
                final String clothingId = clothing['id'] ?? '';
                final bool isSelected = clothingId == selectedTopId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTopId = isSelected ? null : clothingId;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              clothing['imageUrl'],
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    clothing['name'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Size: ${clothing['size'] ?? ''}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: selectedTopId != null
          ? Container(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            try {
              final clothingRef = FirebaseDatabase.instance
                  .ref()
                  .child('users')
                  .child(widget.userId)
                  .child('clothing');

              final snapshot = await clothingRef.get();
              if (snapshot.exists) {
                final data = snapshot.value as Map<dynamic, dynamic>;

                final pantsClothes = data.entries
                    .where((entry) {
                  final clothing = entry.value as Map<dynamic, dynamic>;
                  return clothing['category'] == '하의';
                })
                    .map((entry) => entry.value as Map<dynamic, dynamic>)
                    .toList();

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FittingInClosetPants(
                        userId: widget.userId,
                        pantsClothes: pantsClothes,
                      ),
                    ),
                  );
                }
              }
            } catch (e) {
              print('데이터 로드 오류: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size(double.infinity, 0),
          ),
          child: Text(
            '다음',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      )
          : null,
    );
  }
}