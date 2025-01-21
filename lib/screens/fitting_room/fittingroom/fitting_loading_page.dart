import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'fitting_result_page.dart';

class FittingLoadingPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final File? topImage;
  final File? bottomImage;
  final bool isOnepiece;  // 추가

  const FittingLoadingPage({
    Key? key,
    required this.childInfo,
    this.topImage,
    this.bottomImage,
    required this.isOnepiece,  // 추가
  }) : super(key: key);

  @override
  State<FittingLoadingPage> createState() => _FittingLoadingPageState();
}

class _FittingLoadingPageState extends State<FittingLoadingPage> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FittingResultPage(
            childInfo: widget.childInfo,
            topImageFile: widget.topImage ?? File(''),
            bottomImageFile: widget.bottomImage ?? File(''),
            isOnepiece: widget.isOnepiece,  // isOnepiece 값 전달
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 상단 피팅룸 로고와 텍스트
            SizedBox(height: 40),
            Icon(Icons.checkroom, size: 40, color: Colors.black),
            SizedBox(height: 8),
            Text(
              '피팅룸',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // 중앙 로딩 영역
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(height: 40),
                    Text(
                      '아이에게 옷을 입히는 중이에요!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
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