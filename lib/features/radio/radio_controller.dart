import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:m_club/core/services/radio_api_service.dart';
import 'package:m_club/features/radio/models/radio_track.dart';
import 'package:m_club/features/radio/radio_audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller responsible for playing radio streams and
/// providing information about current track and player state.
class RadioController extends ChangeNotifier {
  RadioController._internal() {
    _player.playerStateStream.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.idle && _player.audioSource != null) {
        _hasError = true;
        await _audioHandlerReady;
        await _audioHandler!.stop();
      }
      notifyListeners();
    });

    // Listen to ICY metadata updates to refresh track information as soon
    // as the streaming server reports new data. This supplements the
    // periodic timer-based refresh below.
    _player.icyMetadataStream.listen((_) {
      _updateTrackInfo();
    });
  }

  static final RadioController _instance = RadioController._internal();

  factory RadioController() => _instance;

  final RadioApiService _api = RadioApiService();
  static final AudioPlayer _player = AudioPlayer();
  static RadioAudioHandler? _audioHandler;
  static bool _isServiceHandler = false;
  Completer<void>? _audioHandlerCompleter;

  Future<void> get _audioHandlerReady =>
      (_audioHandlerCompleter ??= Completer<void>()).future;

  Map<String, String> _streams = {};
  String? _quality;
  PlayerState _playerState = PlayerState(false, ProcessingState.idle);
  RadioTrack? _track;
  Timer? _trackTimer;
  bool _hasError = false;
  bool _streamsUnavailable = false;
  double _volume = 1.0;
  double _previousVolume = 1.0;
  String? _errorMessage;
  bool _notificationsEnabled = true;

  static const String _cachedStreamsKey = 'radio_streams';

  Map<String, String> get streams => _streams;
  String? get quality => _quality;
  PlayerState get playerState => _playerState;
  RadioTrack? get track => _track;
  bool get hasError => _hasError;
  bool get streamsUnavailable => _streamsUnavailable;
  double get volume => _volume;
  String? get errorMessage => _errorMessage;
  bool get notificationsEnabled => _notificationsEnabled;

  bool get isConnecting =>
      _playerState.processingState == ProcessingState.loading;
  bool get isBuffering =>
      _playerState.processingState == ProcessingState.buffering;
  bool get isPlaying =>
      _playerState.playing &&
      _playerState.processingState == ProcessingState.ready;
  bool get isPaused =>
      !_playerState.playing &&
      _playerState.processingState == ProcessingState.ready;

  /// Starts playback if the stream is not playing and stops otherwise.
  Future<void> togglePlay() async {
    await _audioHandlerReady;
    if (_player.playing) {
      await _audioHandler!.stop();
      _trackTimer?.cancel();
    } else {
      if (_player.audioSource == null && _streams.isNotEmpty) {
        await _startStream();
      } else {
        await _audioHandler!.play();
      }
    }
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Completely stops playback and releases audio resources.
  Future<void> stop() async {
    await _audioHandlerReady;
    _trackTimer?.cancel();
    await _audioHandler!.stop();
    notifyListeners();
  }

  /// Sets the player volume to a value between 0.0 and 1.0.
  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    if (_volume > 0) {
      _previousVolume = _volume;
    }
    await _player.setVolume(_volume);
    notifyListeners();
  }

  /// Toggles mute state preserving the last non-zero volume value.
  Future<void> toggleMute() async {
    if (_volume > 0) {
      _previousVolume = _volume;
      _volume = 0;
    } else {
      _volume = _previousVolume;
    }
    await _player.setVolume(_volume);
    notifyListeners();
  }

  /// Retries playback of the current stream.
  Future<void> retry() async {
    _hasError = false;
    _errorMessage = null;
    if (_streams.isEmpty) {
      await init(quality: _quality);
    } else {
      await _startStream();
    }
    notifyListeners();
  }

  /// Loads available streams and starts playback using selected [quality].
  ///
  /// If [startService] is `true`, the background audio service will be
  /// initialized, enabling notification-based controls. When `false`, the
  /// controller will operate without posting notifications.
  Future<void> init({String? quality, bool startService = true}) async {
    _notificationsEnabled = startService;
    debugPrint('RadioController.init: notificationsEnabled=$_notificationsEnabled');
    if (startService) {
      await ensureAudioService();
      if (_hasError) {
        notifyListeners();
        return;
      }
    } else {
      _isServiceHandler = false;
      _audioHandler = RadioAudioHandler(_player);
      _resetAudioHandlerCompleter();
      _completeAudioHandlerCompleter();
    }

    _streamsUnavailable = false;
    try {
      _streams = await _api.fetchStreams();
      if (_streams.isNotEmpty) {
        await _saveStreamsToCache(_streams);
      } else {
        _streams = await _loadStreamsFromCache();
        if (_streams.isEmpty) {
          _streamsUnavailable = true;
          notifyListeners();
          return;
        }
      }
    } catch (e, s) {
      _streams = await _loadStreamsFromCache();
      if (_streams.isEmpty) {
        _streamsUnavailable = true;
        notifyListeners();
        debugPrint('Failed to fetch radio streams: $e\n$s');
        return;
      }
    }

    _quality = quality ?? _streams.keys.first;
    // Do not automatically start playback to prevent unwanted audio on
    // application launch. The stream will start when the user presses play.
    _trackTimer?.cancel();
    _track = null;
    notifyListeners();
  }

  /// Changes stream quality and restarts playback with a new URL.
  Future<void> setQuality(String quality) async {
    if (!_streams.containsKey(quality) || _quality == quality) return;
    _quality = quality;
    await _startStream();
    notifyListeners();
  }

  Future<void> _startStream() async {
    await _audioHandlerReady;
    final url = _streams[_quality];
    if (url == null) return;
    _hasError = false;
    _errorMessage = null;
    try {
      await _audioHandler!.stop();
      await _player.setUrl(url);
      await _audioHandler!.updateTrack(
        RadioTrack(
          artist: '',
          title: 'Радио «Русские Эмираты»',
          image: '',
        ),
      );
      try {
        await AudioSession.instance.then(
          (session) => session.setActive(true),
        );
      } catch (e, s) {
        _logPlaybackFailure('activateSession', e, s);
      }
      await _audioHandler!.play();
      _startTrackInfoTimer();
      await _updateTrackInfo();
      notifyListeners();
    } catch (e, s) {
      _hasError = true;
      _errorMessage = 'Failed to start radio playback: ${e.toString()}';
      _logPlaybackFailure('startStream', e, s);
      notifyListeners();
    }
  }

  Future<void> _saveStreamsToCache(Map<String, String> streams) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedStreamsKey, jsonEncode(streams));
    } catch (_) {
      // ignore cache errors
    }
  }

  Future<Map<String, String>> _loadStreamsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_cachedStreamsKey);
      if (data == null) return {};
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      return {};
    }
  }

  void _startTrackInfoTimer() {
    _trackTimer?.cancel();
    _trackTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateTrackInfo();
    });
  }

  Future<void> _updateTrackInfo() async {
    await _audioHandlerReady;
    try {
      final info = await _api.fetchTrackInfo();
      if (info == null) {
        _track = null;
        await _audioHandler!.updateTrack(
          RadioTrack(
            artist: '',
            title: 'Радио «Русские Эмираты»',
            image: '',
          ),
        );
        notifyListeners();
        return;
      }
      _track = info;
      await _audioHandler!.updateTrack(info);
      notifyListeners();
    } catch (_) {
      _track = null;
      await _audioHandler!.updateTrack(
        RadioTrack(
          artist: '',
          title: 'Радио «Русские Эмираты»',
          image: '',
        ),
      );
      // ignore errors
    }
  }

  @override
  void dispose() {
    _trackTimer?.cancel();
    // Stop the background service only when nothing is playing to
    // release resources while still allowing ongoing playback to
    // continue when the UI is closed.
    if (!_player.playing) {
      _audioHandler?.stop();
    }
    super.dispose();
  }

  /// Ensures that [AudioService] is initialized and ready for use.
  ///
  /// Safe to call multiple times; subsequent calls have no effect.
  /// This is useful when the app process restarts and needs to
  /// reconnect to a running background audio service.
  Future<void> ensureAudioService() async {
    _resetAudioHandlerCompleter();
    if (_audioHandler != null && _isServiceHandler) {
      _completeAudioHandlerCompleter();
      return;
    }

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);

      final handler = await AudioService.init(
        builder: () => RadioAudioHandler(_player),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'm_club_radio_channel',
          androidNotificationChannelName: 'GorodMore.ru Radio',
          androidNotificationIcon: 'drawable/radio_notification_icon',
          androidNotificationOngoing: true,
        ),
      );

      if (handler is RadioAudioHandler) {
        _audioHandler = handler;
        _isServiceHandler = true;
      } else {
        throw StateError(
          'Unexpected audio handler type: ${handler.runtimeType}',
        );
      }

      await _audioHandler!.updateTrack(
        RadioTrack(
          artist: '',
          title: 'Радио «Русские Эмираты»',
          image: '',
        ),
      );
    } catch (e, s) {
      _hasError = true;
      _errorMessage = 'Audio service error: ${e.toString()}';
      _logPlaybackFailure('ensureAudioService', e, s);
      _audioHandler = RadioAudioHandler(_player);
      _isServiceHandler = false;
    } finally {
      _completeAudioHandlerCompleter();
    }
  }

  void _resetAudioHandlerCompleter() {
    if (_audioHandlerCompleter == null || _audioHandlerCompleter!.isCompleted) {
      _audioHandlerCompleter = Completer<void>();
    }
  }

  void _completeAudioHandlerCompleter() {
    final completer = _audioHandlerCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _logPlaybackFailure(String context, Object error, StackTrace stack) {
    debugPrint('Playback failure in $context: $error\n$stack');
    // TODO: integrate analytics reporting here.
  }
}

