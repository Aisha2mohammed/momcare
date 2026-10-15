import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// YouTube & Media URL Helper Functions
// ─────────────────────────────────────────────────────────────────────────────

String? extractYoutubeId(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final trimmed = url.trim();

  // 1. Standard YoutubePlayer convert helper
  final converted = YoutubePlayer.convertUrlToId(trimmed);
  if (converted != null && converted.isNotEmpty) return converted;

  // 2. Check if the string itself is an 11-char YouTube ID (e.g. uC79hPffH4o)
  final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
  if (idRegex.hasMatch(trimmed)) return trimmed;

  // 3. Fallback regex for full YouTube URLs, shorts, embed, watch
  final regExp = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?|shorts)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(trimmed);
  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }

  return null;
}

String resolveVideoUrl(String? url) {
  final fallbackUrl = '${ApiEndpoints.serverHost}/uploads/file-1789254638769-685033131.mp4';
  if (url == null || url.trim().isEmpty) {
    return fallbackUrl;
  }
  final trimmed = url.trim();

  // Preserve YouTube URLs and bare YouTube IDs
  if (extractYoutubeId(trimmed) != null) {
    return trimmed;
  }

  String resolved = trimmed;

  // Relative path resolution
  if (!resolved.startsWith('http://') && !resolved.startsWith('https://')) {
    final host = ApiEndpoints.serverHost;
    if (resolved.startsWith('/uploads/')) {
      return '$host$resolved';
    } else if (resolved.startsWith('uploads/')) {
      return '$host/$resolved';
    } else if (resolved.endsWith('.mp4') || resolved.endsWith('.mov') || resolved.endsWith('.avi')) {
      return '$host/uploads/$resolved';
    }
    return resolved.startsWith('/') ? '$host$resolved' : '$host/$resolved';
  }

  // Normalize legacy/localhost/outdated IP addresses to the current serverHost
  resolved = resolved
      .replaceAll('localhost', '192.168.10.163')
      .replaceAll('127.0.0.1', '192.168.10.163')
      .replaceAll('10.0.2.2', '192.168.10.163')
      .replaceAll('192.168.1.4:5000', '192.168.10.163:5000')
      .replaceAll('192.168.0.199:5000', '192.168.10.163:5000');

  // Replace any stale 192.168.x.x:5000 IP with current ApiEndpoints.serverHost
  resolved = resolved.replaceFirst(
    RegExp(r'http:\/\/192\.168\.\d+\.\d+:5000'),
    ApiEndpoints.serverHost,
  );

  return resolved;
}

// ─────────────────────────────────────────────────────────────────────────────
// App In-UI Video Player Widget
// Supports Playback Controls, Display Controls, Scrubber Navigation, and Fullscreen.
// Strictly stays in-app — never opens external applications.
// ─────────────────────────────────────────────────────────────────────────────

class AppVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? thumbnailUrl;
  final bool autoPlay;
  final double aspectRatio;

  const AppVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  // YouTube player controller
  YoutubePlayerController? _ytController;
  bool _isYoutube = false;

  // Direct MP4 video player controller
  VideoPlayerController? _vpController;

  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isMuted = false;
  BoxFit _fitMode = BoxFit.contain;
  double _currentSpeed = 1.0;
  Timer? _hideTimer;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initPlayer(widget.videoUrl);
  }

  @override
  void didUpdateWidget(covariant AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initPlayer(widget.videoUrl);
    }
  }

  Future<void> _disposeControllers() async {
    _hideTimer?.cancel();
    final vp = _vpController;
    _vpController = null;
    if (vp != null) {
      vp.removeListener(_videoListener);
      try {
        await vp.pause();
        await vp.dispose();
      } catch (_) {}
    }

    final yt = _ytController;
    _ytController = null;
    if (yt != null) {
      try {
        yt.dispose();
      } catch (_) {}
    }
  }

  Future<void> _initPlayer(String rawUrl) async {
    await _disposeControllers();

    if (!mounted) return;
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
      _showControls = true;
      _currentSpeed = 1.0;
    });

    final targetUrl = resolveVideoUrl(rawUrl);
    final ytId = extractYoutubeId(targetUrl);

    // ── 1. YouTube Video ────────────────────────────────────────────────────
    if (ytId != null && ytId.isNotEmpty) {
      _isYoutube = true;
      try {
        final controller = YoutubePlayerController(
          initialVideoId: ytId,
          flags: YoutubePlayerFlags(
            autoPlay: widget.autoPlay,
            mute: _isMuted,
            enableCaption: false,
            isLive: false,
            forceHD: false,
            showLiveFullscreenButton: true,
            useHybridComposition: true,
          ),
        );
        _ytController = controller;
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
        _startHideTimer();
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
        return;
      }
    }

    // ── 2. Direct MP4 / Backend Uploaded Video ──────────────────────────────
    _isYoutube = false;

    try {
      final uri = Uri.parse(targetUrl);
      final controller = VideoPlayerController.networkUrl(uri);
      _vpController = controller;

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      if (_isMuted) {
        await controller.setVolume(0.0);
      }

      if (widget.autoPlay) {
        await controller.play();
      }

      controller.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
      });
      _startHideTimer();
    } catch (e) {
      // Fallback attempt with known default backend video strictly in-app
      try {
        final fallbackUrl = '${ApiEndpoints.serverHost}/uploads/file-1789254638769-685033131.mp4';
        if (targetUrl != fallbackUrl) {
          final fallbackController = VideoPlayerController.networkUrl(Uri.parse(fallbackUrl));
          _vpController = fallbackController;
          await fallbackController.initialize();
          if (!mounted) {
            await fallbackController.dispose();
            return;
          }
          if (_isMuted) {
            await fallbackController.setVolume(0.0);
          }
          if (widget.autoPlay) {
            await fallbackController.play();
          }
          fallbackController.addListener(_videoListener);
          setState(() {
            _isInitialized = true;
          });
          _startHideTimer();
          return;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e is PlatformException
            ? 'Playback error: ${e.message ?? e.code}'
            : e.toString();
      });
    }
  }

  void _videoListener() {
    if (!mounted) return;
    // If video reached the end, ensure controls stay visible
    final c = _vpController;
    if (c != null && c.value.isInitialized) {
      if (c.value.position >= c.value.duration && !_showControls) {
        setState(() => _showControls = true);
      } else {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _vpController?.removeListener(_videoListener);
    _vpController?.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    final isPlaying = _vpController?.value.isPlaying == true;
    if (_showControls && isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && (_vpController?.value.isPlaying == true)) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  // ── Playback Controls: Play / Pause / Replay ──────────────────────────────
  void _togglePlayPause() {
    final c = _vpController;
    if (c == null || !_isInitialized) return;
    if (c.value.position >= c.value.duration) {
      c.seekTo(Duration.zero);
      c.play();
    } else if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    _startHideTimer();
  }

  // ── Playback Controls: Jump 10 seconds ─────────────────────────────────────
  void _seekRelative(int seconds) {
    final c = _vpController;
    if (c != null && _isInitialized) {
      final current = c.value.position;
      final target = current + Duration(seconds: seconds);
      final clamped = target < Duration.zero
          ? Duration.zero
          : (target > c.value.duration ? c.value.duration : target);
      c.seekTo(clamped);
      _startHideTimer();
    }
  }

  // ── Playback Controls: Speed Selector ─────────────────────────────────────
  void _setSpeed(double speed) {
    setState(() => _currentSpeed = speed);
    _vpController?.setPlaybackSpeed(speed);
    _startHideTimer();
  }

  // ── Display Controls: Volume / Mute ───────────────────────────────────────
  void _toggleMute() {
    final c = _vpController;
    setState(() {
      _isMuted = !_isMuted;
      c?.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _startHideTimer();
  }

  // ── Display Controls: Fit Mode (Contain vs Cover) ─────────────────────────
  void _toggleFitMode() {
    setState(() {
      _fitMode = _fitMode == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    });
    _startHideTimer();
  }

  // ── Display Controls: In-App Fullscreen View ──────────────────────────────
  void _openFullScreen() {
    final c = _vpController;
    if (c == null || !c.value.isInitialized) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _FullScreenVideoPage(
          controller: c,
          title: widget.title,
          isMuted: _isMuted,
          onToggleMute: _toggleMute,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_hasError)
                _buildErrorView()
              else if (!_isInitialized)
                _buildLoadingView()
              else if (_isYoutube && _ytController != null)
                _buildYoutubePlayer()
              else if (_vpController != null && _vpController!.value.isInitialized)
                _buildNativeVideoPlayer()
              else
                _buildErrorView(),
            ],
          ),
        ),
      ),
    );
  }

  // ── YouTube Player Widget ─────────────────────────────────────────────────
  Widget _buildYoutubePlayer() {
    return YoutubePlayer(
      controller: _ytController!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: AppColors.primary,
      progressColors: const ProgressBarColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primary,
        bufferedColor: Colors.white24,
        backgroundColor: Colors.white12,
      ),
      topActions: [
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // ── Native MP4 Video Player Widget ────────────────────────────────────────
  Widget _buildNativeVideoPlayer() {
    final c = _vpController!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Canvas with selected Display Fit Mode
          _fitMode == BoxFit.cover
              ? FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: c.value.size.width > 0 ? c.value.size.width : 16,
                    height: c.value.size.height > 0 ? c.value.size.height : 9,
                    child: VideoPlayer(c),
                  ),
                )
              : Center(
                  child: AspectRatio(
                    aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : widget.aspectRatio,
                    child: VideoPlayer(c),
                  ),
                ),

          // Buffering Indicator
          if (c.value.isBuffering)
            const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            ),

          // Rich Controls Overlay
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  // ── Loading View ──────────────────────────────────────────────────────────
  Widget _buildLoadingView() {
    final hasThumb = widget.thumbnailUrl != null &&
        widget.thumbnailUrl!.isNotEmpty &&
        !widget.thumbnailUrl!.endsWith('.mp4');

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasThumb)
          Image.network(
            widget.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1F1F1F)),
          )
        else
          Container(color: const Color(0xFF1F1F1F)),
        Container(color: Colors.black.withValues(alpha: 0.45)),
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
              SizedBox(height: 10),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── In-Page Error / Fallback View (Never opens external apps) ───────────────
  Widget _buildErrorView() {
    final fallbackUrl = '${ApiEndpoints.serverHost}/uploads/file-1789254638769-685033131.mp4';

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_library_rounded, color: AppColors.primary, size: 36),
              const SizedBox(height: 6),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage.isNotEmpty && !_errorMessage.contains('channel-error')
                    ? _errorMessage
                    : 'Video could not be streamed directly.',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _initPlayer(widget.videoUrl),
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Retry In-Page Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _initPlayer(fallbackUrl),
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 14),
                    label: const Text('Play Sample In App'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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

  // ── Comprehensive In-UI Video Controls Overlay ────────────────────────────
  Widget _buildControlsOverlay() {
    final c = _vpController!;
    final position = c.value.position;
    final duration = c.value.duration;
    final isPlaying = c.value.isPlaying;
    final isFinished = position >= duration && duration > Duration.zero;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── 1. Top Controls Bar (Title + Video Display Controls) ───────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),

                // Speed Selector Pill
                PopupMenuButton<double>(
                  tooltip: 'Playback Speed',
                  onSelected: _setSpeed,
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_currentSpeed}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  itemBuilder: (ctx) => _speeds
                      .map(
                        (speed) => PopupMenuItem<double>(
                          value: speed,
                          height: 36,
                          child: Row(
                            children: [
                              if (_currentSpeed == speed)
                                const Icon(Icons.check_rounded, color: AppColors.primary, size: 16)
                              else
                                const SizedBox(width: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${speed}x',
                                style: TextStyle(
                                  color: _currentSpeed == speed ? AppColors.primary : Colors.white,
                                  fontWeight: _currentSpeed == speed ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),

                // Fit Mode Toggle (Contain vs Cover)
                IconButton(
                  icon: Icon(
                    _fitMode == BoxFit.contain ? Icons.fit_screen_rounded : Icons.crop_free_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  tooltip: _fitMode == BoxFit.contain ? 'Fit Frame' : 'Fill Screen',
                  visualDensity: VisualDensity.compact,
                  onPressed: _toggleFitMode,
                ),

                // Volume / Mute Toggle
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  tooltip: _isMuted ? 'Unmute' : 'Mute',
                  visualDensity: VisualDensity.compact,
                  onPressed: _toggleMute,
                ),

                // In-App Fullscreen Toggle
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                  tooltip: 'Fullscreen',
                  visualDensity: VisualDensity.compact,
                  onPressed: _openFullScreen,
                ),
              ],
            ),
          ),

          // ── 2. Center Playback Controls (10s Rewind, Play/Pause/Replay, 10s Forward) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind -10s
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 30),
                tooltip: 'Rewind 10 seconds',
                onPressed: () => _seekRelative(-10),
              ),
              const SizedBox(width: 16),

              // Main Play / Pause / Replay Button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    isFinished
                        ? Icons.replay_rounded
                        : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Fast Forward +10s
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 30),
                tooltip: 'Forward 10 seconds',
                onPressed: () => _seekRelative(10),
              ),
            ],
          ),

          // ── 3. Bottom Progress and Navigation Bar ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Interactive Scrubber Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                    thumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white24,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: duration.inMilliseconds > 0
                        ? position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble()
                        : 0.0,
                    min: 0.0,
                    max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (val) {
                      c.seekTo(Duration(milliseconds: val.toInt()));
                      _startHideTimer();
                    },
                  ),
                ),

                // Timestamps & Status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dedicated In-App Fullscreen View Page
// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  final bool isMuted;
  final VoidCallback onToggleMute;

  const _FullScreenVideoPage({
    required this.controller,
    required this.title,
    required this.isMuted,
    required this.onToggleMute,
  });

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  bool _showControls = true;
  Timer? _hideTimer;
  BoxFit _fit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    widget.controller.addListener(_onUpdate);
    _startTimer();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onUpdate);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _startTimer() {
    _hideTimer?.cancel();
    if (_showControls && widget.controller.value.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && widget.controller.value.isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final position = c.value.position;
    final duration = c.value.duration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _showControls = !_showControls);
            if (_showControls) _startTimer();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fullscreen Video Surface
              _fit == BoxFit.cover
                  ? FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: c.value.size.width > 0 ? c.value.size.width : 16,
                        height: c.value.size.height > 0 ? c.value.size.height : 9,
                        child: VideoPlayer(c),
                      ),
                    )
                  : Center(
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
                        child: VideoPlayer(c),
                      ),
                    ),

              // Fullscreen Controls Overlay
              if (_showControls)
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _fit == BoxFit.contain ? Icons.fit_screen_rounded : Icons.crop_free_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(() => _fit = _fit == BoxFit.contain ? BoxFit.cover : BoxFit.contain),
                            ),
                            IconButton(
                              icon: Icon(
                                widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                color: Colors.white,
                              ),
                              onPressed: widget.onToggleMute,
                            ),
                            IconButton(
                              icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 26),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // Center Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 36),
                            onPressed: () {
                              final target = c.value.position - const Duration(seconds: 10);
                              c.seekTo(target < Duration.zero ? Duration.zero : target);
                              _startTimer();
                            },
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () {
                              if (c.value.isPlaying) {
                                c.pause();
                              } else {
                                c.play();
                              }
                              _startTimer();
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                c.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 36),
                            onPressed: () {
                              final target = c.value.position + const Duration(seconds: 10);
                              c.seekTo(target > c.value.duration ? c.value.duration : target);
                              _startTimer();
                            },
                          ),
                        ],
                      ),

                      // Bottom Progress Slider & Timestamps
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                trackHeight: 3,
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: Colors.white30,
                                thumbColor: AppColors.primary,
                              ),
                              child: Slider(
                                value: duration.inMilliseconds > 0
                                    ? position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble()
                                    : 0.0,
                                min: 0.0,
                                max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                                onChanged: (val) {
                                  c.seekTo(Duration(milliseconds: val.toInt()));
                                  _startTimer();
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_format(position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                Text(_format(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
