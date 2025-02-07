import 'package:flutter/material.dart';
import 'dart:io';
import '../fitting_room_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class FittingResultPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final dynamic topImage;
  final dynamic bottomImage;
  final bool isOnepiece;
  final bool isFromCloset;
  final File? processedImage;
  final List<String> recommendedItems;

  const FittingResultPage({
    Key? key,
    required this.childInfo,
    required this.topImage,
    required this.bottomImage,
    this.isOnepiece = false,
    this.isFromCloset = false,
    required this.processedImage,
    required this.recommendedItems,
  }) : super(key: key);

  @override
  State<FittingResultPage> createState() => _FittingResultPageState();
}

class _FittingResultPageState extends State<FittingResultPage> {
  @override
  void initState() {
    super.initState();
    // 디버깅을 위한 로그 추가
    print('ResultPage - ProcessedImage: ${widget.processedImage?.path}');
    print('ResultPage - ProcessedImage exists: ${widget.processedImage?.existsSync()}');
    _saveToHistory();
  }

  Widget _buildMainImage() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: widget.processedImage != null
            ? Image.file(
          widget.processedImage!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('이미지 로드 에러: $error');
            print('스택 트레이스: $stackTrace');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 40),
                  SizedBox(height: 8),
                  Text('피팅된 이미지를 불러올 수 없습니다: $error'),
                ],
              ),
            );
          },
        )
            : widget.isOnepiece
            ? _buildImage(widget.topImage)
            : Column(
          children: [
            if (widget.topImage != null && widget.topImage != '')
              Expanded(child: _buildImage(widget.topImage)),
            if (widget.bottomImage != null && widget.bottomImage != '')
              Expanded(child: _buildImage(widget.bottomImage)),
          ],
        ),
      ),
    );
  }

  Future<File> _compressImage(File file) async {
    try {
      print('압축 시작: ${file.path}');

      final img = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 1024,
        minHeight: 1024,
        quality: 85,
      );

      if (img == null) {
        print('이미지 압축 실패');
        return file;
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${path.basename(file.path)}');
      await tempFile.writeAsBytes(img);

      print('압축 완료: ${tempFile.path}');
      return tempFile;
    } catch (e) {
      print('이미지 압축 오류: $e');
      return file;
    }
  }

  Widget _buildImage(dynamic image) {
    if (image is File) {
      return Image.file(
        image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('파일 이미지 로드 에러: $error');
          return Container(
            color: Colors.white,
          );
        },
      );
    } else if (image is String && image.isNotEmpty) {
      return Image.network(
        image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('네트워크 이미지 로드 에러: $error');
          return Container(
            color: Colors.white,
          );
        },
      );
    } else {
      return Container(
        color: Colors.white,
      );
    }
  }

  Future<void> _saveToHistory() async {
    try {
      final _userId = FirebaseAuth.instance.currentUser?.uid;
      if (_userId == null) return;

      String fileName = 'fitting_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final historyStorageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .child(widget.childInfo['childId'])
          .child('fittingHistory');

      Map<String, dynamic> fittingData = {
        'date': DateTime.now().toString(),
        'timestamp': ServerValue.timestamp,
        'savedAt': DateTime.now().toString(),
      };

      // 처리된 이미지가 있는 경우 우선적으로 저장
      if (widget.processedImage != null) {
        print('처리된 이미지 저장 시작');
        final newRef = historyStorageRef.child(fileName);
        await newRef.putFile(widget.processedImage!);
        final newUrl = await newRef.getDownloadURL();
        fittingData['processedImageUrl'] = newUrl;
        print('처리된 이미지 저장 완료: $newUrl');
      }
      if (widget.isOnepiece) {
        if (widget.isFromCloset) {
          final originalUrl = widget.topImage as String;
          final response = await http.get(Uri.parse(originalUrl));
          final imageData = response.bodyBytes;

          final newRef = historyStorageRef.child('original_$fileName');
          await newRef.putData(imageData);
          final newUrl = await newRef.getDownloadURL();
          fittingData['originalImageUrl'] = newUrl;
        } else {
          final newRef = historyStorageRef.child('original_$fileName');
          await newRef.putFile(widget.topImage as File);
          final newUrl = await newRef.getDownloadURL();
          fittingData['originalImageUrl'] = newUrl;
        }

        await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(_userId)
            .child('children')
            .child(widget.childInfo['childId'])
            .child('fittingHistory')
            .child('category')
            .child('set')
            .push()
            .set(fittingData);

      } else {
        if (widget.topImage != null && widget.topImage != '') {
          if (widget.isFromCloset) {
            final originalUrl = widget.topImage as String;
            final response = await http.get(Uri.parse(originalUrl));
            final imageData = response.bodyBytes;

            final newRef = historyStorageRef.child('top_$fileName');
            await newRef.putData(imageData);
            final newUrl = await newRef.getDownloadURL();
            fittingData['topImageUrl'] = newUrl;
          } else {
            final newRef = historyStorageRef.child('top_$fileName');
            await newRef.putFile(widget.topImage as File);
            final newUrl = await newRef.getDownloadURL();
            fittingData['topImageUrl'] = newUrl;
          }
        }

        if (widget.bottomImage != null && widget.bottomImage != '') {
          if (widget.isFromCloset) {
            final originalUrl = widget.bottomImage as String;
            final response = await http.get(Uri.parse(originalUrl));
            final imageData = response.bodyBytes;

            final newRef = historyStorageRef.child('bottom_$fileName');
            await newRef.putData(imageData);
            final newUrl = await newRef.getDownloadURL();
            fittingData['bottomImageUrl'] = newUrl;
          } else {
            final newRef = historyStorageRef.child('bottom_$fileName');
            await newRef.putFile(widget.bottomImage as File);
            final newUrl = await newRef.getDownloadURL();
            fittingData['bottomImageUrl'] = newUrl;
          }
        }

        await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(_userId)
            .child('children')
            .child(widget.childInfo['childId'])
            .child('fittingHistory')
            .child('category')
            .child('top_bottom')
            .push()
            .set(fittingData);
      }
    } catch (e) {
      print('History 저장 오류: $e');
    }
  }
  Future<void> _saveFittingResult(BuildContext context) async {
    try {
      final _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String fileName = 'fitting_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final resultStorageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .child(widget.childInfo['childId'])
          .child('fittingResults')
          .child('category');

      // 처리된 이미지가 있는 경우 우선 저장
      if (widget.processedImage != null) {
        print('처리된 이미지 저장 시작');
        final processedRef = resultStorageRef.child('processed').child(fileName);
        await processedRef.putFile(widget.processedImage!);
        print('처리된 이미지 저장 완료');
      }

      if (widget.isOnepiece) {
        if (widget.isFromCloset) {
          final originalUrl = widget.topImage as String;
          final response = await http.get(Uri.parse(originalUrl));
          final imageData = response.bodyBytes;

          final newRef = resultStorageRef.child('set').child(fileName);
          await newRef.putData(imageData);
        } else {
          final newRef = resultStorageRef.child('set').child(fileName);
          await newRef.putFile(widget.topImage as File);
        }
      } else {
        if (widget.topImage != null && widget.topImage != '') {
          if (widget.isFromCloset) {
            final originalUrl = widget.topImage as String;
            final response = await http.get(Uri.parse(originalUrl));
            final imageData = response.bodyBytes;

            await resultStorageRef
                .child('top_bottom')
                .child('top_$fileName')
                .putData(imageData);
          } else {
            await resultStorageRef
                .child('top_bottom')
                .child('top_$fileName')
                .putFile(widget.topImage as File);
          }
        }

        if (widget.bottomImage != null && widget.bottomImage != '') {
          if (widget.isFromCloset) {
            final originalUrl = widget.bottomImage as String;
            final response = await http.get(Uri.parse(originalUrl));
            final imageData = response.bodyBytes;

            await resultStorageRef
                .child('top_bottom')
                .child('bottom_$fileName')
                .putData(imageData);
          } else {
            await resultStorageRef
                .child('top_bottom')
                .child('bottom_$fileName')
                .putFile(widget.bottomImage as File);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피팅 결과가 저장되었습니다')),
      );

      if (widget.isFromCloset) {
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        Navigator.pop(context);
      }

    } catch (e) {
      print('저장 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMainImage(),  // 수정된 부분: 메인 이미지 표시

                  // 하단의 작은 이미지들 (원본 이미지들)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.topImage != null)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImage(widget.topImage),
                            ),
                          ),
                        if (!widget.isOnepiece && widget.bottomImage != null) ...[
                          SizedBox(width: 8),
                          Icon(Icons.add, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImage(widget.bottomImage),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 유사 스타일 추천 섹션
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '유사 스타일 추천',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        if (widget.recommendedItems.isNotEmpty)
                          ...List.generate((widget.recommendedItems.length / 3).ceil(), (index) {
                            int start = index * 3;
                            int end = (start + 3 <= widget.recommendedItems.length)
                                ? start + 3
                                : widget.recommendedItems.length;

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    for (int i = start; i < end; i++)
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.symmetric(horizontal: 6),
                                          height: 150,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              widget.recommendedItems[i],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(Icons.error_outline, color: Colors.grey),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    // 3개 미만일 경우 빈 공간을 채우기 위한 Expanded
                                    for (int i = 0; i < (3 - (end - start)); i++)
                                      Expanded(child: Container()),
                                  ],
                                ),
                                if (index < (widget.recommendedItems.length / 3).ceil() - 1)
                                  SizedBox(height: 12),  // 행 간격
                              ],
                            );
                          }),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // 하단 버튼
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FittingRoomPage(
                          childInfo: widget.childInfo,
                          fullBodyImageUrl: widget.childInfo['fullBodyImageUrl'],
                          clearPreviousImages: true,  // 추가
                        ),
                      ),
                    ),
                    child: Text('다시 피팅하기', style: TextStyle(color: Colors.grey[600])),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveFittingResult(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('저장하기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}