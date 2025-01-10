import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = []; // 최근 검색어 리스트

  // 검색어 추가 함수
  void addSearchTerm(String term) {
    if (term.isEmpty) return; // 빈 검색어는 추가하지 않음

    setState(() {
      // 이미 존재하는 검색어라면 제거 (중복 방지)
      recentSearches.remove(term);
      // 리스트 맨 앞에 새 검색어 추가
      recentSearches.insert(0, term);
      // 최대 10개까지만 저장
      if (recentSearches.length > 10) {
        recentSearches.removeLast();
      }
    });

    // 검색 후 텍스트 필드 비우기
    _searchController.clear();
  }

  // 전체 삭제 함수
  void clearSearchHistory() {
    setState(() {
      recentSearches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 검색바
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onSubmitted: (value) => addSearchTerm(value), // 엔터키 눌렀을 때 검색어 추가
                decoration: InputDecoration(
                  hintText: '검색어 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => addSearchTerm(_searchController.text), // 검색 버튼 눌렀을 때 검색어 추가
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 최근 검색어 텍스트
            const Text(
              '최근검색어',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // 최근 검색어 목록을 표시할 흰색 컨테이너
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // 전체 삭제 버튼
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onTap: clearSearchHistory,
                          child: Text(
                            '전체삭제',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 최근 검색어 목록
                    Expanded(
                      child: ListView.builder(
                        itemCount: recentSearches.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(recentSearches[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  recentSearches.removeAt(index);
                                });
                              },
                            ),
                            onTap: () {
                              // 검색어 탭했을 때 처리
                              _searchController.text = recentSearches[index];
                              addSearchTerm(recentSearches[index]);
                            },
                          );
                        },
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