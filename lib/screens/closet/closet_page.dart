import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'closetpage/add_clothing_page.dart';
import 'closetpage/fitting_in_closet_top.dart';

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
  String selectedCategory = '전체';
  final TextEditingController _searchController = TextEditingController();

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

  Future<void> deleteSelectedItems() async {
    try {
      for (String key in selectedItems) {
        final snapshot = await _clothingRef.child(key).get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final imageUrl = data['imageUrl'] as String;

          try {
            final uri = Uri.parse(imageUrl);
            final imagePath = uri.path.split('/o/').last;
            final decodedPath = Uri.decodeFull(imagePath.split('?').first);

            await FirebaseStorage.instance.ref(decodedPath).delete();
          } catch (e) {
            print('Storage 삭제 오류: $e');
          }

          await _clothingRef.child(key).remove();
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

  List<MapEntry<dynamic, dynamic>> filterClothing(
      List<MapEntry<dynamic, dynamic>> clothing, String searchQuery) {
    if (searchQuery.isEmpty) return clothing;

    return clothing.where((entry) {
      final item = entry.value as Map<dynamic, dynamic>;
      final name = (item['name'] ?? '').toString().toLowerCase();
      final size = (item['size'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      return name.contains(query) || size.contains(query);
    }).toList();
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

            // 카테고리 버튼들과 삭제 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCategoryButton('전체', Icons.checkroom),
                      _buildCategoryButton('상의', Icons.checkroom),
                      _buildCategoryButton('하의', Icons.checkroom),
                      _buildCategoryButton('신발', Icons.checkroom),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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

            // 그리드 뷰 (옷 목록)
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                // 여기 경로 수정
                stream: _clothingRef.onValue,  // 수정된 참조 사용
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('에러가 발생했습니다'));
                  }

                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    return Center(child: Text('등록된 옷이 없습니다'));
                  }

                  Map<dynamic, dynamic> clothingMap =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  // 카테고리별 필터링
                  List<MapEntry<dynamic, dynamic>> filteredClothing =
                  clothingMap.entries.where((entry) {
                    Map<dynamic, dynamic> clothing = entry.value as Map<dynamic, dynamic>;
                    return selectedCategory == '전체' ||
                        clothing['category'] == selectedCategory;
                  }).toList();

                  // 검색어로 추가 필터링
                  if (isSearchVisible && _searchController.text.isNotEmpty) {
                    filteredClothing = filterClothing(
                        filteredClothing, _searchController.text);
                  }

                  if (filteredClothing.isEmpty) {
                    return Center(
                      child: Text(
                        isSearchVisible && _searchController.text.isNotEmpty
                            ? '검색 결과가 없습니다'
                            : '${selectedCategory}에 등록된 옷이 없습니다',
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
                      String key = filteredClothing[index].key;
                      Map<dynamic, dynamic> clothing = filteredClothing[index].value;
                      bool isSelected = selectedItems.contains(key);

                      return Stack(
                        children: [
                          Container(
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
                                      clothing['imageUrl'],
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
                                            clothing['name'] ?? '',
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
                                            'Size: ${clothing['size'] ?? ''}',
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
                                  if (isDeleteMode)
                                    Positioned.fill(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                selectedItems.remove(key);
                                              } else {
                                                selectedItems.add(key);
                                              }
                                            });
                                          },
                                          child: Container(
                                            color: Colors.black.withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
            final clothingRef = FirebaseDatabase.instance
                .ref()
                .child('users')
                .child(_userId)
                .child('children')
                .child(_childId!)
                .child('clothing');

            final snapshot = await clothingRef.get();
            if (snapshot.exists) {
              final data = snapshot.value as Map<dynamic, dynamic>;

              // 상의 카테고리만 필터링
              final topClothes = data.entries
                  .where((entry) {
                final clothing = entry.value as Map<dynamic, dynamic>;
                return clothing['category'] == '상의';
              })
                  .map((entry) => entry.value as Map<dynamic, dynamic>)
                  .toList();

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FittingInClosetTop(
                      userId: _userId,
                      childId: _childId!, // 자녀 ID 전달
                      topClothes: topClothes,
                    ),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('등록된 옷이 없습니다')),
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

  Widget _buildCategoryButton(String label, IconData icon) {
    bool isSelected = selectedCategory == label;

    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
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
    );
  }
}