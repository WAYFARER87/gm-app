import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ClubCard extends StatelessWidget {
  final String cardNum;
  final String expireDate;
  final String? firstName;
  final String? lastName;

  const ClubCard({
    super.key,
    required this.cardNum,
    required this.expireDate,
    this.firstName,
    this.lastName,
  });

  String _formatExpiry(String date) {
    try {
      final parsed = DateTime.parse(date);
      final month = parsed.month.toString().padLeft(2, '0');
      final year = (parsed.year % 100).toString().padLeft(2, '0');
      return '$month/$year';
    } catch (_) {
      final parts = date.split('/');
      if (parts.length >= 2) {
        final month = parts[0].padLeft(2, '0');
        var year = parts[1];
        if (year.length == 4) {
          year = year.substring(2);
        }
        return '$month/$year';
      }
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatExpiry(expireDate);
    final fullName = [
      firstName?.trim(),
      lastName?.trim(),
    ].where((e) => e != null && e!.isNotEmpty).join(' ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 0.95;
        return Center(
          child: SizedBox(
            width: width,
            child: AspectRatio(
              aspectRatio: 8 / 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF182857), Color(0xFF4A5699)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/images/mclub_logo.svg',
                      height: 40,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    const Spacer(),
                    if (fullName.isNotEmpty) ...[
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      cardNum,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'VALID THRU $formattedDate',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: cardNum,
                          width: double.infinity,
                          height: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
