import 'package:flutter/material.dart';
import 'dart:io';

class FittingResultPage extends StatelessWidget {
  final File topImageFile;
  final File bottomImageFile;
  final bool isOnepiece;  // 한벌옷인지 여부를 확인하는 변수 추가

  const FittingResultPage({
    Key? key,
    required this.topImageFile,
    required this.bottomImageFile,
    this.isOnepiece = false,  // 기본값은 false (상하의 분리)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom, color: Colors.black),
            SizedBox(width: 8),
            Text(
              '피팅완료!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 메인 이미지 영역
          Container(
            height: MediaQuery.of(context).size.height * 0.75,  // 높이 증가
            margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),  // 하단 마진 감소
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: isOnepiece
                ? Image.file(
              topImageFile,
              fit: BoxFit.contain,
            )
                : Column(
              children: [
                Expanded(
                  child: topImageFile.path.isEmpty
                      ? Center(child: Text('상의를 선택하지 않았습니다'))
                      : Image.file(
                    topImageFile,
                    fit: BoxFit.contain,
                  ),
                ),
                Expanded(
                  child: bottomImageFile.path.isEmpty
                      ? Center(child: Text('하의를 선택하지 않았습니다'))
                      : Image.file(
                    bottomImageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          // Spacer 추가하여 버튼들을 아래로 밀기
          Spacer(),

          // 하단 버튼들
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),  // 하단 패딩 추가
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.download,
                  label: '다운로드',
                  onTap: () {
                    // 다운로드 기능 구현
                  },
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: '공유하기',
                  onTap: () {
                    // 공유 기능 구현
                  },
                ),
                _buildActionButton(
                  icon: Icons.save_alt,
                  label: '보관하기',
                  onTap: () {
                    // 보관하기 기능 구현
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,  // 아이콘 크기 감소
            color: Colors.black87,
          ),
          const SizedBox(height: 4),  // 간격 감소
          Text(
            label,
            style: TextStyle(
              fontSize: 12,  // 글자 크기 감소
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}