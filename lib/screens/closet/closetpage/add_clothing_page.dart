import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ColorOption {
  final String name;
  final Color color;

  ColorOption(this.name, this.color);
}

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
  String selectedSeason = '사계절';
  Color selectedColor = Colors.grey;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<ColorOption> colorOptions = [
    ColorOption('흰색', Colors.white),
    ColorOption('검정', Colors.black),
    ColorOption('회색', Colors.grey),
    ColorOption('빨강', Colors.red),
    ColorOption('분홍', Colors.pink),
    ColorOption('주황', Colors.orange),
    ColorOption('노랑', Colors.yellow),
    ColorOption('초록', Colors.green),
    ColorOption('파랑', Colors.blue),
    ColorOption('남색', Colors.indigo),
    ColorOption('보라', Colors.purple),
    ColorOption('갈색', Colors.brown),
  ];

  final List<Map<String, dynamic>> categories = [
    {'label': '상의', 'icon': Icons.checkroom},
    {'label': '하의', 'icon': Icons.checkroom},
    {'label': '신발', 'icon': Icons.checkroom},
  ];

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

  Future<void> _pickImage() async {
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
            _imageFile = File(pickedFile.path);
          });
        }
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
        const SnackBar(content: Text('필수 필드를 입력해주세요')),
      );
      return;
    }

    try {
      final imageUrl = await _uploadImage();
      if (imageUrl != null) {
        final colorName = colorOptions
            .firstWhere((option) => option.color == selectedColor)
            .name;

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
          'season': selectedSeason,
          'color': colorName,
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

    // 계절 선택
    SizedBox(height: 24),
    Text(
    '계절',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    ),
    ),
    SizedBox(height: 8),
    Wrap(
    spacing: 8,
    children: [
    '봄', '여름', '가을', '겨울', '사계절'
    ].map((season) => ChoiceChip(
    label: Text(season),
    selected: selectedSeason == season,
    onSelected: (bool selected) {
    setState(() {
    selectedSeason = selected ? season : selectedSeason;
    });
    },
    )).toList(),
    ),

    // 색상 선택
    SizedBox(height: 24),
    Text(
    '색상',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    ),
    ),
    SizedBox(height: 8),
    Wrap(
    spacing: 8,
    runSpacing: 8,
    children: colorOptions.map((option) => GestureDetector(
    onTap: () {
    setState(() {
    selectedColor = option.color;
    });
    },
    child: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
    color: option.color,
    border: Border.all(
    color: selectedColor == option.color
    ? Colors.blue
        : Colors.grey,
    width: selectedColor == option.color ? 2 : 1,
    ),
    borderRadius: BorderRadius.circular(8),
    ),
    child: selectedColor == option.color
    ? Icon(
    Icons.check,
    color: option.color.computeLuminance() > 0.5
    ? Colors.black
        : Colors.white,
    )
        : null,
    ),
    )).toList(),
    ),

    // 메모 입력
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