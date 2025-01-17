import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ClothingAnalyzer {
  static const String apiKey = 'AIzaSyD_oUTlk13g6B6oNopJ6ptX0O3-IKAjvgo';
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

  final List<String> colors = [
    '흰색', '검정', '빨강', '주황', '노랑',
    '초록', '파랑', '남색', '보라', '회색', '분홍', '갈색'
  ];

  Future<Map<String, dynamic>> analyzeClothing(String imagePath) async {
    try {
      print('분석 시작');
      print('이미지 경로: $imagePath');

      final file = File(imagePath);
      if (!await file.exists()) {
        print('이미지 파일이 존재하지 않습니다');
        throw Exception('이미지 파일을 찾을 수 없습니다');
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      print('이미지 인코딩 완료: ${base64Image.length} 바이트');

      final body = {
        "contents": [
          {
            "parts": [
              {
                "text": "이 아기 옷의 종류와 색상을 분석해주세요. 종류는 '상의', '하의', '신발', '한벌옷' 중 하나로, 색상은 '흰색', '검정', '빨강', '주황', '노랑', '초록', '파랑', '남색', '보라', 회색', '분홍', '갈색' 중 하나로 알려주세요. 옷의 바탕이 되는 색으로 색상을 알려주세요. 굳이 정확한 색깔을 말해줄 필요는 없습니다."
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

      print('API 요청 시작');
      print('요청 URL: $apiUrl');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('API 응답 코드: ${response.statusCode}');
      print('API 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        print('AI 응답 텍스트: $text');

        return _parseAIResponse(text);
      } else {
        print('API 오류 상세: ${response.body}');
        // 오류 시 기본값 반환
        return {
          'category': '상의',  // 기본값
          'color': '흰색',    // 기본값
          'confidence': 0.8,
          'description': '이미지 분석에 실패했습니다. 수동으로 선택해주세요.',
        };
      }
    } catch (e) {
      print('분석 오류: $e');
      return {
        'category': '상의',  // 기본값
        'color': '흰색',    // 기본값
        'confidence': 0.8,
        'description': '이미지 분석에 실패했습니다. 수동으로 선택해주세요.',
      };
    }
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    print('응답 파싱 시작');
    String category = '상의';  // 기본값
    String color = '흰색';    // 기본값
    String memo = '';        // 메모 추가
    String description = '';

    // 응답에서 ** 마크업 제거
    response = response.replaceAll('*', '');

    final categories = ['상의', '하의', '신발', '한벌옷'];
    for (var cat in categories) {
      if (response.toLowerCase().contains(cat)) {
        category = cat;
        print('카테고리 감지: $cat');
        break;
      }
    }

    for (var col in colors) {
      if (response.toLowerCase().contains(col)) {
        color = col;
        print('색상 감지: $col');
        break;
      }
    }

    // 설명 부분 추출 (마지막 문장을 메모로 사용)
    final sentences = response.split('.');
    for (var sentence in sentences) {
      sentence = sentence.trim();
    }

    if (sentences.length > 1) {
      // 마지막 문장이 비어있지 않은 경우에만 메모로 사용
      final lastSentence = sentences.last.trim();
      if (lastSentence.isNotEmpty) {
        memo = lastSentence;
      } else if (sentences.length > 2) {
        // 마지막 문장이 비어있다면 그 전 문장 사용
        memo = sentences[sentences.length - 2].trim();
      }
    }

    return {
      'category': category,
      'color': color,
      'confidence': 0.9,
      'description': response,
      'memo': memo,  // 메모 추가
    };
  }

  void dispose() {}
}