import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/movie_detail_model.dart';
import '../models/user_model.dart';
import '../models/watch_room_model.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';
import '../services/socket_service.dart';
import '../services/watch_room_service.dart';
import '../utils/app_snackbar.dart';

class WatchRoomScreen extends StatefulWidget {
  final WatchRoom room;
  final bool isHost;

  const WatchRoomScreen({super.key, required this.room, required this.isHost});

  @override
  State<WatchRoomScreen> createState() => _WatchRoomScreenState();
}

class _WatchRoomScreenState extends State<WatchRoomScreen> {
  final SocketService _socketService = SocketService();
  final WatchRoomService _watchRoomService = WatchRoomService();
  final AuthService _authService = AuthService();
  final MovieService _movieService = MovieService();

  late WatchRoom _room;
  User? _user;
  MovieDetail? _movieDetail;
  bool _isLoading = true;

  // Video sync state
  String? _currentVideoUrl;
  int _currentServerIndex = 0;
  int _currentEpisodeIndex = 0;

  // Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  // Key to rebuild video player
  Key _playerKey = UniqueKey();

  // Flag to prevent sync loop
  bool _isSyncing = false;

  // Sync indicator
  bool _showSyncIndicator = false;
  IconData _syncIndicatorIcon = Icons.play_arrow;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _currentServerIndex = widget.room.currentServer;
    _currentEpisodeIndex = widget.room.currentEpisode;
    _initRoom();
  }

  Future<void> _initRoom() async {
    _user = await _authService.getUser();
    _movieDetail = await _movieService.getMovieDetailFull(_room.movieSlug);

    if (_movieDetail != null) {
      _updateVideoUrl();
    }

    final token = await _authService.getToken();
    _socketService.connect(token: token);

    if (_user != null) {
      _socketService.joinRoom(
        _room.roomCode,
        _user!.id,
        _user!.name.isNotEmpty ? _user!.name : _user!.email,
      );
    }

    _setupSocketListeners();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _setupSocketListeners() {
    _subscriptions.add(
      _socketService.onSyncState.listen((state) {
        if (!mounted || _isSyncing) return;
        setState(() {
          _currentServerIndex = state.currentServer;
          _currentEpisodeIndex = state.currentEpisode;
          _updateVideoUrl();
        });
      }),
    );

    // Show sync indicator for guests when host controls
    if (!widget.isHost) {
      _subscriptions.add(
        _socketService.onVideoPlay.listen((state) {
          if (!mounted) return;
          _showSyncIcon(Icons.play_arrow);
        }),
      );

      _subscriptions.add(
        _socketService.onVideoPause.listen((state) {
          if (!mounted) return;
          _showSyncIcon(Icons.pause);
        }),
      );

      _subscriptions.add(
        _socketService.onVideoSeek.listen((state) {
          if (!mounted) return;
          _showSyncIcon(Icons.fast_forward);
        }),
      );
    }

    _subscriptions.add(
      _socketService.onEpisodeChange.listen((data) {
        if (!mounted || _isSyncing) return;
        final serverIndex = data['serverIndex'] as int;
        final episodeIndex = data['episodeIndex'] as int;
        setState(() {
          _currentServerIndex = serverIndex;
          _currentEpisodeIndex = episodeIndex;
          _updateVideoUrl();
          _playerKey = UniqueKey();
        });
        AppSnackBar.showInfo(context, 'Đổi tập phim');
      }),
    );

    _subscriptions.add(
      _socketService.onUserJoined.listen((data) {
        if (!mounted) return;
        final userName = data['userName'] ?? 'Ai đó';
        AppSnackBar.showInfo(context, '$userName đã tham gia');
        _refreshRoom();
      }),
    );

    _subscriptions.add(
      _socketService.onUserLeft.listen((data) {
        if (!mounted) return;
        _refreshRoom();
      }),
    );

    _subscriptions.add(
      _socketService.onRoomClosed.listen((message) {
        if (!mounted) return;
        AppSnackBar.showWarning(context, message);
        Navigator.pop(context);
      }),
    );
  }

  void _showSyncIcon(IconData icon) {
    setState(() {
      _showSyncIndicator = true;
      _syncIndicatorIcon = icon;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSyncIndicator = false);
      }
    });
  }

  void _updateVideoUrl() {
    if (_movieDetail == null) return;
    if (_movieDetail!.episodes.isEmpty) return;
    final server = _movieDetail!.episodes[_currentServerIndex];
    if (server.episodes.isEmpty) return;
    final episode = server.episodes[_currentEpisodeIndex];
    _currentVideoUrl = episode.linkM3u8.isNotEmpty
        ? episode.linkM3u8
        : episode.linkEmbed;
  }

  Future<void> _refreshRoom() async {
    final room = await _watchRoomService.getRoom(_room.roomCode);
    if (room != null && mounted) {
      setState(() => _room = room);
    }
  }

  Future<void> _leaveRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isHost ? 'Đóng phòng?' : 'Rời phòng?'),
        content: Text(
          widget.isHost
              ? 'Đóng phòng sẽ kết thúc phiên xem cho tất cả mọi người.'
              : 'Bạn có chắc muốn rời phòng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(widget.isHost ? 'Đóng phòng' : 'Rời phòng'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (widget.isHost) {
        _socketService.closeRoom(_room.roomCode);
        await _watchRoomService.closeRoom(_room.roomCode);
      } else {
        _socketService.leaveRoom(_room.roomCode);
        await _watchRoomService.leaveRoom(_room.roomCode);
      }
      Navigator.pop(context);
    }
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: _room.roomCode));
    AppSnackBar.showSuccess(context, 'Đã sao chép mã phòng: ${_room.roomCode}');
  }

  void _onEpisodeTap(int serverIndex, int episodeIndex) {
    if (!widget.isHost) {
      AppSnackBar.showWarning(context, 'Chỉ host mới có thể đổi tập');
      return;
    }

    _isSyncing = true;
    setState(() {
      _currentServerIndex = serverIndex;
      _currentEpisodeIndex = episodeIndex;
      _updateVideoUrl();
      _playerKey = UniqueKey();
    });
    _socketService.emitEpisodeChange(serverIndex, episodeIndex);
    Future.delayed(const Duration(milliseconds: 500), () => _isSyncing = false);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _socketService.leaveRoom(_room.roomCode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Video player
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        if (_currentVideoUrl != null)
                          SyncedVideoPlayer(
                            key: _playerKey,
                            videoUrl: _currentVideoUrl!,
                            isHost: widget.isHost,
                            roomCode: _room.roomCode,
                            initialTime: _room.currentTime,
                            socketService: _socketService,
                          )
                        else
                          Container(
                            color: Colors.black,
                            child: const Center(
                              child: Text(
                                'Không thể tải video',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                        // Sync indicator (only icon, appears briefly on guest)
                        if (_showSyncIndicator && !widget.isHost)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _syncIndicatorIcon,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),

                        // Back button
                        Positioned(
                          top: 10,
                          left: 10,
                          child: IconButton(
                            onPressed: _leaveRoom,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Room code badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _copyRoomCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF5BA3F5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.copy,
                                    color: Color(0xFF5BA3F5),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _room.roomCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Room info
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Movie info
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _room.movieName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_movieDetail != null &&
                                    _movieDetail!.episodes.isNotEmpty)
                                  Text(
                                    '${_movieDetail!.episodes[_currentServerIndex].serverName} - ${_movieDetail!.episodes[_currentServerIndex].episodes[_currentEpisodeIndex].name}',
                                    style: const TextStyle(
                                      color: Color(0xFF5BA3F5),
                                      fontSize: 15,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const Divider(color: Colors.grey, height: 1),

                          // Participants
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.groups,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Đang xem (${_room.participantCount})',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 60,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _room.participants.length,
                                    itemBuilder: (context, index) {
                                      final participant =
                                          _room.participants[index];
                                      final isHostUser =
                                          participant.id == _room.hostId;
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: const Color(
                                                    0xFF5BA3F5,
                                                  ),
                                                  backgroundImage:
                                                      participant.avatar != null
                                                      ? NetworkImage(
                                                          participant.avatar!,
                                                        )
                                                      : null,
                                                  child:
                                                      participant.avatar == null
                                                      ? Text(
                                                          participant.name
                                                              .substring(0, 1)
                                                              .toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        )
                                                      : null,
                                                ),
                                                if (isHostUser)
                                                  Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            2,
                                                          ),
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.amber,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      child: const Icon(
                                                        Icons.star,
                                                        size: 10,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              width: 60,
                                              child: Text(
                                                participant.name,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(color: Colors.grey, height: 1),

                          // Episode list
                          if (_movieDetail != null &&
                              _movieDetail!.episodes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.list,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Danh sách tập',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (!widget.isHost) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Chỉ host',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                      _movieDetail!
                                          .episodes[_currentServerIndex]
                                          .episodes
                                          .length,
                                      (index) {
                                        final episode = _movieDetail!
                                            .episodes[_currentServerIndex]
                                            .episodes[index];
                                        final isSelected =
                                            index == _currentEpisodeIndex;
                                        return GestureDetector(
                                          onTap: () => _onEpisodeTap(
                                            _currentServerIndex,
                                            index,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF5BA3F5)
                                                  : Colors.white.withOpacity(
                                                      0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: isSelected
                                                  ? null
                                                  : Border.all(
                                                      color: Colors.white24,
                                                    ),
                                            ),
                                            child: Text(
                                              episode.name,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Synced video player - host can control, guest syncs automatically
class SyncedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isHost;
  final String roomCode;
  final double initialTime;
  final SocketService socketService;

  const SyncedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isHost,
    required this.roomCode,
    required this.initialTime,
    required this.socketService,
  });

  @override
  State<SyncedVideoPlayer> createState() => _SyncedVideoPlayerState();
}

class _SyncedVideoPlayerState extends State<SyncedVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isError = false;
  bool _isInitialized = false;
  bool _isSyncing = false;

  final List<StreamSubscription> _subscriptions = [];
  bool _wasPlaying = false;
  Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Guest syncs to host
    if (!widget.isHost) {
      _subscriptions.add(
        widget.socketService.onVideoPlay.listen((state) {
          if (_isSyncing || _videoController == null) return;
          _isSyncing = true;
          final target = Duration(
            milliseconds: (state.currentTime * 1000).toInt(),
          );
          _videoController!.seekTo(target);
          _videoController!.play();
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _isSyncing = false,
          );
        }),
      );

      _subscriptions.add(
        widget.socketService.onVideoPause.listen((state) {
          if (_isSyncing || _videoController == null) return;
          _isSyncing = true;
          final target = Duration(
            milliseconds: (state.currentTime * 1000).toInt(),
          );
          _videoController!.pause();
          _videoController!.seekTo(target);
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _isSyncing = false,
          );
        }),
      );

      _subscriptions.add(
        widget.socketService.onVideoSeek.listen((state) {
          if (_isSyncing || _videoController == null) return;
          _isSyncing = true;
          final target = Duration(
            milliseconds: (state.currentTime * 1000).toInt(),
          );
          _videoController!.seekTo(target);
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _isSyncing = false,
          );
        }),
      );
    }
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _videoController!.initialize();

      if (widget.initialTime > 0) {
        await _videoController!.seekTo(
          Duration(milliseconds: (widget.initialTime * 1000).toInt()),
        );
      }

      if (widget.isHost) {
        _videoController!.addListener(_onVideoStateChanged);
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: widget.isHost,
        // Host sees all controls, guest sees only fullscreen button
        showControls: true,
        showControlsOnInitialize: widget.isHost,
        customControls: widget.isHost ? null : const GuestControls(),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Lỗi: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF5BA3F5),
          handleColor: const Color(0xFF5BA3F5),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[700]!,
        ),
      );

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) setState(() => _isError = true);
    }
  }

  void _onVideoStateChanged() {
    if (!mounted || _isSyncing || _videoController == null) return;

    final isPlaying = _videoController!.value.isPlaying;
    final position = _videoController!.value.position;

    if (isPlaying && !_wasPlaying) {
      widget.socketService.emitPlay(position.inMilliseconds / 1000);
    } else if (!isPlaying && _wasPlaying) {
      widget.socketService.emitPause(position.inMilliseconds / 1000);
    }

    final diff = (position - _lastPosition).abs();
    if (diff > const Duration(seconds: 2) && _wasPlaying == isPlaying) {
      widget.socketService.emitSeek(position.inMilliseconds / 1000);
    }

    _wasPlaying = isPlaying;
    _lastPosition = position;
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _videoController?.removeListener(_onVideoStateChanged);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text(
                'Không thể tải video',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5BA3F5)),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}

/// Custom controls for guest - only shows fullscreen button
class GuestControls extends StatelessWidget {
  const GuestControls({super.key});

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);

    return Stack(
      children: [
        // Progress bar (view only)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            color: Colors.grey[800],
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: chewieController.videoPlayerController,
              builder: (context, value, child) {
                final duration = value.duration.inMilliseconds;
                final position = value.position.inMilliseconds;
                final progress = duration > 0 ? position / duration : 0.0;
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(color: const Color(0xFF5BA3F5)),
                );
              },
            ),
          ),
        ),

        // Fullscreen button only
        Positioned(
          bottom: 8,
          right: 8,
          child: IconButton(
            icon: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: () {
              chewieController.toggleFullScreen();
            },
          ),
        ),
      ],
    );
  }
}
