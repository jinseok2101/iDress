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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 정보
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

            // 이미지 섹션
            if (category == 'set' && historyData['onepieceUrl'] != null)
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.5,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    historyData['onepieceUrl'],
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else if (category == 'top_bottom')
              Column(
                children: [
                  if (historyData['topImageUrl'] != null)
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.network(
                          historyData['topImageUrl'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  if (historyData['bottomImageUrl'] != null)
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.network(
                          historyData['bottomImageUrl'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                ],
              ),

            // 추가 정보 섹션
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '피팅 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('피팅 타입', category == 'set' ? '한벌옷' : '일반 피팅'),
                  _buildInfoRow('저장 날짜', formattedDate),
                  // 필요한 경우 더 많은 정보를 추가할 수 있습니다
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}