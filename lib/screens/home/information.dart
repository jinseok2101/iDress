import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  String username = '';  // 사용자 이름
  String phone = '';  // 전화번호
  bool isLoading = true;  // 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadUserData();  // Firebase에서 사용자 데이터 로드
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final databaseRef = FirebaseDatabase.instance.ref("users/${user.uid}");
        final snapshot = await databaseRef.get();

        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;

          // Firebase에서 받아온 데이터를 정확하게 처리
          setState(() {
            username = data['username'] ?? '';  // 사용자 이름
            phone = data['phone'] ?? '';  // 전화번호
            isLoading = false;  // 데이터 로드 완료
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        isLoading = false;  // 에러 발생 시 로딩 종료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "개인 정보",
          style: TextStyle(
            fontSize: 22,  // 제목 글씨 크기 키우기
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFDF6F0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.go('/mypage');  // 뒤로가기 버튼을 눌렀을 때 마이페이지로 이동
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())  // 로딩 중에는 스피너 표시
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,  // 왼쪽 정렬
            children: [
              // 사용자 이름 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '사용자명:',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),  // 항목 간 간격

              // 전화번호 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '전화번호:',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFDF6F0),  // 배경색을 mypage와 동일하게 설정
    );
  }
}
