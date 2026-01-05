import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Components/bottom_navbar.dart';
import '../models/user_model.dart';
import '../models/watch_room_model.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';
import '../services/socket_service.dart';
import '../services/watch_room_service.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'watch_room_screen.dart';

class WatchRoomsScreen extends StatefulWidget {
  const WatchRoomsScreen({super.key});

  @override
  State<WatchRoomsScreen> createState() => _WatchRoomsScreenState();
}

class _WatchRoomsScreenState extends State<WatchRoomsScreen> {
  final WatchRoomService _watchRoomService = WatchRoomService();
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();

  List<WatchRoom> _rooms = [];
  bool _isLoading = true;
  User? _user;
  final int _currentNavIndex = 3; // Watch rooms is index 3

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final user = await _authService.getUser();
    final rooms = await _watchRoomService.getRooms();

    if (mounted) {
      setState(() {
        _user = user;
        _rooms = rooms;
        _isLoading = false;
      });
    }

    // Connect socket
    final token = await _authService.getToken();
    _socketService.connect(token: token);
  }

  Future<void> _showCreateRoomDialog() async {
    final movieController = TextEditingController();
    String? selectedMovieSlug;
    String? selectedMovieName;
    String? selectedMoviePoster;

    // Get movies for selection
    final movieService = MovieService();
    List<dynamic> allMovies = await movieService.getMoviesLimit(50);
    List<dynamic> filteredMovies = List.from(allMovies);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          void onSearchChanged(String query) async {
            if (query.isEmpty) {
              setModalState(() => filteredMovies = List.from(allMovies));
            } else {
              // Search from API
              final searchResults = await movieService.searchMovies(
                query,
                limit: 30,
              );
              setModalState(() => filteredMovies = searchResults);
            }
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tạo phòng xem chung',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),

                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: movieController,
                    onChanged: onSearchChanged,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm phim...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Movie list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = filteredMovies[index];
                      final isSelected = selectedMovieSlug == movie.slug;

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedMovieSlug = movie.slug;
                            selectedMovieName = movie.name;
                            selectedMoviePoster = movie.posterUrl;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5BA3F5).withOpacity(0.2)
                                : isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF5BA3F5),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Poster
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  movie.posterUrl,
                                  width: 60,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 80,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.movie,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${movie.year} • ${movie.type}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Check icon
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF5BA3F5),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Create button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedMovieSlug == null
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await _createRoom(
                                selectedMovieSlug!,
                                selectedMovieName!,
                                selectedMoviePoster,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BA3F5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[600],
                      ),
                      child: const Text(
                        'Tạo phòng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createRoom(
    String movieSlug,
    String movieName,
    String? moviePoster,
  ) async {
    setState(() => _isLoading = true);

    final room = await _watchRoomService.createRoom(
      movieSlug: movieSlug,
      movieName: movieName,
      moviePoster: moviePoster,
    );

    if (room != null && mounted) {
      AppSnackBar.showSuccess(context, 'Đã tạo phòng: ${room.roomCode}');

      // Navigate to room
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WatchRoomScreen(room: room, isHost: true),
        ),
      ).then((_) => _loadData());
    } else if (mounted) {
      AppSnackBar.showError(context, 'Không thể tạo phòng');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom(WatchRoom room) async {
    if (_user == null) {
      AppSnackBar.showWarning(context, 'Vui lòng đăng nhập để tham gia');
      return;
    }

    final joinedRoom = await _watchRoomService.joinRoom(room.roomCode);

    if (joinedRoom != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WatchRoomScreen(
            room: joinedRoom,
            isHost: joinedRoom.hostId == _user!.id,
          ),
        ),
      ).then((_) => _loadData());
    } else if (mounted) {
      AppSnackBar.showError(context, 'Không thể tham gia phòng');
    }
  }

  void _showJoinByCodeDialog() {
    final codeController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Nhập mã phòng',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'XXXXXX',
            hintStyle: TextStyle(color: Colors.grey[500]),
            counterText: '',
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.length == 6) {
                Navigator.pop(context);
                final room = await _watchRoomService.getRoom(code);
                if (room != null) {
                  _joinRoom(room);
                } else if (mounted) {
                  AppSnackBar.showError(context, 'Không tìm thấy phòng');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BA3F5),
            ),
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
  }

  void _onNavBarTap(int index) {
    if (index == _currentNavIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const SearchScreen();
        break;
      case 2:
        destination = const BookmarkScreen();
        break;
      case 3:
        return; // Current screen
      case 4:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0E13) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Xem chung',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          // Join by code button
          IconButton(
            onPressed: _showJoinByCodeDialog,
            icon: Icon(
              Icons.qr_code,
              color: isDark ? Colors.white : Colors.black,
            ),
            tooltip: 'Nhập mã phòng',
          ),
          // Refresh button
          IconButton(
            onPressed: _loadData,
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
          ? _buildEmptyState(isDark)
          : _buildRoomsList(isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _user != null ? _showCreateRoomDialog : null,
        backgroundColor: const Color(0xFF5BA3F5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tạo phòng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentNavIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Chưa có phòng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy tạo phòng mới hoặc nhập mã để tham gia',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return _buildRoomCard(room, isDark);
        },
      ),
    );
  }

  Widget _buildRoomCard(WatchRoom room, bool isDark) {
    final isMyRoom = _user != null && room.hostId == _user!.id;

    return GestureDetector(
      onTap: () => _joinRoom(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie poster and info
            Row(
              children: [
                // Poster
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Image.network(
                    room.moviePoster,
                    width: 100,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 140,
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.white54),
                    ),
                  ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room code badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5BA3F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                room.roomCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            if (isMyRoom) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Host',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Movie name
                        Text(
                          room.movieName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Host info
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Host: ${room.hostName}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Participants count
                        Row(
                          children: [
                            Icon(
                              Icons.groups,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${room.participantCount}/${room.maxParticipants}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            // Playing status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: room.isPlaying
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    room.isPlaying
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                    size: 14,
                                    color: room.isPlaying
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    room.isPlaying ? 'Đang phát' : 'Tạm dừng',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: room.isPlaying
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Text formatter to uppercase input
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
