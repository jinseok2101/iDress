import 'package:flutter/material.dart';
import 'package:last3/screens/home/home_screen.dart';
import 'package:go_router/go_router.dart';
import 'fitting_room/fitting_room_page.dart';
import 'closet/closet_page.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic>? childInfo;
  const MainScreen({Key? key, this.childInfo}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _showBottomNav = true;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    if (widget.childInfo == null) {
      _screens = [
        _buildNoChildInfoScreen(),
        const HomeScreen(),
        _buildNoChildInfoScreen(),
      ];
    } else {
      _screens = [
        ClosetPage(childInfo: widget.childInfo!),
        const HomeScreen(),
        FittingRoomPage(
          childInfo: widget.childInfo!,
          fullBodyImageUrl: widget.childInfo!['fullBodyImageUrl'],
        ),
      ];
    }
  }

  Widget _buildNoChildInfoScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '자녀 정보가 없습니다.\n프로필에서 자녀를 선택해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      context.go('/home');
    } else {
      if (widget.childInfo == null && (index == 0 || index == 2)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필에서 자녀를 먼저 선택해주세요'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _selectedIndex = index;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom),
            label: '옷장',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.door_sliding),
            label: '피팅룸',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.childInfo != oldWidget.childInfo) {
      _initializeScreens();
    }
  }
}