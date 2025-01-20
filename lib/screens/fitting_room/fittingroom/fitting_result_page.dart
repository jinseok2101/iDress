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
            height: MediaQuery.of(context).size.height * 0.65,
            margin: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
            child: isOnepiece  // 한벌옷인 경우와 상하의인 경우를 구분
                ? Image.file(
              topImageFile,  // 한벌옷인 경우 topImageFile만 사용
              fit: BoxFit.contain,
            )
                : Column(  // 상하의인 경우 둘 다 표시
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

          // 하단 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        height: 90,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 34,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}