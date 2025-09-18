import 'package:flutter/material.dart';

import '../../core/services/events_api_service.dart';
import '../events/events_screen.dart';

class AfishaScreen extends StatelessWidget {
  const AfishaScreen({super.key});

  static final EventsApiService _api =
      EventsApiService(basePath: 'calendar');

  @override
  Widget build(BuildContext context) {
    return EventsScreen(
      apiService: _api,
      storageKeyPrefix: 'afisha',
    );
  }
}
