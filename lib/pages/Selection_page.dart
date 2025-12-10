import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import '../theme/app_colors.dart';

class SelectionPage extends StatefulWidget {
  const SelectionPage({Key? key}) : super(key: key);

  @override
  State<SelectionPage> createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  int? _selectedIndex;

  final List<Map<String, String>> _options = [
    {'from': 'Abled', 'to': 'Sign'},
    {'from': 'Sign', 'to': 'Abled'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0EBF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    return _buildSelectionCard(
                      index: index,
                      from: _options[index]['from']!,
                      to: _options[index]['to']!,
                    );
                  },
                ),
              ),
            ),
            _buildContinueButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'HandSpeaks',
                style: TextStyle(
                  fontFamily: "Urbanist",
                  fontWeight: FontWeight.w700,
                  fontSize: 25,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(width: 2.0),
                  color: AppColors.pureBlack,
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    fontWeight: FontWeight.w700,
                    fontSize: 25,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Select Communication Mode',
            style: TextStyle(
              fontFamily: "Urbanist",
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: AppColors.pureBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required int index,
    required String from,
    required String to,
  }) {
    final isSelected = _selectedIndex == index;
    final Color greenGlossy = Color(0xFF00C853);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: greenGlossy.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - From
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    from,
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppColors.pureBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From',
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.pureBlack.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? greenGlossy : Colors.black12,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: greenGlossy.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                    : null,
              ),
              child: Icon(
                Icons.arrow_forward,
                color: isSelected ? AppColors.pureWhite : AppColors.pureBlack,
                size: 20,
              ),
            ),

            // Right side - To
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    to,
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppColors.pureBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'To',
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.pureBlack.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).asGlass(
        enabled: true,
        tintColor: isSelected
            ? greenGlossy.withOpacity(0.15)
            : Colors.transparent,
        clipBorderRadius: BorderRadius.circular(20.0),
        frosted: true,
        blurX: 100,
        blurY: 50,
      ),
    );
  }

  Widget _buildContinueButton() {
    final bool isEnabled = _selectedIndex != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: isEnabled
            ? () {
          // Handle continue action
          print('Selected: ${_options[_selectedIndex!]}');
          // Navigator.push(context, ...);
        }
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.pureBlack : Colors.black26,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              'Continue',
              style: TextStyle(
                fontFamily: "Urbanist",
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}