import 'package:freezed_annotation/freezed_annotation.dart';

part 'news.freezed.dart';
part 'news.g.dart';

/// `GET /news`, `GET /news/{slug}`. `body` est du Markdown.
@freezed
abstract class News with _$News {
  const factory News({
    required int id,
    required String slug,
    required String title,
    required String excerpt,
    required String body,
    String? imageUrl,
    required DateTime publishedAt,
  }) = _News;

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);
}
