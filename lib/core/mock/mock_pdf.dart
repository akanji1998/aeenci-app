import 'dart:convert';

/// PDF minimal et valide (une page, une ligne de texte) pour les reçus
/// factices. Le texte reste en ASCII : police standard sans accents.
List<int> mockPdf(String text) {
  final safe = text
      .replaceAll(RegExp(r'[^\x20-\x7E]'), '?')
      .replaceAll(RegExp(r'[()\\]'), '');
  final stream = 'BT /F1 18 Tf 72 720 Td ($safe) Tj ET';
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
  ];
  final buffer = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(buffer.length);
    buffer.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xref = buffer.length;
  buffer
    ..write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n')
    ..writeAll(
      offsets.map((o) => '${o.toString().padLeft(10, '0')} 00000 n \n'),
    )
    ..write('trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n')
    ..write('startxref\n$xref\n%%EOF\n');
  return ascii.encode(buffer.toString());
}
