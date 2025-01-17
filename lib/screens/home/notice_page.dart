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
          ExpansionTile(
            title: const Text('공지사항 1'),
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('공지사항 내용 1'),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('공지사항 2'),
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('공지사항 내용 2'),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('공지사항 3'),
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('공지사항 내용 3'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
