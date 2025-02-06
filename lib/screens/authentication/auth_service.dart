import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao_sdk;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Auth {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  // Google Login
  Future<firebase_auth.User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In 취소됨');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final oauthCredential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) return null;

      // FirebaseMessaging 토큰 관리
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      await _storeUserInfoInPrefs(user, token);

      final uid = user.uid;
      bool userExists = await isRegisteredByUID(uid);

      debugPrint('사용자 존재 여부: $userExists');

      if (!userExists) {
        // 새 사용자인 경우
        final databaseRef = FirebaseDatabase.instance.ref("users/$uid");
        await databaseRef.set({
          "id": uid,
          "username": user.displayName ?? 'Unknown',
          "createdAt": DateTime.now().toIso8601String(),
          "isNewUser": true,
        });

        if (context.mounted) {
          debugPrint('신규 사용자: /signup으로 이동');
          context.go('/signup');
        }
      } else {
        if (context.mounted) {
          debugPrint('기존 사용자: /home으로 이동');
          context.go('/home');
        }
      }

      return user;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return null;
    }
  }

  // Kakao Login
  Future<firebase_auth.User?> signInWithKakao(BuildContext context) async {
    try {
      final kakao_sdk.OAuthToken kakaoToken = await kakao_sdk.UserApi.instance.loginWithKakaoAccount();
      debugPrint('카카오 로그인 성공: accessToken=${kakaoToken.accessToken}, idToken=${kakaoToken.idToken}');

      if (kakaoToken.idToken == null || kakaoToken.accessToken == null) {
        debugPrint('카카오 로그인 토큰이 null입니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오 로그인 토큰이 유효하지 않습니다. 다시 시도해주세요.')),
        );
        return null;
      }

      var provider = firebase_auth.OAuthProvider("oidc.kakao");
      var credential = provider.credential(
        idToken: kakaoToken.idToken,
        accessToken: kakaoToken.accessToken,
      );
      debugPrint('Firebase Credential 생성 성공');

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        debugPrint('Firebase 사용자 생성 실패: userCredential.user가 null입니다.');
        return null;
      }

      debugPrint('Firebase 사용자 생성 성공: UID=${firebaseUser.uid}');

      // 사용자 유형 확인 및 화면 이동
      bool userExists = await isRegisteredByUID(firebaseUser.uid);
      if (userExists) {
        context.go('/home'); // 기존 사용자
      } else {
        final databaseRef = FirebaseDatabase.instance.ref("users/${firebaseUser.uid}");
        await databaseRef.set({
          "id": firebaseUser.uid,
          "username": firebaseUser.displayName ?? 'Unknown',
          "createdAt": DateTime.now().toIso8601String(),
          "isNewUser": true,
        });
        context.go('/signup'); // 신규 사용자
      }

      return firebaseUser;
    } catch (e) {
      debugPrint('카카오 로그인 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 실패: $e')),
      );
      return null;
    }
  }

  // 로그아웃 및 사용자 삭제
  Future<void> logout(BuildContext context) async {
    if (context.mounted) {
      context.go('/start');
    }

    try {
      // Firebase 로그아웃
      await _firebaseAuth.signOut();
      debugPrint('Firebase 로그아웃 성공');
    } catch (e) {
      debugPrint('Firebase 로그아웃 실패: $e');
    }

    try {
      // Google 로그아웃
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      debugPrint('Google 로그아웃 성공');
    } catch (e) {
      debugPrint('Google 로그아웃 실패: $e');
    }

    try {
      // 카카오 로그아웃
      await kakao_sdk.UserApi.instance.logout();
      debugPrint('카카오 로그아웃 성공');
    } catch (e) {
      debugPrint('카카오 로그아웃 실패: $e');
    }

    // 로컬 데이터 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('로컬 데이터 삭제 완료');
  }

  Future<void> deleteAccount(BuildContext context) async {
    if (context.mounted) {
      context.go('/start');
    }

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
      debugPrint('Checkpoint: 로딩 스피너 닫기 완료');
    } else {
      debugPrint('Checkpoint: 로딩 스피너를 닫을 수 없습니다. Navigator.canPop: ${Navigator.canPop(context)}');
    }

    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // 1. Firebase Storage 데이터 삭제
        final storageRef = FirebaseStorage.instance.ref().child('users/${user.uid}');
        try {
          // 해당 사용자의 모든 파일 리스트 가져오기
          final ListResult result = await storageRef.listAll();

          // 모든 파일 삭제
          for (var item in result.items) {
            await item.delete();
            debugPrint('Storage 파일 삭제 완료: ${item.fullPath}');
          }

          // 모든 하위 폴더 삭제
          for (var prefix in result.prefixes) {
            final subResult = await prefix.listAll();
            for (var item in subResult.items) {
              await item.delete();
              debugPrint('Storage 하위 폴더 파일 삭제 완료: ${item.fullPath}');
            }
          }

          debugPrint('Checkpoint: Firebase Storage 데이터 삭제 완료');
        } catch (e) {
          debugPrint('Firebase Storage 데이터 삭제 실패: $e');
        }

        // 2. Realtime Database 데이터 삭제
        final databaseRef = FirebaseDatabase.instance.ref("users/${user.uid}");
        await databaseRef.remove();
        debugPrint('Checkpoint: Firebase Database 데이터 삭제 완료');

        // 3. Authentication 계정 삭제
        await user.delete();
        debugPrint('Checkpoint: Firebase Authentication 계정 삭제 완료');
      } else {
        debugPrint('Checkpoint: 삭제할 Firebase 계정이 없습니다.');
        return;
      }
    } catch (e) {
      debugPrint('Firebase 계정 또는 데이터 삭제 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('계정 삭제 실패: $e')),
        );
      }
    }

    try {
      await kakao_sdk.UserApi.instance.unlink();
      debugPrint('Checkpoint: 카카오 연동 해제 완료');
    } catch (e) {
      debugPrint('카카오 연동 해제 실패: $e');
    }

    try {
      await _firebaseAuth.signOut();
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('Checkpoint: 로컬 데이터 삭제 완료');
    } catch (e) {
      debugPrint('로그아웃 처리 중 오류 발생: $e');
    }
  }

  // UID로 사용자 확인
  Future<bool> isRegisteredByUID(String uid) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref("users/$uid");
      final snapshot = await databaseRef.get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        return userData.containsKey('createdAt');
      }
      return false;
    } catch (e) {
      debugPrint('UID 확인 중 오류 발생: $e');
      return false;
    }
  }



  Future<void> _storeUserInfoInPrefs(firebase_auth.User user, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user.email ?? '');
    await prefs.setString('user_name', user.displayName ?? 'Unknown');
    await prefs.setString('user_token', token ?? '');
  }
}
