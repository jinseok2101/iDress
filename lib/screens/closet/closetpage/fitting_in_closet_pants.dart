import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:last3/screens/fitting_room/fittingroom/fitting_result_page.dart';
import 'package:last3/screens/fitting_room/fittingroom/fitting_loading_page.dart';


class FittingInClosetPants extends StatefulWidget {
  final String userId;
  final String childId;
  final List<Map<dynamic, dynamic>> pantsClothes;
  final String selectedTopImageUrl;

  const FittingInClosetPants({
    Key? key,
    required this.userId,
    required this.childId,
    required this.pantsClothes,
    required this.selectedTopImageUrl,
  }) : super(key: key);

  @override
  State<FittingInClosetPants> createState() => _FittingInClosetPantsState();
}

class _FittingInClosetPantsState extends State<FittingInClosetPants> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? selectedPantsId;

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('이미지 선택'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library),
                        SizedBox(width: 10),
                        Text('갤러리에서 선택'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.gallery);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Divider(),
                ),
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_camera),
                        SizedBox(width: 10),
                        Text('카메라로 촬영'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadImage() async {
    try {
      final ImageSource? source = await _showImageSourceDialog(context);

      if (source != null) {
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
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
          final String fileName = '${widget.userId}_${widget.childId}_${timestamp}_$uuid$extension';

          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('users')
              .child(widget.userId)
              .child('children')
              .child(widget.childId)
              .child('clothing')
              .child('하의')
              .child(fileName);

          final UploadTask uploadTask = storageRef.putFile(
            File(pickedFile.path),
            SettableMetadata(
              contentType: 'image/${extension.substring(1)}',
              customMetadata: {
                'userId': widget.userId,
                'childId': widget.childId,
                'category': '하의',
                'uploadedAt': DateTime.now().toIso8601String(),
              },
            ),
          );

          final TaskSnapshot snapshot = await uploadTask;
          final String downloadUrl = await snapshot.ref.getDownloadURL();

          final databaseRef = FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(widget.userId)
              .child('children')
              .child(widget.childId)
              .child('clothing')
              .child('하의');

          await databaseRef.push().set({
            'imageUrl': downloadUrl,
            'category': '하의',
            'name': '새 하의',
            'size': '',
            'createdAt': ServerValue.timestamp,
            'childId': widget.childId,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지가 업로드되었습니다')),
          );
        }
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
          '하의',
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FittingLoadingPage(
                      childInfo: {
                        'childId': widget.childId,
                        'userId': widget.userId,
                      },
                      topImage: widget.selectedTopImageUrl,
                      bottomImage: '',
                      isOnepiece: false,
                      isFromCloset: true,
                    ),
                  ),
                );
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
              itemCount: widget.pantsClothes.length + 1,
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

                final clothing = widget.pantsClothes[index - 1];
                final String clothingId = clothing['imageUrl'];
                final bool isSelected = clothingId == selectedPantsId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPantsId = isSelected ? null : clothingId;
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
      bottomNavigationBar: selectedPantsId != null
          ? Container(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            final selectedPants = widget.pantsClothes.firstWhere(
                  (pants) => pants['imageUrl'] == selectedPantsId,
              orElse: () => {},
            );

            if (selectedPants.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FittingLoadingPage(
                    childInfo: {
                      'childId': widget.childId,
                      'userId': widget.userId,
                    },
                    topImage: widget.selectedTopImageUrl,
                    bottomImage: selectedPants['imageUrl'],
                    isOnepiece: false,
                    isFromCloset: true,
                  ),
                ),
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
            '입혀보기',
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