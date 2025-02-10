
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SchoolScheduleWidget extends StatelessWidget {
  const SchoolScheduleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SchoolSchedulePage()),
          );
        },
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '학사일정',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '터치하여 일정 확인하기',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class SchoolSchedulePage extends StatefulWidget {
  const SchoolSchedulePage({super.key});

  @override
  SchoolSchedulePageState createState() => SchoolSchedulePageState();
}

class SchoolSchedulePageState extends State<SchoolSchedulePage> {
  String? _savedSchoolCode;
  String? _schoolName;
  Map<DateTime, List<String>> _events = {};
  bool _isLoading = false;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final String _apiKey = '25abc80106ee41aaa062fe35775d7674';
  List<String> selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _loadSavedSchoolInfo();
  }

  Future<void> _loadSavedSchoolInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schoolCode = prefs.getString('school_code');
      final regionCode = prefs.getString('region_code');
      final schoolName = prefs.getString('school_name');

      if (schoolCode != null && regionCode != null) {
        setState(() {
          _savedSchoolCode = schoolCode;
          _schoolName = schoolName;
        });
        await _fetchSchedule(regionCode, schoolCode);
      }
    } catch (e) {
      _showErrorSnackBar('학교 정보를 불러오는데 실패했습니다');
    }
  }

  Future<void> _fetchSchedule(String regionCode, String schoolCode) async {
    setState(() {
      _isLoading = true;
      _events.clear();
    });

    try {
      // 현재 년월 계산
      final now = DateTime.now();
      final year = now.year;
      final month = now.month.toString().padLeft(2, '0');

      // API URL 구성
      final String url =
          'https://open.neis.go.kr/hub/SchoolSchedule'
          '?KEY=$_apiKey'
          '&Type=json'
          '&pIndex=1'
          '&pSize=100'
          '&ATPT_OFCDC_SC_CODE=$regionCode'
          '&SD_SCHUL_CODE=$schoolCode'
          '&AA_YMD=${year}${month}';

      print('학사일정 API 요청: $url');
      final response = await http.get(Uri.parse(url));
      print('학사일정 응답 코드: ${response.statusCode}');
      print('학사일정 응답 데이터: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('SchoolSchedule')) {
          final List<dynamic> schedules = data['SchoolSchedule'][1]['row'];
          Map<DateTime, List<String>> eventMap = {};

          for (var schedule in schedules) {
            final String dateStr = schedule['AA_YMD'];
            final String eventName = schedule['EVENT_NM'];

            try {
              final year = int.parse(dateStr.substring(0, 4));
              final month = int.parse(dateStr.substring(4, 6));
              final day = int.parse(dateStr.substring(6, 8));
              final eventDate = DateTime.utc(year, month, day);

              print('일정 파싱: $dateStr - $eventName');

              if (!eventMap.containsKey(eventDate)) {
                eventMap[eventDate] = [];
              }
              eventMap[eventDate]!.add(eventName);
            } catch (e) {
              print('날짜 파싱 오류: $e');
            }
          }

          setState(() {
            _events = eventMap;
            print('저장된 일정: $_events');
          });
        } else if (data.containsKey('RESULT')) {
          final errorMessage = data['RESULT']['MESSAGE'];
          print('API 오류 메시지: $errorMessage');
          _showErrorSnackBar('일정 조회 실패: $errorMessage');
        } else {
          print('일정 데이터 없음');
          _showErrorSnackBar('해당 월에 등록된 일정이 없습니다.');
        }
      } else {
        throw Exception('서버 응답 오류 (${response.statusCode})');
      }
    } catch (e) {
      print('일정 조회 오류: $e');
      _showErrorSnackBar('일정을 불러오는 중 오류가 발생했습니다');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  List<String> _getEventsForDay(DateTime day) {
    final dateKey = DateTime.utc(day.year, day.month, day.day);  // ✅ UTC 변환
    return _events[dateKey] ?? [];
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showSchoolSearchDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => SchoolCodeSearchDialog(),
    );

    if (result != null && result is Map<String, String>) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('school_code', result['schoolCode']!);
      await prefs.setString('region_code', result['regionCode']!);
      await prefs.setString('school_name', result['schoolName']!);

      setState(() {
        _savedSchoolCode = result['schoolCode'];
        _schoolName = result['schoolName'];
      });

      await _fetchSchedule(result['regionCode']!, result['schoolCode']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_schoolName ?? '학사 일정'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.school),
            onPressed: _showSchoolSearchDialog,
            tooltip: '학교 검색',
          ),
        ],
      ),
      body: _savedSchoolCode == null
          ? _buildNoSchoolView()
          : Column(
        children: [
          _buildCalendar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSchoolView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '등록된 학교가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showSchoolSearchDialog,
            child: Text('학교 검색하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        // UTC로 변환하여 비교
        final utcDay = DateTime.utc(day.year, day.month, day.day);
        return _events[utcDay] ?? [];
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          // UTC로 변환하여 이벤트 가져오기
          final utcDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
          selectedEvents = _events[utcDay] ?? [];
        });
      },
      onPageChanged: (focusedDay) async {
        // 월이 변경될 때 해당 월의 일정 가져오기
        _focusedDay = focusedDay;
        if (_savedSchoolCode != null) {
          final prefs = await SharedPreferences.getInstance();
          final regionCode = prefs.getString('region_code');
          if (regionCode != null) {
            await _fetchSchedule(regionCode, _savedSchoolCode!);
          }
        }
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 1,
        markerDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  Widget _buildEventList() {
    if (selectedEvents.isEmpty) {
      return Center(
        child: Text(
          '해당 날짜에 일정이 없습니다',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.event),
            title: Text(selectedEvents[index]),
          ),
        );
      },
    );
  }
}
class SchoolCodeSearchDialog extends StatefulWidget {
  @override
  _SchoolCodeSearchDialogState createState() => _SchoolCodeSearchDialogState();
}

class _SchoolCodeSearchDialogState extends State<SchoolCodeSearchDialog> {
  final TextEditingController _schoolNameController = TextEditingController();
  String? _selectedRegionCode;
  List<Map<String, String>> _searchResults = [];
  bool _isLoading = false;

  final Map<String, String> regionCodes = {
    '서울': 'B10',
    '부산': 'C10',
    '대구': 'D10',
    '인천': 'E10',
    '광주': 'F10',
    '대전': 'G10',
    '울산': 'H10',
    '세종': 'I10',
    '경기': 'J10',
    '강원': 'K10',
    '충북': 'M10',
    '충남': 'N10',
    '전북': 'P10',
    '전남': 'Q10',
    '경북': 'R10',
    '경남': 'S10',
    '제주': 'T10',
  };

  void _showErrorSnackBar(String message) {  // ✅ 여기로 이동!
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    super.dispose();
  }

  Future<void> _searchSchool() async {
    // 입력 값 검증
    if (_selectedRegionCode == null || _schoolNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('교육청과 학교명을 모두 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    try {
      // URL 인코딩 추가
      final schoolName = Uri.encodeComponent(_schoolNameController.text);

      // API URL 구성
      final String url =
          'https://open.neis.go.kr/hub/schoolInfo'
          '?KEY=b07059949b5b443eb285752559382a3d'
          '&Type=json'
          '&pIndex=1'
          '&pSize=100'
          '&ATPT_OFCDC_SC_CODE=$_selectedRegionCode'
          '&SCHUL_NM=$schoolName';

      print('요청 URL: $url'); // 디버깅용 로그

      final response = await http.get(Uri.parse(url));

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 데이터: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 검색 결과가 있는 경우
        if (data.containsKey('schoolInfo')) {
          final List<dynamic> schools = data['schoolInfo'][1]['row'];
          setState(() {
            _searchResults = schools.map<Map<String, String>>((school) => {
              'name': school['SCHUL_NM'] as String,
              'code': school['SD_SCHUL_CODE'] as String,
              'address': school['ORG_RDNMA'] as String, // 학교 주소 추가
            }).toList();
          });

          if (_searchResults.isEmpty) {
            _showErrorSnackBar('검색 결과가 없습니다.');
          }
        } else if (data.containsKey('RESULT')) {
          // API 에러 메시지 확인
          final errorMessage = data['RESULT']['MESSAGE'] as String;
          _showErrorSnackBar('검색 실패: $errorMessage');
        } else {
          _showErrorSnackBar('검색된 학교가 없습니다.');
        }
      } else {
        _showErrorSnackBar('서버 응답 오류 (${response.statusCode})');
      }
    } catch (e) {
      print('검색 오류: $e'); // 디버깅용 로그
      _showErrorSnackBar('검색 중 오류가 발생했습니다');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('학교 검색'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedRegionCode,
              hint: Text('시·도 교육청 선택'),
              onChanged: (value) {
                setState(() {
                  _selectedRegionCode = value;
                });
              },
              items: regionCodes.entries
                  .map((entry) => DropdownMenuItem(
                value: entry.value,
                child: Text(entry.key),
              ))
                  .toList(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _schoolNameController,
              decoration: InputDecoration(
                labelText: '학교명',
                suffix: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchSchool,
                ),
              ),
              onSubmitted: (_) => _searchSchool(),
            ),
            SizedBox(height: 16),



            if (_isLoading)
              CircularProgressIndicator()
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final school = _searchResults[index];
                    return ListTile(
                      title: Text(school['name']!),
                      onTap: () {
                        Navigator.of(context).pop({
                          'schoolCode': school['code'],
                          'schoolName': school['name'],
                          'regionCode': _selectedRegionCode,
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소'),
        ),
      ],
    );
  }
}
