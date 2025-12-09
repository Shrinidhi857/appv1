import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handspeaks/components/frostedglass.dart';
import 'package:handspeaks/theme/app_colors.dart';

class IllustrationTab extends StatelessWidget {
  const IllustrationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 180),
            child: Column(
              children: [
                const SizedBox(height: 20),

                FrostedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Sessions',
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "No sessions yet — start your first one!",
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.textSecondary
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ],
    );
  }
}
