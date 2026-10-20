// Génère les images de l'icône et de l'écran de démarrage à partir de
// assets/logos/aeenci-symbole.svg :
//
//   flutter test tool/brand/render_brand_assets_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// C'est un test Flutter pour profiter du moteur de rendu et de flutter_svg.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:aeenci_app/core/design/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _symbol = 'assets/logos/aeenci-symbole.svg';
const _out = 'assets/branding';

void main() {
  testWidgets('images de marque', (tester) async {
    tester.view
      ..physicalSize = const Size(1200, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> render(
      String name, {
      required double canvas,
      required double symbol,
      Color background = Colors.transparent,
      Color? disc,
    }) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox.square(
                dimension: canvas,
                child: ColoredBox(
                  color: background,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: disc,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(disc == null ? 0 : symbol / 5),
                        child: SvgPicture.asset(
                          _symbol,
                          width: symbol,
                          height: symbol,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Chargement et décodage asynchrones du SVG.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!);
    }

    // Icône complète (iOS, ancien Android) : symbole sur fond blanc.
    await render(
      'icon',
      canvas: 1024,
      symbol: 760,
      background: AppColors.light.surfaceRaised,
    );
    // Avant-plan de l'icône adaptative Android : flutter_launcher_icons
    // ajoute déjà une marge de 16 %, qui place le symbole dans la zone sûre.
    await render('icon_foreground', canvas: 1024, symbol: 900);
    // Écran de démarrage (et Android 12, dans un cercle de 2/3).
    await render('splash', canvas: 1152, symbol: 640);
    // Thème sombre : le personnage (couleur ink) serait invisible sur fond
    // sombre, d'où un disque blanc.
    await render(
      'splash_dark',
      canvas: 1152,
      symbol: 520,
      disc: AppColors.light.surfaceRaised,
    );
  });
}
