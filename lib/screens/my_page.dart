import 'dart:io'; // File을 사용하려면 import 필요
import 'package:flutter/material.dart';
import 'package:last3/screens/authentication/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 선택을 위한 패키지 추가

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String username = '';
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 사용자 데이터를 로드하는 함수
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final databaseRef = FirebaseDatabase.instance.ref("users/${user.uid}");
        final snapshot = await databaseRef.get();

        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            username = data['username'] ?? '';
            profileImageUrl = data['profileImageUrl'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 이미지 선택 함수
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // 선택한 이미지를 로컬에 저장하고, 해당 경로를 profileImageUrl에 저장
      setState(() {
        profileImageUrl = pickedFile.path;
      });

      // Firebase에 새로운 프로필 이미지 URL 업데이트
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final databaseRef = FirebaseDatabase.instance.ref("users/${user.uid}");
        await databaseRef.update({
          'profileImageUrl': pickedFile.path, // 로컬 파일 경로 저장
        });
      }
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 20, bottom: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Page',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // 프로필 섹션
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,  // 프로필 이미지 클릭 시 사진 변경
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: profileImageUrl != null
                              ? (profileImageUrl!.startsWith('http')  // URL인지 확인
                              ? NetworkImage(profileImageUrl!)  // URL이면 NetworkImage 사용
                              : FileImage(File(profileImageUrl!))  // 로컬 파일이면 FileImage 사용
                          )
                              : const AssetImage('assets/profile.jpg') as ImageProvider,  // 기본 프로필 이미지
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 프로필 편집 텍스트에 GestureDetector 추가하여 클릭 시 이미지 변경
                  GestureDetector(
                    onTap: _pickImage,  // "프로필 편집" 클릭 시 이미지 선택
                    child: const Text(
                      '프로필 편집',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$username님, 반갑습니다!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 메뉴 리스트
            _buildMenuItem(Icons.checkroom, '나의 아이 옷장'),
            _buildMenuItem(Icons.person_outline, '개인 정보'),
            _buildMenuItem(Icons.notifications_none, '알림 설정'),
            _buildMenuItem(Icons.campaign_outlined, '공지 사항'),

            const SizedBox(height: 20),

            // 약관 및 정책 섹션
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Text(
                      '약관 및 정책',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPolicyItem('서비스 이용 약관', context),
                  _buildPolicyItem('개인 정보 처리 방침', context),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 로그아웃 및 계정 탈퇴 섹션
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                children: [
                  _buildPolicyItem('로그아웃', context),
                  _buildPolicyItem('계정 탈퇴', context),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildPolicyItem(String title, BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          if (title == '로그아웃') {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final authService = Auth();
                        await authService.logout(context);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                );
              },
            );
          } else if (title == '계정 탈퇴') {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('계정 탈퇴'),
                  content: const Text(
                    '계정을 탈퇴하면 모든 데이터가 삭제되며 복구할 수 없습니다.\n정말 탈퇴하시겠습니까?',
                    style: TextStyle(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // 첫 번째 다이얼로그 닫기

                        // 로딩 표시
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );

                        final authService = Auth();
                        await authService.deleteAccount(context);

                        // 로딩 다이얼로그 닫기
                      },
                      child: const Text(
                        '탈퇴',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: title == '계정 탈퇴' ? Colors.red : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
