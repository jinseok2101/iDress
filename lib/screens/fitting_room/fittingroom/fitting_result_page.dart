import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class FittingResultPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final dynamic topImage;  // File 또는 String을 받을 수 있도록
  final dynamic bottomImage;  // File 또는 String을 받을 수 있도록
  final bool isOnepiece;
  final bool isFromCloset;  // 옷장에서 왔는지 여부

  const FittingResultPage({
    Key? key,
    required this.childInfo,
    required this.topImage,
    required this.bottomImage,
    this.isOnepiece = false,
    this.isFromCloset = false,  // 기본값 false
  }) : super(key: key);

  @override
  State<FittingResultPage> createState() => _FittingResultPageState();
}

class _FittingResultPageState extends State<FittingResultPage> {
  @override
  void initState() {
    super.initState();
    _saveToHistory();
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
        return file;  // 압축 실패시 원본 반환
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${path.basename(file.path)}');
      await tempFile.writeAsBytes(img);

      print('압축 완료: ${tempFile.path}');
      return tempFile;
    } catch (e) {
      print('이미지 압축 오류: $e');
      return file;  // 오류 발생시 원본 반환
    }
  }

  Widget _buildImage(dynamic image) {
    if (image is File) {
      return Image.file(
        image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // 이미지 로드 실패시 빈 컨테이너 반환
          return Container(
            color: Colors.white,  // 또는 원하는 배경색
          );
        },
      );
    } else if (image is String && image.isNotEmpty) {
      return Image.network(
        image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // 이미지 로드 실패시 빈 컨테이너 반환
          return Container(
            color: Colors.white,  // 또는 원하는 배경색
          );
        },
      );
    } else {
      // 이미지가 없는 경우 빈 컨테이너 반환
      return Container(
        color: Colors.white,  // 또는 원하는 배경색
      );
    }
  }

  Future<void> _saveToHistory() async {
    try {
      final _userId = FirebaseAuth.instance.currentUser?.uid;
      if (_userId == null) return;

      String fileName = 'fitting_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // fittingHistory Storage 참조
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

      if (widget.isOnepiece) {
        if (widget.isFromCloset) {
          // 옷장에서 온 경우: Storage에 복사
          final originalUrl = widget.topImage as String;
          final response = await http.get(Uri.parse(originalUrl));
          final imageData = response.bodyBytes;

          final newRef = historyStorageRef.child(fileName);
          await newRef.putData(imageData);
          final newUrl = await newRef.getDownloadURL();
          fittingData['onepieceUrl'] = newUrl;
        } else {
          // 피팅룸에서 온 경우
          final newRef = historyStorageRef.child(fileName);
          await newRef.putFile(widget.topImage as File);
          final newUrl = await newRef.getDownloadURL();
          fittingData['onepieceUrl'] = newUrl;
        }

        // Database에 저장
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
            // 상의 - 옷장에서 온 경우
            final originalUrl = widget.topImage as String;
            final response = await http.get(Uri.parse(originalUrl));
            final imageData = response.bodyBytes;

            final newRef = historyStorageRef.child('top_$fileName');
            await newRef.putData(imageData);
            final newUrl = await newRef.getDownloadURL();
            fittingData['topImageUrl'] = newUrl;
          } else {
            // 상의 - 피팅룸에서 온 경우
            final newRef = historyStorageRef.child('top_$fileName');
            await newRef.putFile(widget.topImage as File);
            final newUrl = await newRef.getDownloadURL();
            fittingData['topImageUrl'] = newUrl;
          }
        }

        if (widget.bottomImage != null && widget.bottomImage != '') {
          if (widget.isFromCloset) {
            // 하의 - 옷장에서 온 경우
            final originalUrl = widget.bottomImage as String;
            final response = await http.get(Uri.parse(originalUrl));
            final imageData = response.bodyBytes;

            final newRef = historyStorageRef.child('bottom_$fileName');
            await newRef.putData(imageData);
            final newUrl = await newRef.getDownloadURL();
            fittingData['bottomImageUrl'] = newUrl;
          } else {
            // 하의 - 피팅룸에서 온 경우
            final newRef = historyStorageRef.child('bottom_$fileName');
            await newRef.putFile(widget.bottomImage as File);
            final newUrl = await newRef.getDownloadURL();
            fittingData['bottomImageUrl'] = newUrl;
          }
        }

        // Database에 저장
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

      // fittingResults Storage 참조
      final resultStorageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .child(widget.childInfo['childId'])
          .child('fittingResults')
          .child('category');

      if (widget.isOnepiece) {
        if (widget.isFromCloset) {
          // 옷장에서 온 경우: Storage에 복사
          final originalUrl = widget.topImage as String;
          final response = await http.get(Uri.parse(originalUrl));
          final imageData = response.bodyBytes;

          final newRef = resultStorageRef.child('set').child(fileName);
          await newRef.putData(imageData);
        } else {
          // 피팅룸에서 온 경우
          final newRef = resultStorageRef.child('set').child(fileName);
          await newRef.putFile(widget.topImage as File);
        }
      } else {
        if (widget.topImage != null && widget.topImage != '') {
          if (widget.isFromCloset) {
            // 상의 - 옷장에서 온 경우
            final originalUrl = widget.topImage as String;
            final response = await http.get(Uri.parse(originalUrl));
            final imageData = response.bodyBytes;

            await resultStorageRef
                .child('top_bottom')
                .child('top_$fileName')
                .putData(imageData);
          } else {
            // 상의 - 피팅룸에서 온 경우
            await resultStorageRef
                .child('top_bottom')
                .child('top_$fileName')
                .putFile(widget.topImage as File);
          }
        }

        if (widget.bottomImage != null && widget.bottomImage != '') {
          if (widget.isFromCloset) {
            // 하의 - 옷장에서 온 경우
            final originalUrl = widget.bottomImage as String;
            final response = await http.get(Uri.parse(originalUrl));
            final imageData = response.bodyBytes;

            await resultStorageRef
                .child('top_bottom')
                .child('bottom_$fileName')
                .putData(imageData);
          } else {
            // 하의 - 피팅룸에서 온 경우
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

      // 네비게이션 로직 수정
      if (widget.isFromCloset) {
        // 옷장에서 왔을 경우: 모든 스택을 지우고 ClosetPage로 이동
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        // 피팅룸에서 왔을 경우: 이전 페이지로 이동
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
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: widget.isOnepiece
                        ? _buildImage(widget.topImage)  // 원피스인 경우
                        : Column(
                      children: [
                        // 상의 이미지가 있을 때만 표시
                        if (widget.topImage != null && widget.topImage != '')
                          Expanded(
                            child: _buildImage(widget.topImage),
                          ),
                        // 하의 이미지가 있을 때만 표시
                        if (widget.bottomImage != null && widget.bottomImage != '')
                          Expanded(
                            child: _buildImage(widget.bottomImage),
                          ),
                      ],
                    ),
                  ),

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
                        if (!widget.isOnepiece) ...[
                          SizedBox(width: 8),
                          Icon(Icons.add, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          if (widget.bottomImage != null)
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
                        SizedBox(
                          height: 200,
                          child: StreamBuilder(
                            stream: FirebaseDatabase.instance
                                .ref()
                                .child('users')
                                .child(FirebaseAuth.instance.currentUser?.uid ?? '')
                                .child('children')
                                .child(widget.childInfo['childId'])
                                .child('clothing')
                                .child(widget.isOnepiece ? '한벌옷' : '상의')
                                .onValue,
                            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                                return Center(child: Text('추천 항목이 없습니다'));
                              }

                              Map<dynamic, dynamic> clothes =
                              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                              List<MapEntry<dynamic, dynamic>> clothesList =
                              clothes.entries.toList();

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: clothesList.length,
                                itemBuilder: (context, index) {
                                  final clothing = clothesList[index].value;
                                  return Container(
                                    width: 120,
                                    margin: EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(8),
                                            ),
                                            child: Image.network(
                                              clothing['imageUrl'],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                clothing['name'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Size: ${clothing['size'] ?? ''}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '다시 피팅하기',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
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