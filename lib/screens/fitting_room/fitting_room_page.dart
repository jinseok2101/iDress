import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';  // Uint8List 필요
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fittingroom/fitting_loading_page.dart';
import 'fittingroom/fitting_history_page.dart';

import 'package:path_provider/path_provider.dart';

class FittingRoomPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final String? fullBodyImageUrl;

  const FittingRoomPage({
    Key? key,
    required this.childInfo,
    this.fullBodyImageUrl,
  }) : super(key: key);

  @override
  State<FittingRoomPage> createState() => _FittingRoomPageState();
}

class _FittingRoomPageState extends State<FittingRoomPage> {
  File? topImage;
  File? bottomImage;
  String? _humanImageBase64;
  String? _garmentImageBase64;
  String _response = "";
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isUploading = false;
  String selectedOption = '상의'; // 콤보박스 기본값

  DatabaseReference get _clothingRef =>
      FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .child(widget.childInfo['childId'])
          .child('clothing');

  Reference get _storageRef =>
      FirebaseStorage.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .child(widget.childInfo['childId'])
          .child('clothing');


  Future<void> uploadImages() async {

    final url = Uri.parse('http://34.64.206.26:80/upload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'human_image': _humanImageBase64,
          'garment_image': _garmentImageBase64,
        }),
      );

      if (response.statusCode == 200) {
        // 서버에서 반환된 Base64 이미지 데이터를 파싱
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String resultBase64 = responseData['result_image'];

        // Base64 이미지를 디코딩하여 이미지로 변환
        final bytes = base64Decode(resultBase64);

      } else {
        setState(() {
          _response = "서버 오류: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _response = "에러 발생: $e";
      });
    }
  }





  Future<void> _pickImage(String type) async {
    try {
      // 이미 이미지가 있고, 단일 이미지 옵션일 경우 더 이상 업로드 불가
      if ((topImage != null || bottomImage != null) &&
          (selectedOption == '상의' || selectedOption == '하의' || selectedOption == '한벌옷')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 이미지가 선택되었습니다')),
        );
        return;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      String encodeUrlToBase64(String url) {
        // URL을 바이트 배열로 변환한 후 Base64로 인코딩
        List<int> bytes = utf8.encode(url);
        return base64Encode(bytes);
      }

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        String base64String = base64Encode(bytes);
        if (widget.fullBodyImageUrl != null) {
          String encodedUrl = encodeUrlToBase64(widget.fullBodyImageUrl!);
          _humanImageBase64 = encodedUrl;
        } else {
          // fullBodyImageUrl이 null일 때 처리할 로직 추가
          print("Image URL is null");
        }
        setState(() {
          switch (selectedOption) {
            case '상의':
              topImage = File(pickedFile.path);
              _garmentImageBase64=base64String;
              bottomImage = null;
              break;
            case '하의':
              topImage = null;
              bottomImage = File(pickedFile.path);
              break;
            case '상의+하의':
              if (topImage == null) {
                topImage = File(pickedFile.path);
              } else if (bottomImage == null) {
                bottomImage = File(pickedFile.path);
              }
              break;
            case '한벌옷':
              topImage = File(pickedFile.path);
              bottomImage = null;
              break;
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
        // 아이 전신 사진
        Expanded(
          flex: 4,
          child: AspectRatio(
            aspectRatio: 1/2,  // 세로로 긴 1:2 비율 설정
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
      // 오른쪽 영역
      Container(
        width: 130,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 콤보박스
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
                items: ['상의', '하의', '상의+하의', '한벌옷']
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
                    topImage = null;
                    bottomImage = null;
                  });
                },
              ),
            ),
            SizedBox(height: 16),
            // 업로드 영역
            if (selectedOption == '상의+하의') ...[
              // 상의 업로드 버튼 또는 미리보기
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: topImage != null
                    ? Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        topImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            topImage = null;
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
                  onTap: () => _pickImage(selectedOption),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_upload_outlined,
                          size: 50,
                          color: Colors.grey[600]),
                      SizedBox(height: 12),
                      Text(
                        '상의 업로드',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // 하의 업로드 버튼 또는 미리보기
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: bottomImage != null
                    ? Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        bottomImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            bottomImage = null;
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
                  onTap: () => _pickImage(selectedOption),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_upload_outlined,
                          size: 50,
                          color: Colors.grey[600]),
                      SizedBox(height: 12),
                      Text(
                        '하의 업로드',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // 단일 이미지 업로드 버튼 또는 미리보기
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: (topImage != null || bottomImage != null)
                    ? Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        topImage ?? bottomImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            topImage = null;
                            bottomImage = null;
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
                  onTap: () => _pickImage(selectedOption),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_upload_outlined,
                          size: 50,
                          color: Colors.grey[600]),
                      SizedBox(height: 12),
                      Text(
                        '${selectedOption == "상의" ? "상의" : selectedOption == "하의" ? "하의" : "한벌옷"} 업로드',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
    ),
    ),
    ),
      // 피팅하기 버튼
      Container(
        padding: EdgeInsets.all(16),
        child: _buildFittingButton(),
      ),
    ],
    ),
    );
  }

  Widget _buildFittingButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.lightBlue[300],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.lightBlue[300]!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (topImage == null && bottomImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('최소한 하나의 의류를 선택해주세요'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          uploadImages();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FittingLoadingPage(
                childInfo: widget.childInfo,
                topImage: topImage,
                bottomImage: bottomImage,
                isOnepiece: selectedOption == '한벌옷',
                isFromCloset: false,
                humanImageBase64: _humanImageBase64,
                garmentImageBase64: _garmentImageBase64,
              ),
            ),
          );
        },
        customBorder: CircleBorder(),
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