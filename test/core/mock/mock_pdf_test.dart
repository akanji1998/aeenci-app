import 'dart:convert';

import 'package:aeenci_app/core/mock/mock_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDF factice : en-tête, table xref à la bonne position, fin', () {
    final text = ascii.decode(mockPdf('Recu de test REC-2026-0001'));
    expect(text, startsWith('%PDF-1.4'));
    expect(text.trimRight(), endsWith('%%EOF'));
    final startxref = int.parse(
      RegExp(r'startxref\n(\d+)').firstMatch(text)!.group(1)!,
    );
    expect(text.substring(startxref), startsWith('xref'));
    // Chaque objet commence bien à la position annoncée.
    final offsets = RegExp(
      r'(\d{10}) 00000 n',
    ).allMatches(text).map((m) => int.parse(m.group(1)!));
    var n = 1;
    for (final offset in offsets) {
      expect(text.substring(offset), startsWith('$n 0 obj'));
      n++;
    }
  });

  test('caractères hors ASCII remplacés', () {
    expect(ascii.decode(mockPdf('Reçu')), contains('(Re?u)'));
  });
}
