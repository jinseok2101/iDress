import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'fitting_result_page.dart';

class FittingLoadingPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final dynamic topImage;
  final dynamic bottomImage;
  final bool isOnepiece;
  final bool isFromCloset;
  final String clothType;

  const FittingLoadingPage({
    Key? key,
    required this.childInfo,
    this.topImage,
    this.bottomImage,
    required this.isOnepiece,
    required this.isFromCloset,
    required this.clothType,
  }) : super(key: key);

  @override
  State<FittingLoadingPage> createState() => _FittingLoadingPageState();
}

class _FittingLoadingPageState extends State<FittingLoadingPage> {

  Future<String> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/human_image.jpg');
    await tempFile.writeAsBytes(response.bodyBytes);
    return tempFile.path;
  }

  Future<File> _tryOn() async {
    if (widget.childInfo['fullBodyImageUrl'] == null) {
      throw Exception('아이의 전신 이미지가 없습니다.');
    }

    if (widget.clothType == '상의+하의') {
      if (widget.topImage == null || widget.bottomImage == null) {
        throw Exception('상의와 하의 이미지를 모두 업로드해야 합니다.');
      }
    } else {
      if (widget.topImage == null && widget.bottomImage == null) {
        throw Exception('상의 또는 하의 이미지를 업로드해야 합니다.');
      }
    }

    final url = 'http://34.47.104.167/try-on';
    var request = http.MultipartRequest('POST', Uri.parse(url));

    try {
      print('요청 시작: $url');
      final humanImagePath = await _downloadImage(widget.childInfo['fullBodyImageUrl']);
      request.files.add(await http.MultipartFile.fromPath('human_image', humanImagePath));

      File? tempFile;

      if (widget.clothType == '상의+하의') {
        final fullOutfitUrl = 'http://34.47.104.167/try-on-full-outfit';
        var fullRequest = http.MultipartRequest('POST', Uri.parse(fullOutfitUrl));

        fullRequest.files.addAll([
          await http.MultipartFile.fromPath('human_image', humanImagePath),
          await http.MultipartFile.fromPath('top_image', widget.topImage.path),
          await http.MultipartFile.fromPath('bottom_image', widget.bottomImage.path)
        ]);

        final response = await fullRequest.send();
        print('응답 코드: ${response.statusCode}');

        final tempDir = await getTemporaryDirectory();
        tempFile = File('${tempDir.path}/result.png');
        await response.stream.pipe(tempFile.openWrite());

      } else {
        request.files.add(await http.MultipartFile.fromPath(
            'garment_image',
            widget.topImage?.path ?? widget.bottomImage.path
        ));

        String serverClothType = widget.clothType == '상의' ? 'upper_body' :
        widget.clothType == '하의' ? 'lower_body' :
        'jumpsuit';
        request.fields['cloth_type'] = serverClothType;
        print('cloth_type: $serverClothType');

        final response = await request.send();
        print('응답 코드: ${response.statusCode}');

        if (response.statusCode != 200) {
          final responseText = await response.stream.bytesToString();
          print('에러 응답: $responseText');
          throw Exception('서버 에러: ${response.statusCode}');
        }

        final tempDir = await getTemporaryDirectory();
        tempFile = File('${tempDir.path}/result.png');
        await response.stream.pipe(tempFile.openWrite());
      }

      return tempFile;

    } catch (e) {
      print('에러 발생: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _tryOn().then((resultImage) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FittingResultPage(
            childInfo: widget.childInfo,
            topImage: widget.topImage,
            bottomImage: widget.bottomImage,
            processedImage: resultImage,
            isOnepiece: widget.isOnepiece,
            isFromCloset: widget.isFromCloset,
          ),
        ),
      );
    }).catchError((error) {
      print('Error in _tryOn: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('피팅 중 오류가 발생했습니다: $error')),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Icon(Icons.checkroom, size: 40, color: Colors.black),
            SizedBox(height: 8),
            Text(
              widget.isFromCloset ? '옷장 피팅' : '피팅룸',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(height: 40),
                    Text(
                      '아이에게 옷을 입히는 중이에요!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}