import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'fitting_history_detail_page.dart';

class FittingHistoryPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;

  const FittingHistoryPage({
    Key? key,
    required this.childInfo,
  }) : super(key: key);

  @override
  State<FittingHistoryPage> createState() => _FittingHistoryPageState();
}

class _FittingHistoryPageState extends State<FittingHistoryPage> {
  String _selectedFilter = '전체';
  final List<String> _filterOptions = ['전체', '원피스', '상하의'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '피팅 기록',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list, color: Colors.black),
              onSelected: (String value) {
                setState(() {
                  _selectedFilter = value;
                });
              },
              itemBuilder: (BuildContext context) {
                return _filterOptions.map((String option) {
                  return PopupMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList();
              },
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: '모든 피팅 기록'),
              Tab(text: '저장한 피팅 기록'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HistoryListTab(
              childInfo: widget.childInfo,
              type: 'history',
              filter: _selectedFilter,
            ),
            HistoryListTab(
              childInfo: widget.childInfo,
              type: 'results',
              filter: _selectedFilter,
            ),
          ],
        ),
      ),
    );
  }
}
class HistoryListTab extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final String type;
  final String filter;

  const HistoryListTab({
    Key? key,
    required this.childInfo,
    required this.type,
    required this.filter,
  }) : super(key: key);

  @override
  State<HistoryListTab> createState() => _HistoryListTabState();
}

class _HistoryListTabState extends State<HistoryListTab>
    with AutomaticKeepAliveClientMixin {
  late final DatabaseReference _ref;
  late final Stream<DatabaseEvent> _stream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _ref = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('children')
        .child(widget.childInfo['childId'])
        .child(widget.type == 'history' ? 'fittingHistory' : 'fittingResults')
        .child('category');

    _stream = _ref.onValue;
  }

  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('이미지 삭제 오류: $e');
    }
  }

  Future<void> _deleteEntireHistory(Map<dynamic, dynamic> historyData, String historyKey) async {
    try {
      // 이미지 삭제
      if (historyData['processedImageUrl'] != null) {
        await _deleteImageFromStorage(historyData['processedImageUrl']);
      }
      if (historyData['originalImageUrl'] != null) {
        await _deleteImageFromStorage(historyData['originalImageUrl']);
      }
      if (historyData['topImageUrl'] != null) {
        await _deleteImageFromStorage(historyData['topImageUrl']);
      }
      if (historyData['bottomImageUrl'] != null) {
        await _deleteImageFromStorage(historyData['bottomImageUrl']);
      }

      // 데이터베이스 기록 삭제
      await _ref.child(historyData['category']).child(historyKey).remove();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피팅 기록이 완전히 삭제되었습니다')),
      );
    } catch (e) {
      print('전체 삭제 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, String historyKey, Map<dynamic, dynamic> historyData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('피팅 기록 삭제'),
          content: Text('이 피팅 기록을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEntireHistory(historyData, historyKey);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveToResults(Map<dynamic, dynamic> historyData) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // 현재 시간으로 데이터 업데이트
      final updatedData = {
        ...Map<String, dynamic>.from(historyData),
        'savedAt': DateTime.now().toString(),
        'timestamp': ServerValue.timestamp,
      };

      // fittingResults에 저장
      final resultsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('children')
          .child(widget.childInfo['childId'])
          .child('fittingResults')
          .child('category')
          .child(historyData['category'])
          .push();

      await resultsRef.set(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장된 피팅 기록에 추가되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('저장 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<MapEntry<dynamic, dynamic>> _filterAndGroupHistories(List<MapEntry<dynamic, dynamic>> histories) {
    // 필터링
    var filteredHistories = histories.where((entry) {
      if (widget.filter == '전체') return true;
      if (widget.filter == '원피스') return entry.value['category'] == 'set';
      if (widget.filter == '상하의') return entry.value['category'] == 'top_bottom';
      return true;
    }).toList();

    // 날짜순 정렬
    filteredHistories.sort((a, b) {
      int timestampA = (a.value['timestamp'] ?? 0) as int;
      int timestampB = (b.value['timestamp'] ?? 0) as int;
      return timestampB.compareTo(timestampA);
    });

    return filteredHistories;
  }

  Widget _buildGroupedListView(List<MapEntry<dynamic, dynamic>> histories) {
    // 날짜별로 그룹화
    Map<String, List<MapEntry<dynamic, dynamic>>> groupedHistories = {};

    for (var history in histories) {
      final DateTime date = DateTime.parse(history.value['date'] as String);
      final String dateKey = DateFormat('yyyy년 MM월 dd일').format(date);

      if (!groupedHistories.containsKey(dateKey)) {
        groupedHistories[dateKey] = [];
      }
      groupedHistories[dateKey]!.add(history);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: groupedHistories.length,
      itemBuilder: (context, index) {
        String dateKey = groupedHistories.keys.elementAt(index);
        List<MapEntry<dynamic, dynamic>> dayHistories = groupedHistories[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            ...dayHistories.map((history) {
              final DateTime time = DateTime.parse(history.value['date'] as String);
              final String formattedTime = DateFormat('HH:mm').format(time);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FittingHistoryDetailPage(
                        historyData: history.value,
                        category: history.value['category'],
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                if (widget.type == 'history')
                                  IconButton(
                                    icon: Icon(Icons.save_alt, size: 20),
                                    onPressed: () => _saveToResults(history.value),
                                    tooltip: '저장하기',
                                  ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _showDeleteConfirmation(
                                      context,
                                      history.key,
                                      history.value
                                  ),
                                  tooltip: '삭제하기',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (history.value['category'] == 'set' &&
                          history.value['processedImageUrl'] != null)
                        Image.network(
                          history.value['processedImageUrl'] as String,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Icon(Icons.error_outline, color: Colors.grey),
                            );
                          },
                        )
                      else if (history.value['category'] == 'top_bottom')
                        Row(
                          children: [
                            if (history.value['topImageUrl'] != null)
                              Expanded(
                                child: Image.network(
                                  history.value['topImageUrl'] as String,
                                  fit: BoxFit.cover,
                                  height: 200,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: Icon(Icons.error_outline,
                                          color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                            if (history.value['bottomImageUrl'] != null)
                              Expanded(
                                child: Image.network(
                                  history.value['bottomImageUrl'] as String,
                                  fit: BoxFit.cover,
                                  height: 200,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: Icon(Icons.error_outline,
                                          color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder(
        stream: _stream,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text('데이터를 불러오는 중 오류가 발생했습니다\n${snapshot.error}'),
        );
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '피팅 기록이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      try {
        final data = snapshot.data!.snapshot.value;
        if (data == null) {
          return Center(child: Text('피팅 기록이 없습니다'));
        }

        Map<dynamic, dynamic> categoriesMap = data as Map<dynamic, dynamic>;
        List<MapEntry<dynamic, dynamic>> allHistories = [];

        categoriesMap.forEach((category, histories) {
          if (histories is Map) {
            histories.forEach((key, value) {
              if (value is Map) {
                allHistories.add(MapEntry(key, {
                  ...Map<String, dynamic>.from(value),
                  'category': category,
                }));
              }
            });
          }
        });

        // 필터링 및 그룹화 적용
        var filteredHistories = _filterAndGroupHistories(allHistories);

        if (filteredHistories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '해당하는 피팅 기록이 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return _buildGroupedListView(filteredHistories);

      } catch (e) {
        print('데이터 파싱 에러: $e');
        return Center(child: Text('데이터 처리 중 오류가 발생했습니다'));
      }
        },
    );
  }
}
