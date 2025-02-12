import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'fitting_result_page.dart';

class FittingLoadingPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final dynamic topImage;
  final dynamic bottomImage;
  final String? topImageUrl;
  final String? bottomImageUrl;
  final bool isOnepiece;
  final bool isFromCloset;
  final String clothType;

  const FittingLoadingPage({
    Key? key,
    required this.childInfo,
    this.topImage,
    this.bottomImage,
    this.topImageUrl,
    this.bottomImageUrl,
    required this.isOnepiece,
    required this.isFromCloset,
    required this.clothType,
  }) : super(key: key);

  @override
  State<FittingLoadingPage> createState() => _FittingLoadingPageState();
}

class _FittingLoadingPageState extends State<FittingLoadingPage> {
  Future<List<int>> _downloadImageBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  }

  Future<File> _tryOn() async {
    if (widget.childInfo['fullBodyImageUrl'] == null) {
      throw Exception('아이의 전신 이미지가 없습니다.');
    }

    bool hasTopImage = widget.topImage != null || widget.topImageUrl != null;
    bool hasBottomImage = widget.bottomImage != null || widget.bottomImageUrl != null;

    if (widget.clothType == '상의+하의') {
      if (!hasTopImage || !hasBottomImage) {
        throw Exception('상의와 하의 이미지를 모두 업로드해야 합니다.');
      }
    } else {
      if (!hasTopImage && !hasBottomImage) {
        throw Exception('상의 또는 하의 이미지를 업로드해야 합니다.');
      }
    }

    try {
      final humanBytes = await _downloadImageBytes(widget.childInfo['fullBodyImageUrl']);
      File? tempFile;

      if (widget.clothType == '상의+하의') {
        final url = 'http://34.64.72.171/try-on-full-outfit';
        var request = http.MultipartRequest('POST', Uri.parse(url));

        request.files.add(
            http.MultipartFile.fromBytes(
                'human_image',
                humanBytes,
                filename: 'human_image.png'
            )
        );

        // 상의 이미지 처리
        if (widget.topImage != null) {
          request.files.add(await http.MultipartFile.fromPath('top_image', widget.topImage.path));
        } else if (widget.topImageUrl != null) {
          final bytes = await _downloadImageBytes(widget.topImageUrl!);
          request.files.add(
              http.MultipartFile.fromBytes(
                  'top_image',
                  bytes,
                  filename: 'top_image.png'
              )
          );
        }

        // 하의 이미지 처리
        if (widget.bottomImage != null) {
          request.files.add(await http.MultipartFile.fromPath('bottom_image', widget.bottomImage.path));
        } else if (widget.bottomImageUrl != null) {
          final bytes = await _downloadImageBytes(widget.bottomImageUrl!);
          request.files.add(
              http.MultipartFile.fromBytes(
                  'bottom_image',
                  bytes,
                  filename: 'bottom_image.png'
              )
          );
        }

        final response = await request.send();
        if (response.statusCode != 200) {
          throw Exception('서버 에러: ${response.statusCode}');
        }

        final tempDir = await getTemporaryDirectory();
        tempFile = File('${tempDir.path}/result.png');
        await response.stream.pipe(tempFile.openWrite());
      } else {
        final url = 'http://34.64.72.171/try-on';
        var request = http.MultipartRequest('POST', Uri.parse(url));

        request.files.add(
            http.MultipartFile.fromBytes(
                'human_image',
                humanBytes,
                filename: 'human_image.png'
            )
        );

        // 단일 의류 처리
        if (widget.topImage != null) {
          request.files.add(await http.MultipartFile.fromPath('garment_image', widget.topImage.path));
        } else if (widget.bottomImage != null) {
          request.files.add(await http.MultipartFile.fromPath('garment_image', widget.bottomImage.path));
        } else if (widget.topImageUrl != null) {
          final bytes = await _downloadImageBytes(widget.topImageUrl!);
          request.files.add(
              http.MultipartFile.fromBytes(
                  'garment_image',
                  bytes,
                  filename: 'garment_image.png'
              )
          );
        } else if (widget.bottomImageUrl != null) {
          final bytes = await _downloadImageBytes(widget.bottomImageUrl!);
          request.files.add(
              http.MultipartFile.fromBytes(
                  'garment_image',
                  bytes,
                  filename: 'garment_image.png'
              )
          );
        }

        String serverClothType = widget.clothType == '하의' ? 'lower_body' :
        widget.clothType == '올인원' ? 'jumpsuit' :
        'upper_body';

        request.fields['cloth_type'] = serverClothType;

        final response = await request.send();
        if (response.statusCode != 200) {
          final responseText = await response.stream.bytesToString();
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

  Future<List<String>> _recommand() async {
    try {
      if (widget.clothType == '상의+하의') {
        final url = 'http://34.64.72.171/search-similar-full';
        var request = http.MultipartRequest('POST', Uri.parse(url));

        // 상의 이미지 처리
        if (widget.topImage != null) {
          request.files.add(await http.MultipartFile.fromPath('top_image', widget.topImage.path));
        } else if (widget.topImageUrl != null) {
          final bytes = await _downloadImageBytes(widget.topImageUrl!);
          request.files.add(
              http.MultipartFile.fromBytes(
                  'top_image',
                  bytes,
                  filename: 'top_image.png'
              )
          );
        }

        // 하의 이미지 처리
        if (widget.bottomImage != null) {
          request.files.add(await http.MultipartFile.fromPath('bottom_image', widget.bottomImage.path));
        } else if (widget.bottomImageUrl != null) {
          final bytes = await _downloadImageBytes(widget.bottomImageUrl!);
          request.files.add(
              http.MultipartFile.fromBytes(
                  'bottom_image',
                  bytes,
                  filename: 'bottom_image.png'
              )
          );
        }

        final response = await request.send();
        if (response.statusCode != 200) {
          throw Exception('서버 에러: ${response.statusCode}');
        }

        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);
        return List<String>.from(jsonResponse['similar_items']);

      } else {
        final url = 'http://34.64.72.171/search-similar';
        var request = http.MultipartRequest('POST', Uri.parse(url));

        if (widget.topImage != null) {
          request.files.add(await http.MultipartFile.fromPath('garment_image', widget.topImage.path));
        } else if (widget.bottomImage != null) {
          request.files.add(await http.MultipartFile.fromPath('garment_image', widget.bottomImage.path));
        } else if (widget.topImageUrl != null) {
          final bytes = await _downloadImageBytes(widget.topImageUrl!);
          request.files.add(
              http.MultipartFile.fromBytes(
                  'garment_image',
                  bytes,
                  filename: 'garment_image.png'
              )
          );
        } else if (widget.bottomImageUrl != null) {
          final bytes = await _downloadImageBytes(widget.bottomImageUrl!);
          request.files.add(
              http.MultipartFile.fromBytes(
                  'garment_image',
                  bytes,
                  filename: 'garment_image.png'
              )
          );
        }

        String serverClothType = widget.clothType == '하의' ? 'lower_body' :
        widget.clothType == '올인원' ? 'jumpsuit' :
        'upper_body';

        request.fields['cloth_type'] = serverClothType;

        final response = await request.send();
        if (response.statusCode != 200) {
          throw Exception('서버 에러: ${response.statusCode}');
        }

        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);
        return List<String>.from(jsonResponse['similar_items']);
      }
    } catch (e) {
      print('추천 시스템 에러 발생: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();

    _tryOn().then((processedImage) {
      return _recommand().then((recommendedItems) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FittingResultPage(
                childInfo: widget.childInfo,
                topImage: widget.topImage ?? widget.topImageUrl,
                bottomImage: widget.bottomImage ?? widget.bottomImageUrl,
                processedImage: processedImage,
                recommendedItems: recommendedItems,
                isOnepiece: widget.isOnepiece,
                isFromCloset: widget.isFromCloset,
              ),
            ),
          );
        }
      });
    }).catchError((error) {
      print('Error in processing: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리 중 오류가 발생했습니다: $error')),
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