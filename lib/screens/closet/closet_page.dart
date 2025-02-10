import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'closetpage/add_clothing_page.dart';
import 'closetpage/clothing_detail_page.dart';
import 'closetpage/weather_widget.dart';
import 'closetpage/school_schedule_widget.dart';

class ClosetPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final bool selectionMode;  // 선택 모드 여부
  final String? allowedCategory;  // 선택 가능한 카테고리

  const ClosetPage({
    Key? key,
    required this.childInfo,
    this.selectionMode = false,
    this.allowedCategory,
  }) : super(key: key);

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String? _childProfileUrl;
  String? _childName;
  String? _childId;
  bool isDeleteMode = false;
  bool isSearchVisible = false;
  Set<String> selectedItems = {};
  String selectedFilter = '카테고리';
  String selectedCategory = '전체';
  Set<String> selectedSeasons = {'전체'};
  String selectedColor = '전체';
  final TextEditingController _searchController = TextEditingController();

  final List<String> filterTypes = ['카테고리', '계절', '색상','즐겨찾기'];
  final List<String> seasons = ['전체', '봄', '여름', '가을', '겨울', '사계절'];

  final Map<String, String> categoryImages = {
    '전체': 'assets/images/categories/free-icon-hanger-69981.png',
    '올인원': 'assets/images/categories/free-icon-onesie-1012727.png',
    '아우터': 'assets/images/categories/outer.png',
    '상의': 'assets/images/categories/free-icon-shirt-16882503.png',
    '하의': 'assets/images/categories/free-icon-pants-8190299.png',
    '신발': 'assets/images/categories/free-icon-shoes-7606033.png',
  };

  List<MapEntry<dynamic, dynamic>> filteredClothing = [];


  @override
  void initState() {
    super.initState();
    _initializeChildData();

    // selectionMode일 때 자동으로 카테고리 설정
    if (widget.selectionMode && widget.allowedCategory != null) {
      selectedCategory = widget.allowedCategory!;
      selectedFilter = '카테고리';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeChildData() {
    setState(() {
      _childProfileUrl = widget.childInfo['childImage'];
      _childName = widget.childInfo['childName'];
      _childId = widget.childInfo['childId'];
    });
  }

  DatabaseReference get _clothingRef => FirebaseDatabase.instance
      .ref()
      .child('users')
      .child(_userId)
      .child('children')
      .child(_childId!)
      .child('clothing');

  Reference get _storageRef => FirebaseStorage.instance
      .ref()
      .child('users')
      .child(_userId)
      .child('children')
      .child(_childId!)
      .child('clothing');

  List<MapEntry<dynamic, dynamic>> filterClothing(
      List<MapEntry<dynamic, dynamic>> clothing, String searchQuery) {
    if (searchQuery.isNotEmpty) {
      clothing = clothing.where((entry) {
        final item = entry.value as Map<dynamic, dynamic>;
        final name = (item['name'] ?? '').toString().toLowerCase();
        final size = (item['size'] ?? '').toString().toLowerCase();
        final memo = (item['memo'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();

        return name.contains(query) ||
            size.contains(query) ||
            memo.contains(query);
      }).toList();
    }

    // 카테고리 필터링
    if (selectedFilter == '카테고리' && selectedCategory != '전체') {
      clothing = clothing.where((entry) {
        final item = entry.value as Map<dynamic, dynamic>;
        return item['category'] == selectedCategory;
      }).toList();
    }

    // 계절 필터링
    if (selectedFilter == '계절' && !selectedSeasons.contains('전체')) {
      clothing = clothing.where((entry) {
        final item = entry.value as Map<dynamic, dynamic>;
        final itemSeasons = item['season'];

        if (itemSeasons is List) {
          return itemSeasons.any((season) => selectedSeasons.contains(season));
        } else if (itemSeasons is String) {
          return selectedSeasons.contains(itemSeasons);
        }
        return false;
      }).toList();
    }

    // 색상 필터링
    if (selectedFilter == '색상' && selectedColor != '전체') {
      clothing = clothing.where((entry) {
        final item = entry.value as Map<dynamic, dynamic>;
        return item['color'] == selectedColor;
      }).toList();
    }

    // 즐겨찾기 필터링 추가
    if (selectedFilter == '즐겨찾기') {
      clothing = clothing.where((entry) {
        final item = entry.value as Map<dynamic, dynamic>;
        return item['isFavorite'] == true;
      }).toList();
    }

    // 선택 모드에서 카테고리 제한
    if (widget.selectionMode && widget.allowedCategory != null) {
      clothing = clothing.where((entry) {
        final item = entry.value as Map<dynamic, dynamic>;
        final itemCategory = item['category']?.toString() ?? '';
        return itemCategory == widget.allowedCategory;
      }).toList();
    }

    return clothing;
  }

  Future<void> deleteSelectedItems() async {
    try {
      for (String key in selectedItems) {
        final categories = ['올인원','아우터', '상의', '하의', '신발'];
        for (String category in categories) {
          final categoryRef = _clothingRef.child(category);
          final itemSnapshot = await categoryRef.child(key).get();

          if (itemSnapshot.exists) {
            final data = itemSnapshot.value as Map<dynamic, dynamic>;
            final imageUrl = data['imageUrl'] as String;

            try {
              final uri = Uri.parse(imageUrl);
              final imagePath = uri.path.split('/o/').last;
              final decodedPath = Uri.decodeFull(imagePath.split('?').first);
              await FirebaseStorage.instance.ref(decodedPath).delete();
            } catch (e) {
              print('Storage 삭제 오류: $e');
            }

            await categoryRef.child(key).remove();
            break;
          }
        }
      }

      setState(() {
        isDeleteMode = false;
        selectedItems.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 아이템이 삭제되었습니다')),
      );
    } catch (e) {
      print('삭제 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.selectionMode ? AppBar(
        title: Text('${widget.allowedCategory} 선택'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.selectionMode) ...[
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: _childProfileUrl != null
                              ? NetworkImage(_childProfileUrl!)
                              : AssetImage('assets/images/profile.jpg') as ImageProvider,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _childName != null ? '${_childName}의 옷장' : 'OOO의 옷장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          WeatherWidget(),
                          SizedBox(height: 4),
                          //SchoolScheduleWidget(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 필터 옵션들
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterTypes.map((type) {
                        bool isSelected = selectedFilter == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  selectedFilter = type;
                                  if (type != '즐겨찾기') {
                                    selectedCategory = '전체';
                                    selectedSeasons = {'전체'};
                                    selectedColor = '전체';
                                  }
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (selectedFilter == '카테고리') ...[
                          // selectionMode가 true일 때는 카테고리 UI만 숨기고 기능은 유지
                          if (!widget.selectionMode) ...[
                            _buildCategoryButton('전체'),
                            SizedBox(width: 16),
                            _buildCategoryButton('올인원'),
                            SizedBox(width: 16),
                            _buildCategoryButton('아우터'),
                            SizedBox(width: 16),
                            _buildCategoryButton('상의'),
                            SizedBox(width: 16),
                            _buildCategoryButton('하의'),
                            SizedBox(width: 16),
                            _buildCategoryButton('신발'),
                          ],
                          // selectedCategory와 필터링 로직은 그대로 유지
                          if (widget.selectionMode) ...[
                            // UI는 숨기지만 selectedCategory는 widget.allowedCategory로 자동 설정
                            Container(
                              height: 0,
                              child: Text('', style: TextStyle(height: 0)),
                            ),
                          ],
                        ]
                        else if (selectedFilter == '계절')
                          Row(
                            children: seasons.map((season) {
                              bool isSelected = selectedSeasons.contains(season);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(season),
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedSeasons.clear();
                                        selectedSeasons.add(season);
                                      } else {
                                        selectedSeasons.remove(season);
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          )
                        else if (selectedFilter == '색상')
                            Row(
                              children: [
                                _buildColorBox('전체', Colors.transparent),
                                SizedBox(width: 8),
                                _buildColorBox('흰색', Colors.white),
                                SizedBox(width: 8),
                                _buildColorBox('검정', Colors.black),
                                SizedBox(width: 8),
                                _buildColorBox('회색', Colors.grey),
                                SizedBox(width: 8),
                                _buildColorBox('빨강', Colors.red),
                                SizedBox(width: 8),
                                _buildColorBox('분홍', Colors.pink),
                                SizedBox(width: 8),
                                _buildColorBox('주황', Colors.orange),
                                SizedBox(width: 8),
                                _buildColorBox('노랑', Colors.yellow),
                                SizedBox(width: 8),
                                _buildColorBox('초록', Colors.green),
                                SizedBox(width: 8),
                                _buildColorBox('파랑', Colors.blue),
                                SizedBox(width: 8),
                                _buildColorBox('남색', Colors.indigo),
                                SizedBox(width: 8),
                                _buildColorBox('보라', Colors.purple),
                                SizedBox(width: 8),
                                _buildColorBox('갈색', Colors.brown),
                              ],
                            ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // 삭제와 검색 버튼을 카테고리 버튼들 아래로 이동
                  if (!widget.selectionMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 삭제 버튼 (왼쪽)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              isDeleteMode = !isDeleteMode;
                              if (!isDeleteMode) {
                                selectedItems.clear();
                              }
                            });
                          },
                          icon: Icon(
                            isDeleteMode ? Icons.close : Icons.delete_outline,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          label: Text(
                            isDeleteMode ? '취소' : '삭제',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        // 검색 버튼 (오른쪽)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              isSearchVisible = !isSearchVisible;
                              if (!isSearchVisible) {
                                _searchController.clear();
                              }
                            });
                          },
                          icon: Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          label: Text(
                            '검색',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  if (isSearchVisible) ...[
                    SizedBox(height: 16),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '검색어를 입력하세요',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search, size: 22),
                          border: InputBorder.none,
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _clothingRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('에러가 발생했습니다'));
                  }

                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    return Center(child: Text('등록된 옷이 없습니다'));
                  }

                  Map<dynamic, dynamic> categories =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  filteredClothing.clear();

                  categories.forEach((category, clothingItems) {
                    if (clothingItems != null && clothingItems is Map) {
                      clothingItems.forEach((key, value) {
                        if (value is Map) {
                          filteredClothing.add(MapEntry(key, value));
                        }
                      });
                    }
                  });

                  if (isSearchVisible && _searchController.text.isNotEmpty) {
                    filteredClothing = filterClothing(filteredClothing, _searchController.text);
                  } else {
                    filteredClothing = filterClothing(filteredClothing, '');
                  }

                  if (filteredClothing.isEmpty) {
                    return Center(
                      child: Text(
                        isSearchVisible && _searchController.text.isNotEmpty
                            ? '검색 결과가 없습니다'
                            : selectedFilter == '즐겨찾기'
                            ? '즐겨찾기한 옷이 없습니다'
                            : '${selectedFilter == '카테고리' ? selectedCategory : selectedFilter == '계절' ? selectedSeasons.join(', ') : selectedColor}에 해당하는 옷이 없습니다',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: filteredClothing.length,
                    itemBuilder: (context, index) {
                      final MapEntry<dynamic, dynamic> entry = filteredClothing[index];
                      final String itemKey = entry.key;
                      final Map<dynamic, dynamic> itemData = entry.value;
                      bool isSelected = selectedItems.contains(itemKey);
                      bool isFavorite = itemData['isFavorite'] ?? false;


                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: widget.selectionMode
                                ? () {
                              // Map<dynamic, dynamic>을 Map<String, dynamic>으로 변환
                              final Map<String, dynamic> convertedData = Map<String, dynamic>.from(
                                  itemData.map((key, value) => MapEntry(key.toString(), value))
                              );
                              Navigator.pop(context, convertedData);
                            }
                                : isDeleteMode
                                ? () {
                              setState(() {
                                if (isSelected) {
                                  selectedItems.remove(itemKey);
                                } else {
                                  selectedItems.add(itemKey);
                                }
                              });
                            }
                                : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClothingDetailPage(
                                    clothing: itemData,
                                    clothingId: itemKey,
                                    category: itemData['category'] ?? selectedCategory,
                                    childId: _childId!,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        itemData['imageUrl'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // 즐겨찾기 아이콘 추가
                                    if (isFavorite)
                                      Positioned(
                                        left: 8,
                                        top: 8,
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.7),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        padding: EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              itemData['name'] ?? '',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Size: ${itemData['size'] ?? ''}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 10,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if ((isDeleteMode || widget.selectionMode) && isSelected)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.selectionMode ? null : Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.lightBlue.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddClothingPage(
                  childInfo: {
                    'childId': _childId,
                    'childName': _childName,
                    'childImage': _childProfileUrl,
                  },
                ),
              ),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
          elevation: 0,
          shape: CircleBorder(),
        ),
      ),
      bottomNavigationBar: (isDeleteMode && !widget.selectionMode)
          ? Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: selectedItems.isEmpty
              ? null
              : () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  content: Text(
                    '선택한 항목을 삭제하시겠습니까?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly, // 버튼 간격 균등 분배
                  actionsPadding: EdgeInsets.only(bottom: 8), // 하단 패딩 추가
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        deleteSelectedItems();
                      },
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '선택한 항목 삭제',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildColorBox(String colorName, Color color) {
    bool isSelected = selectedColor == colorName;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = colorName;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorName == '전체' ? Colors.white : color,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: colorName == '전체'
            ? Center(
          child: Text(
            '전체',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        )
            : isSelected
            ? Icon(
          Icons.check,
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        )
            : null,
      ),
    );
  }

  Widget _buildCategoryButton(String label) {
    bool isSelected = selectedCategory == label;

    return Container(
      width: 70,
      height: 75,
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedCategory = label;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                categoryImages[label]!,
                width: 32,
                height: 32,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}