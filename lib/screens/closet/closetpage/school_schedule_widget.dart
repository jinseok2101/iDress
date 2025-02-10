// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class SchoolScheduleWidget extends StatelessWidget {
//   const SchoolScheduleWidget({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => SchoolSchedulePage()),
//           );
//         },
//         child: Row(
//           children: [
//             Icon(Icons.calendar_today, size: 20),
//             SizedBox(width: 8),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '학사일정',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   Text(
//                     '터치하여 일정 확인하기',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class SchoolSchedulePage extends StatefulWidget {
//   const SchoolSchedulePage({super.key});
//
//   @override
//   SchoolSchedulePageState createState() => SchoolSchedulePageState();
// }
//
// class SchoolSchedulePageState extends State<SchoolSchedulePage> {
//   String? _savedSchoolCode;
//   String? _schoolName;
//   Map<DateTime, List<String>> _events = {};
//   bool _isLoading = false;
//   DateTime _selectedDay = DateTime.now();
//   DateTime _focusedDay = DateTime.now();
//   final String _apiKey = '25abc80106ee41aaa062fe35775d7674';
//   List<String> selectedEvents = [];
//
//   @override
//   void initState() {
//     super.initState();
//     print('SchoolSchedulePage initState 호출');
//     _loadSavedSchoolInfo();
//   }
//
//   Future<void> _loadSavedSchoolInfo() async {
//     print('_loadSavedSchoolInfo 호출');
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final schoolCode = prefs.getString('school_code');
//       final regionCode = prefs.getString('region_code');
//       final schoolName = prefs.getString('school_name');
//
//       print('저장된 학교 정보: code=$schoolCode, region=$regionCode, name=$schoolName');
//
//       if (schoolCode != null && regionCode != null) {
//         setState(() {
//           _savedSchoolCode = schoolCode;
//           _schoolName = schoolName;
//         });
//         await _fetchSchedule(regionCode, schoolCode);
//       }
//     } catch (e) {
//       print('학교 정보 로드 오류: $e');
//       _showErrorSnackBar('학교 정보를 불러오는데 실패했습니다');
//     }
//   }
//
//   Future<void> _fetchSchedule(String regionCode, String schoolCode) async {
//     print('_fetchSchedule 호출됨: region=$regionCode, school=$schoolCode');
//
//     setState(() {
//       _isLoading = true;
//       _events.clear();
//     });
//
//     try {
//       // 현재 달의 년월 가져오기
//       final now = _focusedDay;
//       final year = now.year;
//       final month = now.month.toString().padLeft(2, '0');
//       final yearMonth = '$year${month}'; // YYYYMM 형식
//
//       final String url =
//           'https://open.neis.go.kr/hub/SchoolSchedule'
//           '?KEY=$_apiKey'
//           '&Type=json'
//           '&pIndex=1'
//           '&pSize=100'
//           '&ATPT_OFCDC_SC_CODE=$regionCode'
//           '&SD_SCHUL_CODE=$schoolCode'
//           '&AA_YMD=$yearMonth';
//
//       print('학사일정 API 요청 URL: $url');
//
//       final response = await http.get(Uri.parse(url));
//       print('학사일정 API 응답 코드: ${response.statusCode}');
//       print('학사일정 API 응답 데이터: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data.containsKey('SchoolSchedule')) {
//           final List<dynamic> schedules = data['SchoolSchedule'][1]['row'];
//           Map<DateTime, List<String>> eventMap = {};
//
//           for (var schedule in schedules) {
//             final String dateStr = schedule['AA_YMD'];
//             final String eventName = schedule['EVENT_NM'];
//             final String? eventContent = schedule['EVENT_CNTNT']; // 일정 상세 내용 (있는 경우)
//
//             print('일정 파싱: $dateStr - $eventName');
//
//             try {
//               final year = int.parse(dateStr.substring(0, 4));
//               final month = int.parse(dateStr.substring(4, 6));
//               final day = int.parse(dateStr.substring(6, 8));
//               final eventDate = DateTime.utc(year, month, day);
//
//               if (!eventMap.containsKey(eventDate)) {
//                 eventMap[eventDate] = [];
//               }
//
//               // 상세 내용이 있는 경우 함께 표시
//               final displayText = eventContent != null && eventContent.isNotEmpty
//                   ? '$eventName\n($eventContent)'
//                   : eventName;
//
//               eventMap[eventDate]!.add(displayText);
//             } catch (e) {
//               print('날짜 파싱 오류: $e');
//             }
//           }
//
//           setState(() {
//             _events = eventMap;
//             // 현재 선택된 날짜의 이벤트도 업데이트
//             final selectedDayUtc = DateTime.utc(
//               _selectedDay.year,
//               _selectedDay.month,
//               _selectedDay.day,
//             );
//             selectedEvents = _events[selectedDayUtc] ?? [];
//             print('저장된 일정 수: ${_events.length}');
//           });
//         } else if (data.containsKey('RESULT')) {
//           final errorMessage = data['RESULT']['MESSAGE'];
//           print('API 응답 메시지: $errorMessage');
//           if (errorMessage.contains('해당하는 데이터가 없습니다')) {
//             _showErrorSnackBar('이번 달에 등록된 학사일정이 없습니다');
//           } else {
//             _showErrorSnackBar(errorMessage);
//           }
//         } else {
//           print('SchoolSchedule 데이터 없음');
//           _showErrorSnackBar('해당 월에 등록된 일정이 없습니다.');
//         }
//       } else {
//         throw Exception('서버 응답 오류 (${response.statusCode})');
//       }
//     } catch (e) {
//       print('학사일정 조회 오류: $e');
//       _showErrorSnackBar('일정을 불러오는 중 오류가 발생했습니다');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   List<String> _getEventsForDay(DateTime day) {
//     final dateKey = DateTime.utc(day.year, day.month, day.day);
//     return _events[dateKey] ?? [];
//   }
//
//   void _showErrorSnackBar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)),
//       );
//     }
//   }
//
//   Future<void> _showSchoolSearchDialog() async {
//     print('학교 검색 다이얼로그 열기');
//     final result = await showDialog(
//       context: context,
//       builder: (context) => SchoolCodeSearchDialog(),
//     );
//
//     if (result != null && result is Map<String, String>) {
//       print('학교 검색 결과: $result');
//
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('school_code', result['schoolCode']!);
//       await prefs.setString('region_code', result['regionCode']!);
//       await prefs.setString('school_name', result['schoolName']!);
//
//       setState(() {
//         _savedSchoolCode = result['schoolCode'];
//         _schoolName = result['schoolName'];
//       });
//
//       // 학사일정 즉시 조회 전에 로그 추가
//       print('학사일정 조회 시작: ${result['regionCode']}, ${result['schoolCode']}');
//       await _fetchSchedule(result['regionCode']!, result['schoolCode']!);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_schoolName ?? '학사 일정'),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.school),
//             onPressed: _showSchoolSearchDialog,
//             tooltip: '학교 검색',
//           ),
//         ],
//       ),
//       body: _savedSchoolCode == null
//           ? _buildNoSchoolView()
//           : Column(
//         children: [
//           _buildCalendar(),
//           Expanded(
//             child: _isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : _buildEventList(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNoSchoolView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.school_outlined,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           SizedBox(height: 16),
//           Text(
//             '등록된 학교가 없습니다',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//           SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: _showSchoolSearchDialog,
//             child: Text('학교 검색하기'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCalendar() {
//     return TableCalendar(
//       firstDay: DateTime.utc(2020, 1, 1),
//       lastDay: DateTime.utc(2030, 12, 31),
//       focusedDay: _focusedDay,
//       selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//       eventLoader: (day) {
//         final utcDay = DateTime.utc(day.year, day.month, day.day);
//         return _events[utcDay] ?? [];
//       },
//       onDaySelected: (selectedDay, focusedDay) {
//         setState(() {
//           _selectedDay = selectedDay;
//           _focusedDay = focusedDay;
//           final utcDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
//           selectedEvents = _events[utcDay] ?? [];
//         });
//       },
//       onPageChanged: (focusedDay) async {
//         setState(() {
//           _focusedDay = focusedDay;
//         });
//         if (_savedSchoolCode != null) {
//           final prefs = await SharedPreferences.getInstance();
//           final regionCode = prefs.getString('region_code');
//           if (regionCode != null) {
//             // 월이 변경될 때 해당 월의 일정 가져오기
//             final year = focusedDay.year;
//             final month = focusedDay.month.toString().padLeft(2, '0');
//             await _fetchSchedule(regionCode, _savedSchoolCode!);
//           }
//         }
//       },
//       calendarStyle: CalendarStyle(
//         markersMaxCount: 1,
//         markerDecoration: BoxDecoration(
//           color: Colors.blue,
//           shape: BoxShape.circle,
//         ),
//       ),
//       headerStyle: HeaderStyle(
//         formatButtonVisible: false,
//         titleCentered: true,
//       ),
//     );
//   }
//
//   Widget _buildEventList() {
//     if (selectedEvents.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
//             SizedBox(height: 16),
//             Text(
//               '해당 날짜에 일정이 없습니다',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: selectedEvents.length,
//       itemBuilder: (context, index) {
//         final event = selectedEvents[index];
//         return Card(
//           elevation: 2,
//           margin: EdgeInsets.only(bottom: 8),
//           child: ListTile(
//             leading: Icon(Icons.event, color: Colors.blue),
//             title: Text(
//               event.split('\n')[0], // 일정 이름
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             subtitle: event.contains('\n')
//                 ? Text(
//               event.split('\n')[1].replaceAll(RegExp(r'[\(\)]'), ''),
//               style: TextStyle(
//                 color: Colors.grey[600],
//               ),
//             )
//                 : null,
//           ),
//         );
//       },
//     );
//   }
// }
//
//
// class SchoolCodeSearchDialog extends StatefulWidget {
//   @override
//   _SchoolCodeSearchDialogState createState() => _SchoolCodeSearchDialogState();
// }
//
// class _SchoolCodeSearchDialogState extends State<SchoolCodeSearchDialog> {
//   final TextEditingController _schoolNameController = TextEditingController();
//   String? _selectedRegionCode;
//   List<Map<String, String>> _searchResults = [];
//   bool _isLoading = false;
//
//   final Map<String, String> regionCodes = {
//     '서울': 'B10',
//     '부산': 'C10',
//     '대구': 'D10',
//     '인천': 'E10',
//     '광주': 'F10',
//     '대전': 'G10',
//     '울산': 'H10',
//     '세종': 'I10',
//     '경기': 'J10',
//     '강원': 'K10',
//     '충북': 'M10',
//     '충남': 'N10',
//     '전북': 'P10',
//     '전남': 'Q10',
//     '경북': 'R10',
//     '경남': 'S10',
//     '제주': 'T10',
//   };
//
//   @override
//   void dispose() {
//     _schoolNameController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _searchSchool() async {
//     if (_selectedRegionCode == null || _schoolNameController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('교육청과 학교명을 모두 입력해주세요')),
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _searchResults.clear();
//     });
//
//     try {
//       final schoolName = Uri.encodeComponent(_schoolNameController.text);
//       final String url =
//           'https://open.neis.go.kr/hub/schoolInfo'
//           '?KEY=b07059949b5b443eb285752559382a3d'
//           '&Type=json'
//           '&pIndex=1'
//           '&pSize=100'
//           '&ATPT_OFCDC_SC_CODE=$_selectedRegionCode'
//           '&SCHUL_NM=$schoolName';
//
//       print('학교 검색 API 요청: $url');
//       final response = await http.get(Uri.parse(url));
//       print('학교 검색 응답: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data.containsKey('schoolInfo')) {
//           final List<dynamic> schools = data['schoolInfo'][1]['row'];
//           setState(() {
//             _searchResults = schools.map<Map<String, String>>((school) => {
//               'name': school['SCHUL_NM'],
//               'code': school['SD_SCHUL_CODE'],
//               'address': school['ORG_RDNMA'],
//             }).toList();
//           });
//         } else {
//           _showErrorSnackBar('검색된 학교가 없습니다');
//         }
//       } else {
//         throw Exception('서버 응답 오류');
//       }
//     } catch (e) {
//       print('학교 검색 오류: $e');
//       _showErrorSnackBar('검색 중 오류가 발생했습니다');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text('학교 검색'),
//       content: Container(
//         width: double.maxFinite,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             DropdownButton<String>(
//               isExpanded: true,
//               value: _selectedRegionCode,
//               hint: Text('시·도 교육청 선택'),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedRegionCode = value;
//                 });
//               },
//               items: regionCodes.entries.map((entry) {
//                 return DropdownMenuItem(
//                   value: entry.value,
//                   child: Text(entry.key),
//                 );
//               }).toList(),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _schoolNameController,
//               decoration: InputDecoration(
//                 labelText: '학교명',
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.search),
//                   onPressed: _searchSchool,
//                 ),
//               ),
//               onSubmitted: (_) => _searchSchool(),
//             ),
//             SizedBox(height: 16),
//             if (_isLoading)
//               CircularProgressIndicator()
//             else if (_searchResults.isNotEmpty)
//               Expanded(
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: _searchResults.length,
//                   itemBuilder: (context, index) {
//                     final school = _searchResults[index];
//                     return ListTile(
//                       title: Text(school['name']!),
//                       subtitle: Text(school['address'] ?? ''),
//                       onTap: () {
//                         Navigator.of(context).pop({
//                           'schoolCode': school['code'],
//                           'schoolName': school['name'],
//                           'regionCode': _selectedRegionCode,
//                         });
//                       },
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: Text('취소'),
//         ),
//       ],
//     );
//   }
// }