// fitting_result_page.dart
import 'package:flutter/material.dart';

class FittingResultPage extends StatelessWidget {
  const FittingResultPage({super.key});

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
          // 결과 이미지 표시 영역
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text(
                  '[ 합성 결과 표시 ]',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 하단 버튼들
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 다운로드 버튼
                IconButton(
                  onPressed: () {
                    // 다운로드 기능 구현
                  },
                  icon: const Icon(
                    Icons.download,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 40),
                // 공유 버튼
                IconButton(
                  onPressed: () {
                    // 공유 기능 구현
                  },
                  icon: const Icon(
                    Icons.share,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}