import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'closetpage/add_clothing_page.dart';
import 'closetpage/fitting_in_closet_top.dart';
import 'closetpage/clothing_detail_page.dart';
import 'closetpage/fitting_in_closet_set.dart';
import 'closetpage/fitting_in_closet_pants.dart';
import 'package:last3/screens/fitting_room/fittingroom/fitting_result_page.dart';

class ClosetPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;

  const ClosetPage({
    Key? key,
    required this.childInfo,
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
  Set<String> selectedSeasons = {'전체'}; // 수정된 부분: 여러 계절 선택
  String selectedColor = '전체';
  final TextEditingController _searchController = TextEditingController();

  final List<String> filterTypes = ['카테고리', '계절', '색상'];
  final List<String> seasons = ['전체', '봄', '여름', '가을', '겨울', '사계절'];

  @override
  void initState() {
    super.initState();
    _initializeChildData();
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

    switch (selectedFilter) {
      case '카테고리':
        if (selectedCategory != '전체') {
          clothing = clothing.where((entry) {
            final item = entry.value as Map<dynamic, dynamic>;
            return item['category'] == selectedCategory;
          }).toList();
        }
        break;
      case '계절':
        if (!selectedSeasons.contains('전체')) {
          clothing = clothing.where((entry) {
            final item = entry.value as Map<dynamic, dynamic>;
            return selectedSeasons.contains(item['season']);
          }).toList();
        }
        break;
      case '색상':
        if (selectedColor != '전체') {
          clothing = clothing.where((entry) {
            final item = entry.value as Map<dynamic, dynamic>;
            return item['color'] == selectedColor;
          }).toList();
        }
        break;
    }

    return clothing;
  }

  Future<void> deleteSelectedItems() async {
    try {
      for (String key in selectedItems) {
        final categories = ['한벌옷', '상의', '하의', '신발'];
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
      body: SafeArea(
        child: Column(
          children: [
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
                            : AssetImage('assets/images/profile.jpg')
                        as ImageProvider,
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
                  SizedBox(width: 32),
                  Row(
                    children: [
                      _buildActionButtonWithLabel(
                        icon: Icons.checkroom,
                        label: '피팅하기',
                        backgroundColor: Colors.blue[50]!,
                        context: context,
                      ),
                      SizedBox(width: 16),
                      _buildActionButtonWithLabel(
                        icon: Icons.camera_alt,
                        label: '옷 추가',
                        backgroundColor: Colors.blue[50]!,
                        context: context,
                      ),
                      SizedBox(width: 16),
                      _buildActionButtonWithLabel(
                        icon: Icons.search,
                        label: '옷 검색',
                        backgroundColor: Colors.blue[50]!,
                        onTap: () {
                          setState(() {
                            isSearchVisible = !isSearchVisible;
                            if (!isSearchVisible) {
                              _searchController.clear();
                            }
                          });
                        },
                        context: context,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  selectedCategory = '전체';
                                  selectedSeasons = {'전체'}; // 초기화
                                  selectedColor = '전체';
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
                        if (selectedFilter == '카테고리')
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildCategoryButton('전체', Icons.checkroom),
                                SizedBox(width: 16),
                                _buildCategoryButton('한벌옷', Icons.accessibility_new),
                                SizedBox(width: 16),
                                _buildCategoryButton('상의', Icons.checkroom),
                                SizedBox(width: 16),
                                _buildCategoryButton('하의', Icons.checkroom),
                                SizedBox(width: 16),
                                _buildCategoryButton('신발', Icons.checkroom),
                              ],
                            ),
                          )
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
                                      if (season == '전체') {
                                        selectedSeasons.clear();
                                        selectedSeasons.add('전체');
                                      } else {
                                        if (selected) {
                                          selectedSeasons.add(season);
                                          selectedSeasons.remove('전체');
                                        } else {
                                          selectedSeasons.remove(season);
                                        }
                                        if (selectedSeasons.isEmpty) {
                                          selectedSeasons.add('전체');
                                        }
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          )
                        else if (selectedFilter == '색상')
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildColorBox('전체', Colors.transparent),
                                _buildColorBox('흰색', Colors.white),
                                _buildColorBox('검정', Colors.black),
                                _buildColorBox('빨강', Colors.red),
                                _buildColorBox('주황', Colors.orange),
                                _buildColorBox('노랑', Colors.yellow),
                                _buildColorBox('초록', Colors.green),
                                _buildColorBox('파랑', Colors.blue),
                                _buildColorBox('남색', Colors.indigo),
                                _buildColorBox('보라', Colors.purple),
                                _buildColorBox('회색', Colors.grey),
                                _buildColorBox('분홍', Colors.pink),
                                _buildColorBox('갈색', Colors.brown),
                              ],
                            ),
                      ],
                    ),
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
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                    ],
                  ),
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
                  List<MapEntry<dynamic, dynamic>> filteredClothing = [];

                  categories.forEach((category, clothingItems) {
                    if (clothingItems != null && clothingItems is Map) {
                      clothingItems.forEach((key, value) {
                        if (value is Map) {
                          filteredClothing.add(MapEntry(key, value));
                        }
                      });
                    }
                  });

                  // 검색어와 선택된 필터로 필터링 적용
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

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: isDeleteMode
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
                          if (isDeleteMode && isSelected)
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
      bottomNavigationBar: isDeleteMode
          ? Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: selectedItems.isEmpty ? null : deleteSelectedItems,
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

  Widget _buildActionButtonWithLabel({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required BuildContext context,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () async {
        if (label == '옷 추가') {
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
        } else if (label == '피팅하기') {
          try {
            final setRef = FirebaseDatabase.instance
                .ref()
                .child('users')
                .child(_userId)
                .child('children')
                .child(_childId!)
                .child('clothing')
                .child('한벌옷');

            final setSnapshot = await setRef.get();
            if (setSnapshot.exists) {
              final setData = setSnapshot.value as Map<dynamic, dynamic>;
              List<Map<dynamic, dynamic>> setClothingList = [];
              setData.forEach((key, value) {
                if (value is Map && value['category'] == '한벌옷') {
                  setClothingList.add(Map<dynamic, dynamic>.from(value));
                }
              });

              if (mounted && setClothingList.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FittingInClosetSet(
                      userId: _userId,
                      childId: _childId!,
                      setClothes: setClothingList,
                    ),
                  ),
                );
                return;
              }
            }

            final topRef = FirebaseDatabase.instance
                .ref()
                .child('users')
                .child(_userId)
                .child('children')
                .child(_childId!)
                .child('clothing')
                .child('상의');

            final topSnapshot = await topRef.get();
            if (topSnapshot.exists) {
              final topData = topSnapshot.value as Map<dynamic, dynamic>;
              List<Map<dynamic, dynamic>> topClothingList = [];
              topData.forEach((key, value) {
                if (value is Map && value['category'] == '상의') {
                  topClothingList.add(Map<dynamic, dynamic>.from(value));
                }
              });

              if (mounted && topClothingList.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FittingInClosetTop(
                      userId: _userId,
                      childId: _childId!,
                      topClothes: topClothingList,
                    ),
                  ),
                );
                return;
              }
            }

            final pantsRef = FirebaseDatabase.instance
                .ref()
                .child('users')
                .child(_userId)
                .child('children')
                .child(_childId!)
                .child('clothing')
                .child('하의');

            final pantsSnapshot = await pantsRef.get();
            if (pantsSnapshot.exists) {
              final pantsData = pantsSnapshot.value as Map<dynamic, dynamic>;
              List<Map<dynamic, dynamic>> pantsClothingList = [];
              pantsData.forEach((key, value) {
                if (value is Map && value['category'] == '하의') {
                  pantsClothingList.add(Map<dynamic, dynamic>.from(value));
                }
              });

              if (mounted && pantsClothingList.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FittingInClosetPants(
                      userId: _userId,
                      childId: _childId!,
                      pantsClothes: pantsClothingList,
                      selectedTopImageUrl: '',
                    ),
                  ),
                );
                return;
              }
            }

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FittingResultPage(
                    childInfo: {
                      'childId': _childId,
                      'childName': _childName,
                      'childImage': _childProfileUrl,
                    },
                    topImage: '',
                    bottomImage: '',
                    isOnepiece: false,
                    isFromCloset: true,
                  ),
                ),
              );
            }
          } catch (e) {
            print('데이터 로드 오류: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다')),
            );
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 30,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
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

  Widget _buildCategoryButton(String label, IconData icon) {
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
              Icon(
                icon,
                size: 32,
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