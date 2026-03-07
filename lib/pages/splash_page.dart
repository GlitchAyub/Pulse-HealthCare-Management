import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.skyBlue.withOpacity(0.75),
              AppTheme.periwinkle.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 24,
                left: 24,
                child: _star(color: Colors.white.withOpacity(0.35), size: 18),
              ),
              Positioned(
                top: 70,
                right: 40,
                child: _star(color: Colors.white.withOpacity(0.3), size: 14),
              ),
              Positioned(
                bottom: 120,
                left: 40,
                child: _bubble(size: 28, opacity: 0.25),
              ),
              Positioned(
                top: 140,
                right: 70,
                child: _bubble(size: 18, opacity: 0.2),
              ),
              Positioned(
                bottom: -40,
                left: -30,
                child: _bubble(size: 140, opacity: 0.16),
              ),
              Positioned(
                top: -30,
                right: -20,
                child: _bubble(size: 110, opacity: 0.18),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'HEALTHCARE',
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'All your healthcare need\non your finger tips',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble({required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _star({required Color color, required double size}) {
    return Icon(Icons.star_rounded, color: color, size: size);
  }
}
