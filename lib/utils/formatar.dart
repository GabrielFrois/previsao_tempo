/// Formata uma data como DD/MM/AAAA.
String formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final ano = data.year.toString().padLeft(4, '0');
  return '$dia/$mes/$ano';
}

const List<String> _diasDaSemana = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

/// Nome do dia da semana em português (DateTime.weekday: 1 = segunda).
String diaDaSemana(DateTime data) => _diasDaSemana[data.weekday - 1];

/// Temperatura em graus Celsius ou "--" quando ausente.
String formatarTemperatura(double? valor) {
  if (valor == null) return '--';
  return '${valor.round()} °C';
}

/// Índice ultravioleta ou "não disponível" quando ausente.
String formatarIuv(double? valor) {
  if (valor == null) return 'não disponível';
  return valor == valor.roundToDouble()
      ? valor.toInt().toString()
      : valor.toStringAsFixed(1);
}