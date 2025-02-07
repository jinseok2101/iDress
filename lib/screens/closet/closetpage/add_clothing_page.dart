import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'clothing_analyzer.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AddClothingPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;

  const AddClothingPage({
    Key? key,
    required this.childInfo,
  }) : super(key: key);

  @override
  State<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends State<AddClothingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController memoController = TextEditingController();
  String selectedCategory = '전체';
  String selectedColor = '미분류';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isAnalyzing = false;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final ClothingAnalyzer _analyzer = ClothingAnalyzer();

  final List<Map<String, dynamic>> categories = [
    {
      'label': '올인원',
      'imagePath': 'assets/images/categories/free-icon-onesie-1012727.png',
    },
    {
      'label': '아우터',
      'imagePath': 'assets/images/categories/outer.png',
    },
    {
      'label': '상의',
      'imagePath': 'assets/images/categories/free-icon-shirt-16882503.png',
    },
    {
      'label': '하의',
      'imagePath': 'assets/images/categories/free-icon-pants-8190299.png',
    },
    {
      'label': '신발',
      'imagePath': 'assets/images/categories/free-icon-shoes-7606033.png',
    },
  ];



  Set<String> selectedSeasons = {}; // 수정된 부분: 여러 계절 선택

  @override
  void initState() {
    super.initState();
  }

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

  Future<void> _analyzeAndSetClothing() async {
    if (_imageFile != null) {
      setState(() {
        _isAnalyzing = true;
      });

      try {
        final result = await _analyzer.analyzeClothing(_imageFile!.path);

        // 분석 결과를 임시 변수에 저장
        final analyzedCategory = result['category'];
        final analyzedColor = result['color'];
        final analyzedSeasons = Set<String>.from(result['seasons'] ?? ['봄']);
        final analyzedMemo = result['memo'] ?? ''; // 메모 내용 가져오기

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('AI 분석 결과'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('카테고리: ${result['category']}'),
                    SizedBox(height: 8),
                    Text('색상: ${result['color']}'),
                    SizedBox(height: 8),
                    Text('계절: ${(result['seasons'] as List<String>).join(", ")}'),
                    SizedBox(height: 8),
                    Text('상세 설명:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                      result['memo'] ?? '상세 설명이 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 그냥 닫기만 하고 상태 변경하지 않음
                  },
                  child: Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = analyzedCategory;
                      selectedColor = analyzedColor;
                      selectedSeasons = analyzedSeasons;
                      memoController.text = analyzedMemo; // 메모 컨트롤러에 분석된 상세 내용 설정
                    });
                    Navigator.pop(context);
                  },
                  child: Text('적용'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        print('분석 오류: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지 분석 중 오류가 발생했습니다')),
          );
        }
      } finally {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }


  Future<File?> _processImageSegmentation(File imageFile) async {
    try {
      var uri = Uri.parse('http://34.47.84.144/upload');
      var request = http.MultipartRequest('POST', uri);

      // Add file to the request
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();

      var multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Send the request
      var streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        // 응답을 파일로 저장
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File(
            '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png'
        );

        // 스트림을 파일로 저장
        await streamedResponse.stream.pipe(tempFile.openWrite());
        return tempFile;
      } else {
        print('서버 오류: ${streamedResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('이미지 처리 중 오류 발생: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final ImageSource? source = await _showImageSourceDialog(context);

      if (source != null) {
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 70,
        );

        if (pickedFile != null) {
          final File imageFile = File(pickedFile.path);

          try {
            // 서버 연결 상태 확인 (3초 타임아웃)
            final response = await http
                .get(Uri.parse('http://34.47.84.144/upload'))
                .timeout(Duration(seconds: 3));

            if (response.statusCode != 404) {  // 서버가 응답하면
              final File? processedFile = await _processImageSegmentation(imageFile);
              if (processedFile != null) {
                setState(() {
                  _imageFile = processedFile;
                });
              } else {
                setState(() {
                  _imageFile = imageFile;
                });
              }
            } else {
              setState(() {
                _imageFile = imageFile;
              });
            }
          } catch (e) {
            // 서버 연결 실패시 원본 이미지 사용
            print('서버 연결 실패: $e');
            setState(() {
              _imageFile = imageFile;
            });
          }

          await _analyzeAndSetClothing();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
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
      final String fileName =
          '${_userId}_${widget.childInfo['childId']}_${timestamp}_$uuid$extension';

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

    if (selectedCategory == '전체') { // ✅ 카테고리 선택 필수
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택해주세요')),
      );
      return;
    }

    if (nameController.text.isEmpty) { // ✅ 이름 입력 필수
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }

    if (selectedSeasons.isEmpty) { // ✅ 계절 선택 필수
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계절을 선택해주세요')),
      );
      return;
    }

    if (selectedColor == '미분류') { // ✅ 색상 선택 필수
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('색상을 선택해주세요')),
      );
      return;
    }

    try {
      final imageUrl = await _uploadImage();
      if (imageUrl != null) {
        final databaseRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(_userId)
            .child('children')
            .child(widget.childInfo['childId'])
            .child('clothing')
            .child(selectedCategory);

        await databaseRef.push().set({
          'name': nameController.text,
          'size': sizeController.text,
          'category': selectedCategory,
          'season': selectedSeasons.toList(), // 수정된 부분: 선택된 계절 저장
          'color': selectedColor,
          'memo': memoController.text,
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
          '${widget.childInfo['childName']}의 옷 추가',
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
            Center(
              child: Stack(
                children: [
                  GestureDetector(
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
                  if (_isAnalyzing)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 8),
                              Text(
                                'AI 분석중...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 40),

            Row(
              children: [
                Icon(Icons.star, color: Colors.red, size: 18), // 빨간색 별 아이콘
                SizedBox(width: 4), // 아이콘과 텍스트 사이 간격
                Text(
                  '카테고리',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                            Image.asset(
                              category['imagePath'],
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.error_outline,
                                  size: 32,
                                  color: isSelected ? Colors.blue : Colors.grey[600],
                                );
                              },
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

            Row(
              children: [
                Icon(Icons.star, color: Colors.red, size: 18), // 빨간색 별 아이콘
                SizedBox(width: 4), // 아이콘과 텍스트 사이 간격
                Text(
                  '이름',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
              keyboardType: TextInputType.number,

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
            SizedBox(height: 24),

            Row(
              children: [
                Icon(Icons.star, color: Colors.red, size: 18), // 빨간색 별 아이콘
                SizedBox(width: 4), // 아이콘과 텍스트 사이 간격
                Text(
                  '계절',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              children: ['봄', '여름', '가을', '겨울', '사계절'].map((season) {
                bool isSelected = selectedSeasons.contains(season);

                return ChoiceChip(
                  label: Text(season),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (season == '사계절') {
                        // '사계절'을 선택하면 모든 계절을 추가
                        if (selected) {
                          selectedSeasons.addAll(['봄', '여름', '가을', '겨울', '사계절']);
                        } else {
                          // '사계절'을 취소하면 모든 계절을 제거
                          selectedSeasons.removeAll(['봄', '여름', '가을', '겨울', '사계절']);
                        }
                      } else {
                        // '사계절'이 아닌 다른 계절을 선택/취소
                        if (selected) {
                          selectedSeasons.add(season);
                        } else {
                          selectedSeasons.remove(season);
                        }

                        // 봄, 여름, 가을, 겨울 4개가 모두 선택되면 '사계절'도 자동 선택
                        if (selectedSeasons.containsAll(['봄', '여름', '가을', '겨울'])) {
                          selectedSeasons.add('사계절');
                        } else {
                          // 4개 계절 중 하나라도 선택 취소하면 '사계절' 해제
                          selectedSeasons.remove('사계절');
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),

            SizedBox(height: 24),

            Row(
              children: [
                Icon(Icons.star, color: Colors.red, size: 18), // 빨간색 별 아이콘
                SizedBox(width: 4), // 아이콘과 텍스트 사이 간격
                Text(
                  '색상',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildColorChoice('흰색', Colors.white),
                  _buildColorChoice('검정', Colors.black),
                  _buildColorChoice('회색', Colors.grey),
                  _buildColorChoice('빨강', Colors.red),
                  _buildColorChoice('분홍', Colors.pink),
                  _buildColorChoice('주황', Colors.orange),
                  _buildColorChoice('노랑', Colors.yellow),
                  _buildColorChoice('초록', Colors.green),
                  _buildColorChoice('파랑', Colors.blue),
                  _buildColorChoice('남색', Colors.indigo),
                  _buildColorChoice('보라', Colors.purple),
                  _buildColorChoice('갈색', Colors.brown),
                ],
              ),
            ),
            SizedBox(height: 24),

            Text(
              '메모',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: memoController,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: '메모를 입력하세요',
              ),
            ),
            SizedBox(height: 40),

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

  Widget _buildColorChoice(String colorName, Color color) {
    bool isSelected = selectedColor == colorName;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedColor = colorName;
          });
        },
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                Icons.check,
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              )
                  : null,
            ),
            SizedBox(height: 4),
            Text(
              colorName,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}