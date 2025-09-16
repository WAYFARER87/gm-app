import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:m_club/features/radio/radio_controller.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RadioView();
  }
}

class _RadioView extends StatefulWidget {
  const _RadioView();

  @override
  State<_RadioView> createState() => _RadioViewState();
}

class _RadioViewState extends State<_RadioView> {
  @override
  void initState() {
    super.initState();
    context.read<RadioController>().init(startService: false);
  }

  Future<void> _ensureServiceAndPlay() async {
    final controller = context.read<RadioController>();

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          status = await Permission.notification.request();
        }
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Для отображения медиа-уведомления необходимо разрешить уведомления.',
                ),
              ),
            );
          }
          return;
        }
      }
    }

    if (!controller.notificationsEnabled) {
      await controller.init(startService: true);
    } else {
      await controller.ensureAudioService();
    }

    await controller.togglePlay();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RadioController>();
    if (controller.streamsUnavailable) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Radio streams are currently unavailable. Please try again later.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => controller
                        .init(startService: controller.notificationsEnabled),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    final track = controller.track;
    final artist =
        track?.artist ?? 'Радио «Русские Эмираты»';
    final title =
        track?.title ?? 'По-русски про Эмираты!';
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ) *
                    0.8;
                return Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: SizedBox(
                                width: size,
                                height: size,
                                child: track != null && track.image.isNotEmpty
                                    ? Image.network(
                                        track.image,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/images/Radio_RE_Logo.webp',
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                            if (controller.quality != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: SizedBox(
                                  child: Material(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (context) {
                                            return SafeArea(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: controller.streams.keys
                                                    .map((quality) => ListTile(
                                                          title: Text(quality),
                                                          trailing: controller
                                                                      .quality ==
                                                                  quality
                                                              ? const Icon(
                                                                  Icons.check)
                                                              : null,
                                                          onTap: () {
                                                            controller
                                                                .setQuality(
                                                                    quality);
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        ))
                                                    .toList(),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        constraints: const BoxConstraints(
                                            minHeight: 44),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        child: Center(
                                          child: Text(
                                            controller.quality!,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (controller.hasError) ...[
                          Chip(
                            label: const Text('ERROR'),
                            labelStyle: const TextStyle(color: Colors.white),
                            backgroundColor: Colors.red,
                          ),
                          TextButton(
                            onPressed: () =>
                                context.read<RadioController>().retry(),
                            child: const Text('Повторить'),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          artist,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                        const SizedBox(height: 12),
                        if (track != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(16),
                                minimumSize: const Size(72, 72),
                                backgroundColor: Colors.grey[200],
                                elevation: 4,
                                shadowColor: Colors.grey,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () => _ensureServiceAndPlay(),
                              child: controller.isConnecting ||
                                      controller.isBuffering
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(
                                      controller.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 36,
                                    ),
                            ),
                            const SizedBox(width: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                minimumSize: const Size(48, 48),
                                backgroundColor: Colors.grey[200],
                                elevation: 0,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: controller.isConnecting ||
                                      controller.isBuffering
                                  ? null
                                  : () =>
                                      context.read<RadioController>().toggleMute(),
                              child: Icon(
                                controller.volume == 0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        Consumer<RadioController>(
                          builder: (context, state, _) {
                            if (state.isBuffering) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Буферизация…'),
                              );
                            }
                            if (state.isPlaying) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Воспроизведение'),
                              );
                            }
                            if (state.isPaused) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Пауза'),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
