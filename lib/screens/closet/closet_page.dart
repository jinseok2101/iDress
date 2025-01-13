import 'package:flutter/material.dart';
// AddClothingPage import 추가
import 'closetpage/add_clothing_page.dart';
import 'closetpage/search_page.dart';

class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  String selectedChildName = '아이 이름'; // Firebase에서 불러오는 로직 추가

  String searchQuery = '';
  String selectedCategory = '한벌옷';

  final List<Map<String, dynamic>> categories = [
    {'name': '한벌옷', 'icon': Icons.checkroom},
    {'name': '상의', 'icon': Icons.checkroom},
    {'name': '하의', 'icon': Icons.accessibility_new},
    {'name': '아우터', 'icon': Icons.layers},
    {'name': '신발', 'icon': Icons.shopping_bag},
  ];

  final List<Map<String, String>> clothingItems = [
    {'id': '1', 'name': '상의1', 'category': '상의'},
    {'id': '2', 'name': '상의2', 'category': '상의'},
    {'id': '3', 'name': '상의3', 'category': '상의'},
    {'id': '4', 'name': '상의4', 'category': '상의'},
  ];

  List<Map<String, String>> get filteredItems {
    return clothingItems.where((item) {
      // 카테고리 필터링
      final categoryMatch = item['category'] == selectedCategory;
      // 검색어 필터링
      final searchMatch = searchQuery.isEmpty ||
          item['name']!.toLowerCase().contains(searchQuery.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title:  Text(
          '${selectedChildName}의 옷장',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector( // TextField를 GestureDetector로 감싸기
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchPage(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IgnorePointer( // 실제 TextField는 탭 불가능하게 설정
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '검색',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 카테고리 목록
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category['name'];
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            category['icon'],
                            color: selectedCategory == category['name']
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            color: selectedCategory == category['name']
                                ? Colors.blue
                                : Colors.black,
                            fontWeight: selectedCategory == category['name']
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 자녀 선택 및 옷 추가 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddClothingPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  '+ 옷 추가',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),


          // 옷 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(item['name']!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}