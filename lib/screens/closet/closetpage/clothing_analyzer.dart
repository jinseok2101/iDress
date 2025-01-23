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

  final List<String> seasons = ['봄', '여름', '가을', '겨울'];

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
                "text": """이 아기 옷을 분석해주세요:
1. 종류: '상의', '하의', '신발', '한벌옷' 중 하나로 알려주세요.
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

      print('API 요청 시작');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('API 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        print('AI 응답 텍스트: $text');

        return _parseAIResponse(text);
      } else {
        print('API 오류 상세: ${response.body}');
        return {
          'category': '상의',
          'color': '흰색',
          'seasons': ['봄'],
          'confidence': 0.8,
          'description': '이미지 분석에 실패했습니다. 수동으로 선택해주세요.',
          'memo': '',
        };
      }
    } catch (e) {
      print('분석 오류: $e');
      return {
        'category': '상의',
        'color': '흰색',
        'seasons': ['봄'],
        'confidence': 0.8,
        'description': '이미지 분석에 실패했습니다. 수동으로 선택해주세요.',
        'memo': '',
      };
    }
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    print('응답 파싱 시작');
    String category = '상의';
    String color = '흰색';
    Set<String> detectedSeasons = {'봄'}; // Set으로 변경하여 중복 방지
    String memo = '';

    // 응답을 줄 단위로 분리하고 소문자로 변환
    final lines = response.toLowerCase().split('\n');

    print('파싱 시작: ${lines.length}줄');

    for (var line in lines) {
      line = line.trim();
      print('처리 중인 라인: $line');

      // 카테고리 파싱
      if (line.startsWith('종류:')) {
        for (var cat in ['상의', '하의', '신발', '한벌옷']) {
          if (line.contains(cat.toLowerCase())) {
            category = cat;
            print('카테고리 감지: $cat');
            break;
          }
        }
      }

      // 색상 파싱
      if (line.startsWith('색상:')) {
        for (var col in colors) {
          if (line.contains(col.toLowerCase())) {
            color = col;
            print('색상 감지: $col');
            break;
          }
        }
      }

      // 계절 파싱 개선
      if (line.startsWith('계절:')) {
        detectedSeasons.clear(); // 기존 계절 정보 초기화
        print('계절 라인 감지: $line');

        for (var season in seasons) {
          if (line.contains(season.toLowerCase())) {
            detectedSeasons.add(season);
            print('계절 추가: $season');
          }
        }

        // 계절이 하나도 감지되지 않았다면 기본값 설정
        if (detectedSeasons.isEmpty) {
          // 옷의 특성에 따라 기본 계절 설정
          if (line.contains('두꺼운') || line.contains('따뜻한')) {
            detectedSeasons.add('겨울');
          } else if (line.contains('얇은') || line.contains('시원한')) {
            detectedSeasons.add('여름');
          } else {
            detectedSeasons.add('봄');
            detectedSeasons.add('가을');
          }
        }
      }

      // 상세 설명 파싱
      if (line.startsWith('상세:')) {
        memo = line.substring(line.indexOf(':') + 1).trim();
        // 여러 줄의 상세 설명을 하나로 합치기
        int i = lines.indexOf(line) + 1;
        while (i < lines.length && !lines[i].contains(':')) {
          if (lines[i].trim().isNotEmpty) {
            memo += ' ' + lines[i].trim();
          }
          i++;
        }
        print('메모 감지: $memo');
      }
    }

    print('파싱 결과:');
    print('카테고리: $category');
    print('색상: $color');
    print('계절: ${detectedSeasons.toList()}');
    print('메모: $memo');

    return {
      'category': category,
      'color': color,
      'seasons': detectedSeasons.toList(), // Set을 List로 변환
      'confidence': 0.9,
      'description': response,
      'memo': memo,
    };
  }

  void dispose() {}
}