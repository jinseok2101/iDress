import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'fitting_result_page.dart';

class FittingLoadingPage extends StatefulWidget {
  final Map<String, dynamic> childInfo;
  final dynamic topImage;  // File 또는 String을 받을 수 있도록 dynamic으로 변경
  final dynamic bottomImage;  // File 또는 String을 받을 수 있도록 dynamic으로 변경
  final bool isOnepiece;
  final bool isFromCloset;

  const FittingLoadingPage({
    Key? key,
    required this.childInfo,
    this.topImage,
    this.bottomImage,
    required this.isOnepiece,
    required this.isFromCloset,
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
            topImage: widget.topImage ?? (widget.isFromCloset ? '' : File('')),
            bottomImage: widget.bottomImage ?? (widget.isFromCloset ? '' : File('')),
            isOnepiece: widget.isOnepiece,
            isFromCloset: widget.isFromCloset,
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
              widget.isFromCloset ? '옷장 피팅' : '피팅룸',  // 출처에 따라 다른 텍스트 표시
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