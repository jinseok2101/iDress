import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoticePage extends StatelessWidget {
  const NoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
        title: const Text(
          '공지사항',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.go('/mypage');
          },
        ),
      ),
      body: ListView(
        children: [
          // ExpansionTile을 감싸는 Container를 추가하여 배경색을 흰색으로 변경
          Container(
            color: Colors.white, // 배경색을 흰색으로 설정
            child: ExpansionTile(
              title: const Text('앱 버전 업데이트 안내'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('공지사항 내용 1'),
                ),
              ],
            ),
          ),
          // 다른 ExpansionTile들도 같은 방식으로 감싸기
          Container(
            color: Colors.white,
            child: ExpansionTile(
              title: const Text('서버 점검 안내'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('공지사항 내용 2'),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: ExpansionTile(
              title: const Text('IDress 이벤트 안내'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('공지사항 내용 3'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
