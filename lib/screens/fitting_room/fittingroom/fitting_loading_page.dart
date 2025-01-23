import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'fitting_result_page.dart';
import 'package:path_provider/path_provider.dart';

class FittingLoadingPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final dynamic topImage;
  final dynamic bottomImage;
  final bool isOnepiece;
  final bool isFromCloset;
  final String? humanImageBase64;
  final String? garmentImageBase64;

  const FittingLoadingPage({
    Key? key,
    required this.childInfo,
    this.topImage,
    this.bottomImage,
    required this.isOnepiece,
    required this.isFromCloset,
    this.humanImageBase64,
    this.garmentImageBase64,
  }) : super(key: key);

  @override
  State<FittingLoadingPage> createState() => _FittingLoadingPageState();
}

class _FittingLoadingPageState extends State<FittingLoadingPage> {
  String _loadingMessage = '아이에게 옷을 입히는 중이에요!';
  bool _isProcessing = true;
  final int _maxRetries = 3;
  int _currentRetry = 0;

  @override
  void initState() {
    super.initState();
    _startImageProcessing();
  }

  Future<void> _startImageProcessing() async {
    try {
      setState(() {
        _loadingMessage = '이미지 처리 요청 중...';
        _isProcessing = true;
      });

      final client = http.Client();
      try {
        final uploadUrl = Uri.parse('http://34.64.206.26:80/upload');

        print('요청 시작 - 시도 ${_currentRetry + 1}/$_maxRetries');
        print('Human Image Base64 길이: ${widget.humanImageBase64?.length}');
        print('Garment Image Base64 길이: ${widget.garmentImageBase64?.length}');

        // 요청 생성
        final request = http.Request('POST', uploadUrl);
        request.headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        });
        request.body = jsonEncode({
          'human_image': widget.humanImageBase64,
          'garment_image': widget.garmentImageBase64,
        });

        // 스트림 응답 받기
        final streamedResponse = await client.send(request).timeout(
          Duration(minutes: 3),  // 타임아웃 시간 3분으로 증가
          onTimeout: () {
            throw TimeoutException('서버 응답 시간이 초과되었습니다');
          },
        );

        print('응답 수신 시작: ${streamedResponse.statusCode}');

        if (streamedResponse.statusCode == 200) {
          setState(() {
            _loadingMessage = '처리된 이미지 다운로드 중...';
          });

          // 응답 데이터를 메모리에 한번에 받지 않고 청크로 받기
          final List<int> bytes = [];
          await for (final chunk in streamedResponse.stream) {
            bytes.addAll(chunk);
            print('청크 수신: ${chunk.length} bytes');
          }

          print('전체 데이터 수신 완료: ${bytes.length} bytes');

          final responseString = utf8.decode(bytes);
          final responseData = jsonDecode(responseString);

          if (!responseData.containsKey('result_image')) {
            throw Exception('서버 응답에 결과 이미지가 없습니다');
          }

          setState(() {
            _loadingMessage = '이미지 저장 중...';
          });

          final String resultBase64 = responseData['result_image'];
          final imageBytes = base64Decode(resultBase64);
          final tempDir = await getTemporaryDirectory();
          final processedImageFile = File('${tempDir.path}/processed_image.jpg');
          await processedImageFile.writeAsBytes(imageBytes);

          print('이미지 파일 저장 완료: ${processedImageFile.path}');
          print('파일 존재 여부: ${await processedImageFile.exists()}');
          print('파일 크기: ${await processedImageFile.length()} bytes');

          setState(() {
            _loadingMessage = '피팅 완료!';
            _isProcessing = false;
          });

          if (mounted) {
            await Future.delayed(Duration(milliseconds: 500));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FittingResultPage(
                  childInfo: widget.childInfo,
                  topImage: widget.topImage,
                  bottomImage: widget.bottomImage,
                  isOnepiece: widget.isOnepiece,
                  isFromCloset: widget.isFromCloset,
                  processedImage: processedImageFile,
                ),
              ),
            );
          }
        } else {
          throw Exception('서버 오류: ${streamedResponse.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('이미지 처리 오류: $e');

      // 재시도 로직
      if (_currentRetry < _maxRetries - 1) {
        _currentRetry++;
        print('재시도 $_currentRetry 시작');
        setState(() {
          _loadingMessage = '재시도 중... ($_currentRetry/$_maxRetries)';
        });
        await Future.delayed(Duration(seconds: 2));
        return _startImageProcessing();
      } else {
        setState(() {
          _loadingMessage = '오류가 발생했습니다';
          _isProcessing = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('오류'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('이미지 처리 중 문제가 발생했습니다.'),
                    SizedBox(height: 8),
                    Text(
                      '오류 내용: ${e.toString()}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('취소'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('다시 시도'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _currentRetry = 0;
                      _startImageProcessing();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checkroom, size: 50, color: Colors.blue),
                SizedBox(height: 30),

                if (_isProcessing) ...[
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 30),
                ],

                Text(
                  _loadingMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 10),

                if (_isProcessing)
                  Text(
                    '잠시만 기다려주세요...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),

                if (!_isProcessing && _loadingMessage.contains('오류'))
                  ElevatedButton(
                    onPressed: _startImageProcessing,  // 여기를 수정
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text('다시 시도'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}