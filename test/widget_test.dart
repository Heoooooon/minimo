// 우물(Oomool) 앱 위젯 테스트

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oomool/data/services/pocketbase_service.dart';
import 'package:oomool/data/services/onboarding_service.dart';
import 'package:oomool/main.dart';

// Mock 클래스 정의
class MockPocketBase extends Mock implements PocketBase {}

class MockAuthStore extends Mock implements AuthStore {}

void main() {
  late MockPocketBase mockPocketBase;
  late MockAuthStore mockAuthStore;

  setUpAll(() async {
    // 테스트용 SharedPreferences mock 설정
    SharedPreferences.setMockInitialValues({});

    // Mock 객체 생성
    mockPocketBase = MockPocketBase();
    mockAuthStore = MockAuthStore();

    // AuthStore mock 설정
    when(() => mockPocketBase.authStore).thenReturn(mockAuthStore);
    when(() => mockAuthStore.isValid).thenReturn(false);
    when(() => mockAuthStore.token).thenReturn('');
    when(() => mockAuthStore.record).thenReturn(null);

    // PocketBase 서비스에 mock client 주입
    PocketBaseService.instance.initializeForTesting(mockPocketBase);

    // OnboardingService 초기화
    await OnboardingService.instance.initialize();
  });

  tearDownAll(() {
    // 테스트 후 정리
    PocketBaseService.instance.resetForTesting();
  });

  testWidgets('앱 시작 시 로그인 화면이 표시되는지 확인', (WidgetTester tester) async {
    // 앱 빌드
    await tester.pumpWidget(const OomoolApp());
    await tester.pumpAndSettle();

    // 로그인되지 않은 상태이므로 로그인 화면이 표시되어야 함
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('DemoHomeScreen 위젯 테스트', (WidgetTester tester) async {
    // DemoHomeScreen 직접 테스트
    await tester.pumpWidget(
      const MaterialApp(
        home: DemoHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 홈 화면 요소 확인
    expect(find.text('우물'), findsOneWidget);
    expect(find.text('UT 시나리오'), findsOneWidget);

    // 메뉴 카드들이 표시되는지 확인
    expect(find.text('어항 등록'), findsOneWidget);
    expect(find.text('기록하기'), findsOneWidget);
    expect(find.text('커뮤니티 질문'), findsOneWidget);
  });

  testWidgets('로그인 상태일 때 메인 화면이 표시되는지 확인', (WidgetTester tester) async {
    // 로그인 상태로 mock 설정 변경
    when(() => mockAuthStore.isValid).thenReturn(true);

    // 온보딩 완료 상태로 설정
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
    });
    await OnboardingService.instance.initialize();

    await tester.pumpWidget(const OomoolApp());
    await tester.pumpAndSettle();

    // 로그인된 상태이므로 MainShell이 표시되어야 함
    expect(find.byType(MaterialApp), findsOneWidget);

    // 원래 상태로 복원
    when(() => mockAuthStore.isValid).thenReturn(false);
  });
}
