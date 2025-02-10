import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FittingHistoryDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> historyData;
  final String category;

  const FittingHistoryDetailPage({
    Key? key,
    required this.historyData,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime date = DateTime.parse(historyData['date']);
    final String formattedDate = DateFormat('yyyy년 MM월 dd일 HH:mm').format(date);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '피팅 상세정보',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(  // SafeArea 추가
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 피팅 과정 표시
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '피팅 과정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        // 원본 의류 이미지
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '선택한 의류',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildOriginalImages(),
                            ],
                          ),
                        ),
                        // 화살표 아이콘
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.arrow_forward, color: Colors.blue),
                        ),
                        // 피팅 결과 이미지
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '피팅 결과',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildProcessedImage(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 확대보기 섹션
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '확대보기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildZoomableProcessedImage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalImages() {
    if (category == 'set' && historyData['originalImageUrl'] != null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            historyData['originalImageUrl'],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.error_outline, color: Colors.grey),
              );
            },
          ),
        ),
      );
    } else if (category == 'top_bottom') {
      return Column(
        children: [
          if (historyData['topImageUrl'] != null)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  historyData['topImageUrl'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.error_outline, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          if (historyData['bottomImageUrl'] != null) ...[
            SizedBox(height: 8),
            Icon(Icons.add, color: Colors.grey),
            SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  historyData['bottomImageUrl'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.error_outline, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      );
    }
    return Container();
  }

  Widget _buildProcessedImage() {
    if (historyData['processedImageUrl'] != null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            historyData['processedImageUrl'],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.error_outline, color: Colors.grey),
              );
            },
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildZoomableProcessedImage() {
    if (historyData['processedImageUrl'] != null) {
      return Container(
        width: double.infinity,
        height: 400,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.network(
            historyData['processedImageUrl'],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.error_outline, color: Colors.grey),
              );
            },
          ),
        ),
      );
    }
    return Container();
  }
}

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
