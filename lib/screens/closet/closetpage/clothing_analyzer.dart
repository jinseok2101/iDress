import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ClothingAnalyzer {
  static const String apiKey = 'AIzaSyD_oUTlk13g6B6oNopJ6ptX0O3-IKAjvgo';
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

  final List<String> colors = [
    '흰색', '검정', '빨강', '주황', '노랑',
    '초록', '파랑', '남색', '보라', '회색', '분홍', '갈색'
  ];

  final List<String> seasons = ['봄', '여름', '가을', '겨울'];

  Future<Map<String, dynamic>> analyzeClothing(String imagePath) async {
    try {
      print('이미지 분석 시작');

      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('이미지 파일을 찾을 수 없습니다');
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final body = {
        "contents": [
          {
            "parts": [
              {
                "text": """이 아기 옷을 분석해주세요:
1. 종류: '아우터', '상의', '하의', '신발', '올인원' 중 하나로 알려주세요.
2. 색상: '흰색', '검정', '빨강', '주황', '노랑', '초록', '파랑', '남색', '보라', '회색', '분홍', '갈색' 중 주된 색상 하나만 알려주세요.
3. 계절: '봄', '여름', '가을', '겨울' 중에서 적합한 계절을 모두 알려주세요. (여러 계절 선택 가능)
4. 상세: 옷의 재질(면, 니트, 데님 등), 무늬(체크, 스트라이프 등), 디자인 특징을 자세히 설명해주세요.

다음 형식으로 답변해주세요:
종류: [카테고리]
색상: [색상]
계절: [적합한 계절들을 쉼표로 구분하여 나열]
상세: [재질, 무늬, 특징에 대한 상세 설명]"""
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "safety_settings": {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_NONE"
        },
        "generation_config": {
          "temperature": 0.4,
          "top_k": 32,
          "top_p": 1,
          "max_output_tokens": 1024,
          "stop_sequences": []
        }
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        print('AI 분석 결과:\n$text');
        return _parseAIResponse(text);
      } else {
        print('API 오류: ${response.statusCode}');
        return _getDefaultResponse();
      }
    } catch (e) {
      print('분석 오류: $e');
      return _getDefaultResponse();
    }
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    String category = '상의';
    String color = '흰색';
    Set<String> detectedSeasons = {'봄'};
    String memo = '';

    final lines = response.toLowerCase().split('\n');

    for (var line in lines) {
      line = line.trim();

      if (line.startsWith('종류:')) {
        for (var cat in ['아우터', '상의', '하의', '신발', '올인원']) {
          if (line.contains(cat.toLowerCase())) {
            category = cat;
            break;
          }
        }
      } else if (line.startsWith('색상:')) {
        for (var col in colors) {
          if (line.contains(col.toLowerCase())) {
            color = col;
            break;
          }
        }
      } else if (line.startsWith('계절:')) {
        detectedSeasons.clear();
        for (var season in seasons) {
          if (line.contains(season.toLowerCase())) {
            detectedSeasons.add(season);
          }
        }
        if (detectedSeasons.isEmpty) {
          if (line.contains('두꺼운') || line.contains('따뜻한')) {
            detectedSeasons.add('겨울');
          } else if (line.contains('얇은') || line.contains('시원한')) {
            detectedSeasons.add('여름');
          } else {
            detectedSeasons.add('봄');
            detectedSeasons.add('가을');
          }
        }
      } else if (line.startsWith('상세:')) {
        memo = line.substring(line.indexOf(':') + 1).trim();
        int i = lines.indexOf(line) + 1;
        while (i < lines.length && !lines[i].contains(':')) {
          if (lines[i].trim().isNotEmpty) {
            memo += ' ' + lines[i].trim();
          }
          i++;
        }
      }
    }

    print('분석 완료: $category, $color, ${detectedSeasons.toList()}');

    return {
      'category': category,
      'color': color,
      'seasons': detectedSeasons.toList(),
      'confidence': 0.9,
      'description': response,
      'memo': memo,
    };
  }

  Map<String, dynamic> _getDefaultResponse() {
    return {
      'category': '상의',
      'color': '흰색',
      'seasons': ['봄'],
      'confidence': 0.8,
      'description': '이미지 분석에 실패했습니다. 수동으로 선택해주세요.',
      'memo': '',
    };
  }

  void dispose() {}
}