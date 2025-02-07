import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fittingroom/fitting_loading_page.dart';
import 'fittingroom/fitting_history_page.dart';
import 'package:last3/screens/closet/closet_page.dart';

class FittingRoomPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final String? fullBodyImageUrl;
  final bool clearPreviousImages;  // 추가된 파라미터

  const FittingRoomPage({
    Key? key,
    required this.childInfo,
    this.fullBodyImageUrl,
    this.clearPreviousImages = false,  // 기본값 false
  }) : super(key: key);

  @override
  State<FittingRoomPage> createState() => _FittingRoomPageState();
}

class _FittingRoomPageState extends State<FittingRoomPage> {
  String? topImageUrl;
  String? bottomImageUrl;
  File? topImage;
  File? bottomImage;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isUploading = false;
  String? selectedClothingUrl;
  String selectedOption = '상의';

  bool _clearPreviousImages = false;  // 상태 변수 추가

  @override
  void initState() {
    super.initState();

    _clearPreviousImages = widget.clearPreviousImages;  // 위젯의 값을 상태 변수로 복사

    // clearPreviousImages가 true일 경우 모든 이미지 상태를 초기화
    if (_clearPreviousImages) {
      setState(() {
        topImageUrl = null;
        bottomImageUrl = null;
        topImage = null;
        bottomImage = null;
        selectedClothingUrl = null;
        selectedOption = '상의';  // 옵션도 기본값으로 초기화
        _clearPreviousImages = false;  // 초기화 후 false로 변경
      });
    }
  }

  Future<(ImageSource?, bool)?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<(ImageSource?, bool)>(
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
                    Navigator.of(context).pop((ImageSource.gallery, false));
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
                    Navigator.of(context).pop((ImageSource.camera, false));
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
                        Icon(Icons.checkroom),
                        SizedBox(width: 10),
                        Text('옷장에서 선택'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop((null, true));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(String type) async {
    try {
      final result = await _showImageSourceDialog(context);

      if (result != null) {
        final (source, fromCloset) = result;

        if (fromCloset) {
          // 옷장에서 선택하는 경우
          String allowedCategory;
          if (selectedOption == '상의') {
            allowedCategory = '상의';
          } else if (selectedOption == '하의') {
            allowedCategory = '하의';
          } else if (selectedOption == '올인원') {
            allowedCategory = '올인원';
          } else if (selectedOption == '아우터') {
            allowedCategory = '아우터';
          } else if (selectedOption == '상의+하의') {
            allowedCategory = type == 'top' ? '상의' : '하의';
          } else {
            allowedCategory = '전체';
          }

          final selectedClothing = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (context) => ClosetPage(
                childInfo: widget.childInfo,
                selectionMode: true,
                allowedCategory: allowedCategory,
              ),
            ),
          );

          if (selectedClothing != null) {
            setState(() {
              String imageUrl = selectedClothing['imageUrl'] as String;
              if (type == 'top' || selectedOption == '올인원' || selectedOption == '아우터') {
                topImageUrl = imageUrl;
                topImage = null;
              } else if (type == 'bottom') {
                bottomImageUrl = imageUrl;
                bottomImage = null;
              }
            });
          }
        } else if (source != null) {
          // 갤러리나 카메라에서 선택하는 경우
          final XFile? pickedFile = await _picker.pickImage(
            source: source,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );

          if (pickedFile != null) {
            setState(() {
              if (type == 'top' || selectedOption == '올인원' || selectedOption == '아우터') {
                topImage = File(pickedFile.path);
                topImageUrl = null;
              } else if (type == 'bottom') {
                bottomImage = File(pickedFile.path);
                bottomImageUrl = null;
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
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
        title: const Text(
          '피팅룸',
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FittingHistoryPage(childInfo: widget.childInfo),
                ),
              );
            },
            icon: Icon(Icons.history, color: Colors.grey[600]),
            label: Text(
              '기록보기',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: AspectRatio(
                      aspectRatio: 1/2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.fullBodyImageUrl != null
                              ? Image.network(
                            widget.fullBodyImageUrl!,
                            fit: BoxFit.contain,
                          )
                              : Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    '전신 사진을 등록해주세요',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    width: 130,
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: selectedOption,
                            isExpanded: true,
                            underline: Container(),
                            items: ['상의', '하의', '아우터', '상의+하의', '올인원']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(fontSize: 16),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedOption = newValue!;
                                selectedClothingUrl = null;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        if (selectedOption == '상의+하의') ...[
                          _buildUploadContainer('top'),
                          SizedBox(height: 16),
                          _buildUploadContainer('bottom'),
                        ] else ...[
                          _buildUploadContainer(selectedOption == '하의' ? 'bottom' : 'top'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: _buildFittingButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadContainer(String type) {
    File? image = type == 'top' ? topImage : bottomImage;
    String? imageUrl = type == 'top' ? topImageUrl : bottomImageUrl;
    String label;

    if (selectedOption == '올인원') {
      label = '올인원';
    } else if (selectedOption == '아우터') {
      label = '아우터';
    } else {
      label = type == 'top' ? '상의' : '하의';
    }

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: image != null
          ? Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              image,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (type == 'top') {
                    topImage = null;
                    topImageUrl = null;
                  } else {
                    bottomImage = null;
                    bottomImageUrl = null;
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      )
          : imageUrl != null
          ? Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (type == 'top') {
                    topImageUrl = null;
                  } else {
                    bottomImageUrl = null;
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      )
          : InkWell(
        onTap: () => _pickImage(type),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_upload_outlined,
                size: 50,
                color: Colors.grey[600]),
            SizedBox(height: 12),
            Text(
              '$label 업로드',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFittingButton() {
    bool hasTopImage = topImage != null || topImageUrl != null;
    bool hasBottomImage = bottomImage != null || bottomImageUrl != null;
    bool isEnabled = (selectedOption == '상의+하의' && hasTopImage && hasBottomImage) ||
        ((selectedOption == '상의' || selectedOption == '하의' ||
            selectedOption == '올인원' || selectedOption == '아우터') &&
            (hasTopImage || hasBottomImage));

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: isEnabled ? Colors.lightBlue[300] : Colors.grey[300],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isEnabled
                ? Colors.lightBlue[300]!.withOpacity(0.3)
                : Colors.grey[300]!.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FittingLoadingPage(
                  childInfo: widget.childInfo,
                  topImage: topImage,
                  bottomImage: bottomImage,
                  topImageUrl: topImageUrl,
                  bottomImageUrl: bottomImageUrl,
                  isOnepiece: selectedOption == '올인원',
                  isFromCloset: topImageUrl != null || bottomImageUrl != null,
                  clothType: selectedOption,
                ),
              ),
            );
          } : null,
          customBorder: CircleBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.checkroom,
                size: 36,
                color: isEnabled ? Colors.white : Colors.grey[400],
              ),
              SizedBox(height: 6),
              Text(
                '피팅하기',
                style: TextStyle(
                  fontSize: 14,
                  color: isEnabled ? Colors.white : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}