import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> childrenProfiles = [];
  bool _isLoading = true;
  bool isSelecting = false; // 선택 모드 여부
  Set<int> _selectedProfileIndices = {}; // 선택된 프로필 인덱스

  @override
  void initState() {
    super.initState();
    _loadChildrenProfiles();
  }

  Future<void> _loadChildrenProfiles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final childrenRef = FirebaseDatabase.instance.ref('users/${user.uid}/children');
      final snapshot = await childrenRef.get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> children = snapshot.value as Map<dynamic, dynamic>;
        final profiles = await Future.wait(children.keys.map((childKey) async {
          final childSnapshot =
          await FirebaseDatabase.instance.ref('children/$childKey').get();
          if (childSnapshot.exists) {
            final childData = childSnapshot.value as Map<dynamic, dynamic>;
            return {
              'key': childKey,
              'name': childData['name'] ?? '',
              'imageUrl': childData['profileImageUrl'] ?? '',
            };
          }
          return null;
        }));

        setState(() {
          childrenProfiles = profiles.where((profile) => profile != null).cast<Map<String, dynamic>>().toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading profiles: $e');
    }
  }

  void _toggleSelecting() {
    setState(() {
      if (isSelecting) {
        _selectedProfileIndices.clear();
      }
      isSelecting = !isSelecting;
    });
  }

  void _deleteSelectedProfiles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      for (int index in _selectedProfileIndices) {
        final childKey = childrenProfiles[index]['key'];
        if (childKey != null) {
          await FirebaseDatabase.instance.ref('children/$childKey').remove();
          await FirebaseDatabase.instance.ref('users/${user.uid}/children/$childKey').remove();
        }
      }

      setState(() {
        childrenProfiles = childrenProfiles
            .asMap()
            .entries
            .where((entry) => !_selectedProfileIndices.contains(entry.key))
            .map((entry) => entry.value)
            .toList();
        _selectedProfileIndices.clear();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선택한 아이의 프로필이 삭제되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 중 오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4E8D0),
      body: Center(
        child: Container(
          width: screenSize.width * 0.9,
          height: screenSize.height * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFFFEFBF0),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0, bottom: 20.0),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/logo2.png',
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.person_outline,
                              size: 30,
                              color: Colors.black87,
                            ),
                            onPressed: () => context.go('/mypage'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : childrenProfiles.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '등록된 아이가 없습니다.\n아이를 등록해주세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Column(
                              children: const [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.add,
                                    size: 40,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '등록하기',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: childrenProfiles.length + 1,
                      itemBuilder: (context, index) {
                        if (index < childrenProfiles.length) {
                          final child = childrenProfiles[index];
                          final isSelected =
                          _selectedProfileIndices.contains(index);

                          return GestureDetector(
                            onTap: () {
                              if (isSelecting) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedProfileIndices
                                        .remove(index);
                                  } else {
                                    _selectedProfileIndices.add(index);
                                  }
                                });
                              } else {
                                context.go(
                                  '/closet',
                                  extra: {
                                    'childName': child['name'],
                                    'childImage': child['imageUrl'],
                                  },
                                );
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage: NetworkImage(
                                          child['imageUrl'] ?? ''),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      child['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelecting)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isSelected
                                          ? const Color(0xFF7165D6)
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        } else {
                          return GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.add,
                                    size: 40,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '등록하기',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelecting)
                        FloatingActionButton(
                          onPressed: _deleteSelectedProfiles,
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        onPressed: _toggleSelecting,
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
