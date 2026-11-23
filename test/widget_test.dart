import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fira/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FIRA opens the assistant home screen', (tester) async {
    await tester.pumpWidget(const FiraApp());
    await tester.pumpAndSettle();
    expect(find.text('FIRA AI'), findsOneWidget);
    expect(find.text('Que souhaitez-vous\nconstruire aujourd’hui ?'), findsOneWidget);
  });

  testWidgets('Projects and engine settings are accessible', (tester) async {
    await tester.pumpWidget(const FiraApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projets'));
    await tester.pumpAndSettle();
    expect(find.text('Mes projets'), findsOneWidget);
    expect(find.text('Moteur IA'), findsOneWidget);
    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion au moteur IA'), findsOneWidget);
    expect(find.text('Enregistrer le serveur'), findsOneWidget);
  });
}
