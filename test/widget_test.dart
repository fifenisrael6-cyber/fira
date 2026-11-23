import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fira/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FIRA opens as a single conversational assistant', (tester) async {
    await tester.pumpWidget(const FiraApp());
    await tester.pumpAndSettle();
    expect(find.text('FIRA AI'), findsOneWidget);
    expect(find.text('Que souhaitez-vous\nconstruire aujourd’hui ?'), findsOneWidget);
    expect(find.text('Écrivez à FIRA…'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Engine settings are accessible from the chat header', (tester) async {
    await tester.pumpWidget(const FiraApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Réglages'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion au moteur IA'), findsOneWidget);
    expect(find.text('Enregistrer le serveur'), findsOneWidget);
  });
}
