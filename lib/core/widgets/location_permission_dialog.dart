import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({super.key});

  Future<void> _requestPermission(BuildContext context) async {
    final status = await Permission.locationWhenInUse.request();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_permission_granted', status.isGranted);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Доступ к геолокации'),
      content: const Text(
        'Разрешите приложению доступ к местоположению, чтобы видеть предложения рядом.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Позже'),
        ),
        TextButton(
          onPressed: () => _requestPermission(context),
          child: const Text('Разрешить'),
        ),
      ],
    );
  }
}
