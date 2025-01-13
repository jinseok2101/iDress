import 'package:flutter/material.dart';
import 'fitting_result_page.dart';

class FittingRoomPage extends StatelessWidget {
  const FittingRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: const Text(
          '피팅룸',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // 첫 번째 이미지 업로드 영역
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(30), // padding 증가
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Container(
                  width: 150, // 너비 증가
                  height: 150, // 높이 증가
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 70, // 아이콘 크기 증가
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  '아이 사진을\n업로드 해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // + 아이콘
          const SizedBox(height: 20),
          const Icon(
            Icons.add,
            size: 30,
            color: Colors.black,
          ),
          const SizedBox(height: 20),

          // 두 번째 이미지 업로드 영역
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(30), // padding 증가
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Container(
                  width: 150, // 너비 증가
                  height: 150, // 높이 증가
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 70, // 아이콘 크기 증가
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  '아이가 입을 옷 사진을\n업로드 해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // 입어보기 버튼
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // 결과 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FittingResultPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9999),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '입어보기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}