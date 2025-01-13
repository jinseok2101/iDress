import 'package:flutter/material.dart';
import 'package:last3/screens/authentication/auth_service.dart';
import 'package:go_router/go_router.dart';
class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/home'), // 홈으로 이동
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // My Page 헤더
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
                  // 프로필 이미지
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('assets/profile.jpg'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '프로필 편집',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '[ 사용자 이름 ]님, 반갑습니다!',
                    style: TextStyle(
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

            // 하단 네비게이션
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.photo_library, '피팅룸'),
                    _buildNavItem(Icons.home, '홈'),
                    _buildNavItem(Icons.person, '마이페이지'),
                  ],
                ),
              ),
            ),
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
                        if (context.mounted) {
                          Navigator.pop(context);

                          // 성공 메시지 표시
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('탈퇴 완료'),
                                content: const Text('계정이 성공적으로 탈퇴되었습니다.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('확인'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
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

  Widget _buildNavItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}