import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FittingResultPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final File topImageFile;
  final File bottomImageFile;
  final bool isOnepiece;

  const FittingResultPage({
    Key? key,
    required this.childInfo,
    required this.topImageFile,
    required this.bottomImageFile,
    this.isOnepiece = false,
  }) : super(key: key);

  @override
  State<FittingResultPage> createState() => _FittingResultPageState();
}

class _FittingResultPageState extends State<FittingResultPage> {
  @override
  void initState() {
    super.initState();
    // 피팅 결과 생성 즉시 fittingHistory에 자동 저장
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

  Future<void> _saveToHistory() async {
    try {
      final _userId = FirebaseAuth.instance.currentUser?.uid;
      if (_userId == null) return;

      String fileName = 'fitting_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // fittingHistory 저장 로직
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
        final historyRef = historyStorageRef.child(fileName);
        await historyRef.putFile(widget.topImageFile);
        final historyUrl = await historyRef.getDownloadURL();
        fittingData['onepieceUrl'] = historyUrl;

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
        if (widget.topImageFile.path.isNotEmpty) {
          final topFileName = 'top_$fileName';
          final topHistoryRef = historyStorageRef.child(topFileName);
          await topHistoryRef.putFile(widget.topImageFile);
          final topUrl = await topHistoryRef.getDownloadURL();
          fittingData['topImageUrl'] = topUrl;
        }

        if (widget.bottomImageFile.path.isNotEmpty) {
          final bottomFileName = 'bottom_$fileName';
          final bottomHistoryRef = historyStorageRef.child(bottomFileName);
          await bottomHistoryRef.putFile(widget.bottomImageFile);
          final bottomUrl = await bottomHistoryRef.getDownloadURL();
          fittingData['bottomImageUrl'] = bottomUrl;
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

      // fittingResults에만 저장
      final resultStorageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(_userId)
          .child('children')
          .child(widget.childInfo['childId'])
          .child('fittingResults')
          .child('category');

      if (widget.isOnepiece) {
        final setRef = resultStorageRef.child('set').child(fileName);
        await setRef.putFile(widget.topImageFile);
      } else {
        if (widget.topImageFile.path.isNotEmpty) {
          await resultStorageRef
              .child('top_bottom')
              .child('top_$fileName')
              .putFile(widget.topImageFile);
        }
        if (widget.bottomImageFile.path.isNotEmpty) {
          await resultStorageRef
              .child('top_bottom')
              .child('bottom_$fileName')
              .putFile(widget.bottomImageFile);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피팅 결과가 저장되었습니다')),
      );
      Navigator.pop(context);
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
                        ? Image.file(
                      widget.topImageFile,
                      fit: BoxFit.contain,
                    )
                        : Column(
                      children: [
                        if (widget.topImageFile.path.isNotEmpty)
                          Expanded(
                            child: Image.file(
                              widget.topImageFile,
                              fit: BoxFit.contain,
                            ),
                          ),
                        if (widget.bottomImageFile.path.isNotEmpty)
                          Expanded(
                            child: Image.file(
                              widget.bottomImageFile,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.topImageFile.path.isNotEmpty)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                widget.topImageFile,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (!widget.isOnepiece) ...[
                          SizedBox(width: 8),
                          Icon(Icons.add, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          if (widget.bottomImageFile.path.isNotEmpty)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  widget.bottomImageFile,
                                  fit: BoxFit.cover,
                                ),
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