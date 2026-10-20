import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Photo ronde du membre : adresse web (mise en cache), fichier local
/// (photo qui vient d'être choisie) ou initiales.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    this.size = 64,
    this.semanticLabel,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final placeholder = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: c.greenSoft,
      child: Text(
        initials,
        style: AppTypography.h3
            .toTextStyle(color: c.green)
            .copyWith(fontSize: size * 0.32),
      ),
    );
    final url = photoUrl;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final Widget image;
    if (url == null) {
      image = placeholder;
    } else if (url.startsWith('file://')) {
      image = Image.file(
        File.fromUri(Uri.parse(url)),
        width: size,
        height: size,
        cacheWidth: pixels,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        memCacheWidth: pixels,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    }
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: ClipOval(child: image),
    );
  }
}
