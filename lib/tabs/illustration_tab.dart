import 'dart:async';
import 'package:flutter/material.dart';
import 'package:handspeaks/components/frostedglass.dart';
import 'package:handspeaks/components/glb_hand_mapping_widget.dart';
import 'package:handspeaks/theme/app_colors.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class IllustrationTab extends StatefulWidget {
  const IllustrationTab({super.key});

  @override
  State<IllustrationTab> createState() => _IllustrationTabState();
}

class _IllustrationTabState extends State<IllustrationTab> {
  bool _showModel = false;
  final StreamController<List<vm.Vector3>> _landmarksController =
      StreamController<List<vm.Vector3>>.broadcast();

  @override
  void dispose() {
    _landmarksController.close();
    super.dispose();
  }

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

                // 3D Model Viewer Card
                FrostedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '3D Hand Model',
                            style: TextStyle(
                              fontFamily: "Urbanist",
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          Switch(
                            value: _showModel,
                            onChanged: (value) {
                              setState(() {
                                _showModel = value;
                              });
                            },
                            activeColor: Color(0xFF6FB5A8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_showModel) ...[
                        // 3D Model Container
                        Container(
                          height: 400,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GlbHandMappingWidget(
                              modelAssetPath: 'assets/models/breen.glb',
                              handLandmarksStream: _landmarksController.stream,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Real-time 3D hand visualization from MediaPipe landmarks",
                          style: TextStyle(
                            fontFamily: "Urbanist",
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else ...[
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Color(0xFFF0FFDB).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFF6FB5A8).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.view_in_ar,
                                  size: 64,
                                  color: Color(0xFF6FB5A8).withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Toggle switch to view 3D model',
                                  style: TextStyle(
                                    fontFamily: "Urbanist",
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info Card
                FrostedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF6FB5A8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How it works',
                            style: TextStyle(
                              fontFamily: "Urbanist",
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        '1. Connect',
                        'Connect to Raspberry Pi via Bluetooth in Device tab',
                      ),
                      _buildInfoItem(
                        '2. Receive',
                        'Hand landmarks stream from MediaPipe in real-time',
                      ),
                      _buildInfoItem(
                        '3. Visualize',
                        '3D model animates based on your hand movements',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Status Card
                FrostedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Model Status',
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusRow(
                        'Model',
                        'Breen Hand Model (GLB)',
                        Icons.threed_rotation,
                      ),
                      _buildStatusRow(
                        'Textures',
                        '5 texture maps loaded',
                        Icons.texture,
                      ),
                      _buildStatusRow(
                        'Bones',
                        'Hand skeleton ready',
                        Icons.fingerprint,
                      ),
                      _buildStatusRow(
                        'Status',
                        _showModel ? 'Active' : 'Inactive',
                        _showModel ? Icons.check_circle : Icons.circle_outlined,
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

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Color(0xFF6FB5A8),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF6FB5A8)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: "Urbanist",
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: "Urbanist",
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
