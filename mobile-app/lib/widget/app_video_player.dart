import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pregnancy_appp/constants/color.dart';

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

  // 3. Fallback regex for full YouTube URLs
  final regExp = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(trimmed);
  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }

  return null;
}

String resolveVideoUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return 'http://192.168.1.4:5000/uploads/file-1789254638769-685033131.mp4';
  }
  final trimmed = url.trim();
  // Preserve YouTube URLs and bare YouTube IDs
  if (extractYoutubeId(trimmed) != null) {
    return trimmed;
  }
  String resolved = trimmed;
  if (resolved.contains('localhost')) {
    resolved = resolved.replaceAll('localhost', '192.168.1.4');
  }
  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return resolved;
  }
  const host = 'http://192.168.1.4:5000';
  return resolved.startsWith('/') ? '$host$resolved' : '$host/$resolved';
}

// ─────────────────────────────────────────────────────────────────────────────
// App In-UI Video Player Widget
// Supports both YouTube streaming & direct MP4 backend uploads in mobile UI
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
    final vp = _vpController;
    _vpController = null;
    if (vp != null) {
      vp.removeListener(_videoListener);
      await vp.pause();
      await vp.dispose();
    }

    final yt = _ytController;
    _ytController = null;
    if (yt != null) {
      yt.dispose();
    }
  }

  Future<void> _initPlayer(String rawUrl) async {
    await _disposeControllers();

    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
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
            mute: false,
            enableCaption: true,
            isLive: false,
            forceHD: false,
            showLiveFullscreenButton: false,
          ),
        );
        _ytController = controller;
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
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

      if (widget.autoPlay) {
        await controller.play();
      }

      controller.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // Fallback attempt with default backend video if relative path
      try {
        const fallbackUrl = 'http://192.168.1.4:5000/uploads/file-1789254638769-685033131.mp4';
        if (targetUrl != fallbackUrl) {
          final fallbackController = VideoPlayerController.networkUrl(Uri.parse(fallbackUrl));
          _vpController = fallbackController;
          await fallbackController.initialize();
          if (!mounted) {
            await fallbackController.dispose();
            return;
          }
          fallbackController.addListener(_videoListener);
          setState(() {
            _isInitialized = true;
          });
          return;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e is PlatformException
            ? 'Channel error: ${e.message ?? e.code}'
            : e.toString();
      });
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vpController?.removeListener(_videoListener);
    _vpController?.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final c = _vpController;
    if (c == null || !_isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  void _toggleMute() {
    final c = _vpController;
    if (c == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      c.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _launchExternal(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final targetUrl = resolveVideoUrl(widget.videoUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
                _buildErrorView(targetUrl)
              else if (!_isInitialized)
                _buildLoadingView()
              else if (_isYoutube && _ytController != null)
                _buildYoutubePlayer()
              else if (_vpController != null && _vpController!.value.isInitialized)
                _buildNativeVideoPlayer()
              else
                _buildErrorView(targetUrl),
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
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
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

  // ── Error / Fallback View (Safe from Overflow) ────────────────────────────
  Widget _buildErrorView(String targetUrl) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary, size: 36),
              const SizedBox(height: 4),
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
                    : 'Tap below to stream or play this video.',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _initPlayer(widget.videoUrl),
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Retry In-App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _launchExternal(targetUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('Play Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  // ── Direct Video Controls Overlay ─────────────────────────────────────────
  Widget _buildControlsOverlay() {
    final c = _vpController!;
    final position = c.value.position;
    final duration = c.value.duration;
    final isPlaying = c.value.isPlaying;

    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top title and sound controls
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _toggleMute,
                  tooltip: _isMuted ? 'Unmute' : 'Mute',
                ),
              ],
            ),
          ),

          // Center Play / Pause button
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),

          // Bottom Progress Bar & Time
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: VideoProgressIndicator(
                    c,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.primary,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white12,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
