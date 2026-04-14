import 'package:flutter/material.dart';
import 'package:frontend/config/app_background_config.dart';

/// Latar belakang full-screen: gambar + lapisan semi-transparan + konten di atasnya.
///
/// Bungkus isi halaman (mis. `Scaffold.body`) dengan widget ini, dan set
/// `Scaffold(backgroundColor: Colors.transparent)` agar gambar terlihat penuh.
class SemiTransparentImageBackground extends StatelessWidget {
  const SemiTransparentImageBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: AppBackgroundConfig.imageOpacity.clamp(1.0, 2.0),
            child: Image.asset(
              AppBackgroundConfig.assetPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(color: AppBackgroundConfig.fallbackColor);
              },
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: AppBackgroundConfig.scrimColor.withValues(
              alpha: AppBackgroundConfig.scrimOpacity.clamp(0.0, 1.0),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
