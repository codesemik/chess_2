// Basit bir "smoke test": uygulama hatasız açılıyor mu ve alt navigasyon
// barındaki 4 sekme (Mağaza / Oyun / Kartlarım / Klan) görünüyor mu?

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chess_2/main.dart';

void main() {
  testWidgets('Chess 2 app opens with 4 bottom navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const Chess2App());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });
}
