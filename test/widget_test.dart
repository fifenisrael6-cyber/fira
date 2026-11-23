import 'package:flutter_test/flutter_test.dart';
import 'package:fira/main.dart';

void main() {
  testWidgets('FIRA opens the assistant home screen', (tester) async {
    await tester.pumpWidget(const FiraApp());
    expect(find.text('FIRA AI'), findsOneWidget);
    expect(find.text('Que souhaitez-vous\nconstruire aujourd’hui ?'), findsOneWidget);
  });

  testWidgets('Projects tab is accessible', (tester) async {
    await tester.pumpWidget(const FiraApp());
    await tester.tap(find.text('Projets'));
    await tester.pumpAndSettle();
    expect(find.text('Mes projets'), findsOneWidget);
    expect(find.text('Moteur IA'), findsOneWidget);
  });
}
