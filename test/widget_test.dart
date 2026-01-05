// 우물(Oomool) 앱 위젯 테스트

import 'package:flutter_test/flutter_test.dart';

import 'package:oomool/main.dart';

void main() {
  testWidgets('앱 시작 및 홈 화면 표시 테스트', (WidgetTester tester) async {
    // 앱 빌드
    await tester.pumpWidget(const OomoolApp());

    // 홈 화면이 표시되는지 확인
    expect(find.text('우물'), findsOneWidget);
    expect(find.text('UT 시나리오'), findsOneWidget);

    // 메뉴 카드들이 표시되는지 확인
    expect(find.text('어항 등록'), findsOneWidget);
    expect(find.text('기록하기'), findsOneWidget);
    expect(find.text('커뮤니티 질문'), findsOneWidget);
  });

  testWidgets('어항 등록 화면 네비게이션 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const OomoolApp());

    // 어항 등록 카드 탭
    await tester.tap(find.text('어항 등록'));
    await tester.pumpAndSettle();

    // 어항 등록 화면이 표시되는지 확인
    expect(find.text('어항 이름'), findsOneWidget);
    expect(find.text('어항 크기'), findsOneWidget);
    expect(find.text('등록 완료'), findsOneWidget);
  });
}
