import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> childrenProfiles = [];
  bool _isLoading = true;
  bool isSelecting = false;
  int? _selectedProfileIndex; // 단일 선택을 위한 변수

  @override
  void initState() {
    super.initState();
    _loadChildrenProfiles();
  }

  Future<void> _loadChildrenProfiles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final childrenRef = FirebaseDatabase.instance.ref('users/${user.uid}/children');
      final snapshot = await childrenRef.get();

      if (snapshot.exists) {
        print('Children snapshot: ${snapshot.value}');
        final Map<dynamic, dynamic> children = snapshot.value as Map<dynamic, dynamic>;

        // 각 자녀의 데이터를 수집
        final profiles = children.entries.map((entry) {
          final childData = entry.value as Map<dynamic, dynamic>;
          return {
            'key': entry.key,
            'name': childData['name'] ?? '',
            'birthdate': childData['birthdate'] ?? '',
            'gender': childData['gender'] ?? '', // 필드 확인
            'height': childData['height'] ?? 0.0,
            'weight': childData['weight'] ?? 0.0,
            'imageUrl': childData['profileImageUrl'] ?? '',
            'fullBodyImageUrl': childData['fullBodyImageUrl'] ?? '', // 전신사진 URL 추가
          };
        }).toList();

        setState(() {
          childrenProfiles = profiles.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        print('No children found for user: ${user.uid}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profiles: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 이미지 선택을 위한 함수 추가
  Future<String?> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      // 여기에 Firebase Storage 업로드 로직 추가
      // 업로드 후 URL 반환
      return image.path; // 임시로 경로 반환
    }
    return null;
  }


  void _showImagePickerDialog(BuildContext context, bool isProfileImage, Function(String) onImageSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isProfileImage ? '프로필 사진 선택' : '전신 사진 선택'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('갤러리에서 선택'),
                  onTap: () async {
                    Navigator.pop(context);
                    final String? imagePath = await _pickImage(ImageSource.gallery);
                    if (imagePath != null) {
                      // 여기서 이미지 경로를 URL로 변환하거나 처리
                      setState(() {  // 전체 화면 상태 업데이트
                        onImageSelected(imagePath);
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text('카메라로 촬영'),
                  onTap: () async {
                    Navigator.pop(context);
                    final String? imagePath = await _pickImage(ImageSource.camera);
                    if (imagePath != null) {
                      setState(() {  // 전체 화면 상태 업데이트
                        onImageSelected(imagePath);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // 프로필 사진과 전신사진 위젯 수정
  Widget _buildProfileImage(String imageUrl, Function(String) onImageChanged) {
    return GestureDetector(
      onTap: () => _showImagePickerDialog(context, true, onImageChanged),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: imageUrl.startsWith('http')
                ? NetworkImage(imageUrl) as ImageProvider
                : FileImage(File(imageUrl)),  // 로컬 파일 경로인 경우
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: Icon(Icons.edit, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBodyImage(String imageUrl, Function(String) onImageChanged) {
    return GestureDetector(
      onTap: () => _showImagePickerDialog(context, false, onImageChanged),
      child: Stack(
        alignment: Alignment.center,
        children: [
          imageUrl.startsWith('http')
              ? Image.network(
            imageUrl,
            height: 150,
            fit: BoxFit.contain,
          )
              : Image.file(
            File(imageUrl),
            height: 150,
            fit: BoxFit.contain,
          ),

          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: Icon(Icons.edit, size: 20),
            ),
          ),
        ],
      ),
    );
  }


  void _toggleSelecting() {
    setState(() {
      if (isSelecting) {
        _selectedProfileIndex = null;
      }
      isSelecting = !isSelecting;
    });
  }

  void _deleteSelectedProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedProfileIndex == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final childKey = childrenProfiles[_selectedProfileIndex!]['key'];
      if (childKey != null) {
        //await FirebaseDatabase.instance.ref('children/$childKey').remove();
        await FirebaseDatabase.instance
            .ref('users/${user.uid}/children/$childKey')
            .remove();
      }

      setState(() {
        childrenProfiles.removeAt(_selectedProfileIndex!);
        _selectedProfileIndex = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선택한 아이의 프로필이 삭제되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 중 오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editSelectedProfile() {
    if (_selectedProfileIndex == null) return;
    final selectedChild = childrenProfiles[_selectedProfileIndex!];


    String profileImageUrl = selectedChild['imageUrl'] ?? '';
    String fullBodyImageUrl = selectedChild['fullBodyImageUrl'] ?? '';



    showDialog(
      context: context,
      builder: (context) {
        // 기존 데이터를 가져와 초기화
        TextEditingController nameController = TextEditingController(text: selectedChild['name']);
        TextEditingController genderController = TextEditingController(text: selectedChild['gender']);
        TextEditingController birthDateController = TextEditingController(text: selectedChild['birthdate'] ?? '');
        TextEditingController weightController = TextEditingController(text: selectedChild['weight']?.toString() ?? '');
        TextEditingController heightController = TextEditingController(text: selectedChild['height']?.toString() ?? '');
        TextEditingController profileImageUrlController = TextEditingController(text: selectedChild['imageUrl'] ?? '');
        TextEditingController fullBodyImageUrlController = TextEditingController(text: selectedChild['fullBodyImageUrl'] ?? '');


        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2E4C4), // 원하는 배경색으로 변경하세요
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '프로필 정보',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // 프로필 사진
                            _buildProfileImage(
                              profileImageUrl,  // 상태 변수 사용
                                  (String newImageUrl) {
                                setDialogState(() {  // setDialogState 사용
                                  profileImageUrl = newImageUrl;  // 상태 변수 업데이트
                                  profileImageUrlController.text = newImageUrl;
                                });
                              },
                            ),
                            const SizedBox(height: 30),

                            // 이름 (수정 가능)
                            _buildEditableTextField('이름', nameController, true),
                            const SizedBox(height: 30),

                            // 생년월일 (수정 불가능)
                            _buildEditableTextField('생년월일', birthDateController,  false),
                            const SizedBox(height: 30),

                            // 성별 (수정 불가능)
                            _buildEditableTextField('성별', TextEditingController(text: selectedChild['gender']), false),
                            const SizedBox(height: 30),

                            // 키 (수정 가능)
                            _buildEditableTextField('키 (cm)', heightController,  true),
                            const SizedBox(height: 30),

                            // 체중 (수정 가능)
                            _buildEditableTextField('체중 (kg)', weightController,  true),
                            const SizedBox(height: 30),

                            // 전신 사진
                            _buildFullBodyImage(
                              fullBodyImageUrl,  // 상태 변수 사용
                                  (String newImageUrl) {
                                setDialogState(() {  // setDialogState 사용
                                  fullBodyImageUrl = newImageUrl;  // 상태 변수 업데이트
                                  fullBodyImageUrlController.text = newImageUrl;
                                });
                              },
                            ),

                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            final childKey = selectedChild['key'];
                            if (childKey == null) return;

                            try {
                              // 업데이트할 데이터 맵 생성
                              Map<String, dynamic> updates = {
                                'name': nameController.text,
                                'birthdate': birthDateController.text,
                                'gender': selectedChild['gender'],
                                'weight': double.tryParse(weightController.text) ?? 0.0,
                                'height': double.tryParse(heightController.text) ?? 0.0,
                                'profileImageUrl': profileImageUrl,
                                'fullBodyImageUrl': fullBodyImageUrl,
                              };

                              print('Updating child profile with key: $childKey');
                              print('Update data: $updates');

                              // Firebase 레퍼런스 생성
                              final DatabaseReference childRef = FirebaseDatabase.instance
                                  .ref()
                                  .child('users')
                                  .child(user.uid)
                                  .child('children')
                                  .child(childKey);

                              // 데이터 업데이트
                              await childRef.update(updates);

                              print('Firebase update successful');

                              // 로컬 상태 업데이트
                              setState(() {
                                childrenProfiles[_selectedProfileIndex!] = {
                                  'key': childKey,
                                  ...updates,
                                };
                              });

                              // 성공 메시지 표시
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('프로필이 성공적으로 수정되었습니다.'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // 프로필 목록 새로고침
                              await _loadChildrenProfiles();

                              // 다이얼로그 닫기
                              Navigator.pop(context);

                            } catch (e) {
                              print('Error updating profile: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('수정 중 오류 발생: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '저장',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // 닫기 버튼 (보라)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7165D6), // 보라색 배경
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // 둥근 모서리
                            ),
                          ),
                          child: const Text(
                            '닫기',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  // ✅ 수정 가능 여부에 따라 스타일 변경
  Widget _buildEditableTextField(String label, TextEditingController controller, bool isEditable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: !isEditable, // 수정 불가능한 필드는 읽기 전용
          enabled: isEditable, // 클릭 방지
          decoration: InputDecoration(
            filled: true,
            fillColor: isEditable ? Colors.white : Colors.grey.shade300, // 수정 불가능한 필드는 회색 배경
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }




// 정보를 표시하는 위젯
  Widget _buildDisplayRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value ?? ''),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4E8D0),
      body: Center(
        child: Container(
          width: screenSize.width * 0.9,
          height: screenSize.height * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFFFEFBF0),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0, bottom: 20.0),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/logo2.png',
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          right: 20,
                          bottom: 50,
                          child: GestureDetector(
                            onTap: () => context.go('/mypage'),
                            child: Image.asset(
                              'assets/images/mypage.png',
                              height: 45,
                              width: 45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : childrenProfiles.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '등록된 아이가 없습니다.\n아이를 등록해주세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Column(
                              children: const [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.add,
                                    size: 40,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '등록하기',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: childrenProfiles.length + 1,
                      itemBuilder: (context, index) {
                        if (index < childrenProfiles.length) {
                          final child = childrenProfiles[index];
                          final isSelected =
                              _selectedProfileIndex == index;

                          return GestureDetector(
                            onTap: () {
                              if (isSelecting) {
                                setState(() {
                                  _selectedProfileIndex =
                                  isSelected ? null : index;
                                });
                              } else {
                                context.go(
                                  '/main',
                                  extra: {
                                    'childName': child['name'],
                                    'childImage':
                                    child['imageUrl'],
                                    'childId': child['key'],
                                    'fullBodyImageUrl':
                                    child['fullBodyImageUrl'],
                                  },
                                );
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage: NetworkImage(
                                          child['imageUrl'] ?? ''),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      child['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelecting)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isSelected
                                          ? const Color(0xFF7165D6)
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        } else {
                          return GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: const [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.add,
                                    size: 40,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '등록하기',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelecting)
                        FloatingActionButton(
                          onPressed: _deleteSelectedProfile,
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                      const SizedBox(height: 10),
                      if (isSelecting)
                        FloatingActionButton(
                          onPressed: _editSelectedProfile,
                          backgroundColor: Colors.orange,
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        onPressed: _toggleSelecting,
                        backgroundColor: Color(0xFF7165D6),
                        child: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
