import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo/main.dart';

void main() {
  testWidgets('Tela de busca exibe a fonte e valida campo vazio',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PrevisaoApp());
    await tester.pump();

    expect(find.text('Fonte dos dados: CPTEC/INPE'), findsOneWidget);

    await tester.tap(find.text('Buscar'));
    await tester.pump();

    expect(find.text('Informe o nome da cidade.'), findsOneWidget);
  });
}