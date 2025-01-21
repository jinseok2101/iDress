import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: '일반 피팅'),
              Tab(text: '한벌옷 피팅'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HistoryListTab(
              childInfo: widget.childInfo,
              category: 'top_bottom',
            ),
            HistoryListTab(
              childInfo: widget.childInfo,
              category: 'set',
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryListTab extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final String category;

  const HistoryListTab({
    Key? key,
    required this.childInfo,
    required this.category,
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
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _ref = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('children')
        .child(widget.childInfo['childId'])
        .child('fittingHistory')
        .child('category')
        .child(widget.category);

    _stream = _ref.orderByChild('timestamp').onValue;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder(
      stream: _stream,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('오류가 발생했습니다'));
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(child: Text('피팅 기록이 없습니다'));
        }

        Map<dynamic, dynamic> histories =
        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        List<MapEntry<dynamic, dynamic>> historyList =
        histories.entries.toList();

        historyList.sort((a, b) =>
            (b.value['timestamp'] as int).compareTo(a.value['timestamp'] as int));

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: historyList.length,
          itemBuilder: (context, index) {
            final history = historyList[index].value;
            final DateTime date = DateTime.parse(history['date']);
            final String formattedDate =
            DateFormat('yyyy년 MM월 dd일 HH:mm').format(date);

            return GestureDetector( // Card를 GestureDetector로 감싸기
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FittingHistoryDetailPage(
                      historyData: history,
                      category: widget.category,
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
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (widget.category == 'set' && history['onepieceUrl'] != null)
                      Image.network(
                        history['onepieceUrl'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                      )
                    else if (widget.category == 'top_bottom')
                      Row(
                        children: [
                          if (history['topImageUrl'] != null)
                            Expanded(
                              child: Image.network(
                                history['topImageUrl'],
                                fit: BoxFit.cover,
                                height: 200,
                              ),
                            ),
                          if (history['bottomImageUrl'] != null)
                            Expanded(
                              child: Image.network(
                                history['bottomImageUrl'],
                                fit: BoxFit.cover,
                                height: 200,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}