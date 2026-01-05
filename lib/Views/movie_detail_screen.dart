import 'package:flutter/material.dart';

import '../Components/comment_section.dart';
import '../Components/custom_button.dart';
import '../models/movie_model.dart';
import '../services/saved_movie_service.dart';
import '../utils/app_snackbar.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;
  final Movie? movie; // Optional: pass full movie data for bookmark

  // Tạm thời để default value để không lỗi các màn hình khác
  // Sau này bạn nên truyền ID thật từ API phim
  const MovieDetailScreen({
    super.key,
    this.movieId = 'avengers-endgame-2019',
    this.movie,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isSaved = false;
  bool _isSaveLoading = false;
  final SavedMovieService _savedMovieService = SavedMovieService();

  final List<Map<String, String>> _cast = [
    {
      'name': 'Robert D. Jr',
      'role': 'Iron Man',
      'image': 'https://i.pravatar.cc/150?img=11',
    },
    {
      'name': 'Chris Evans',
      'role': 'Captain',
      'image': 'https://i.pravatar.cc/150?img=12',
    },
    {
      'name': 'Scarlett J.',
      'role': 'Black Widow',
      'image': 'https://i.pravatar.cc/150?img=13',
    },
    {
      'name': 'Chris H.',
      'role': 'Thor',
      'image': 'https://i.pravatar.cc/150?img=14',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkSaveStatus();
  }

  Future<void> _checkSaveStatus() async {
    final isSaved = await _savedMovieService.isMovieSaved(widget.movieId);
    if (mounted) {
      setState(() => _isSaved = isSaved);
    }
  }

  Future<void> _toggleSaveMovie() async {
    if (_isSaveLoading) return;

    setState(() => _isSaveLoading = true);

    try {
      if (_isSaved) {
        // Remove from saved list
        final response = await _savedMovieService.removeSavedMovie(
          widget.movieId,
        );
        if (response.success && mounted) {
          setState(() => _isSaved = false);
          AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
        } else if (mounted) {
          AppSnackBar.showError(
            context,
            response.message ?? 'Không thể xóa phim',
          );
        }
      } else {
        // Save movie using movieId (slug)
        final response = await _savedMovieService.saveMovie(widget.movieId);
        if (response.success && mounted) {
          setState(() => _isSaved = true);
          AppSnackBar.showSuccess(context, 'Đã lưu phim thành công');
        } else if (mounted) {
          AppSnackBar.showError(
            context,
            response.message ?? 'Không thể lưu phim',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Có lỗi xảy ra');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaveLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Movie Poster with Play Button
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF0B0E13)
                : const Color(0xFFF5F5F5),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: _isSaveLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: _isSaved
                              ? const Color(0xFF5BA3F5)
                              : Colors.white,
                        ),
                        onPressed: _toggleSaveMovie,
                      ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.network(
                    'https://images.unsplash.com/photo-1635863138275-d9b33299680b?w=800',
                    fit: BoxFit.cover,
                  ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0B0E13).withOpacity(0.7),
                          const Color(0xFF0B0E13),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Movie Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genre Tags and Rating
                  Row(
                    children: [
                      _buildGenreChip('HÀNH ĐỘNG', const Color(0xFF5BA3F5)),
                      const SizedBox(width: 8),
                      _buildGenreChip('VIỄN TƯỞNG', const Color(0xFF1A2332)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.black, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '9.8',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Avengers:',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Text(
                    'Endgame',
                    style: TextStyle(
                      color: Color(0xFF5BA3F5),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Year, Duration, Quality
                  Row(
                    children: [
                      const Text(
                        '2019',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '3g 2p',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A2332)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hd,
                              color: Color(0xFF5BA3F5),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4K Ultra HD',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Xem ngay',
                          onPressed: () {},
                          backgroundColor: const Color(0xFF5BA3F5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A2332)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.add,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A2332)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Danh sách',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Synopsis
                  Text(
                    'Nội dung',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Sau những sự kiện tàn khốc của Avengers: Infinity War (2018), vũ trụ đang ở hủy hoại. Với sự giúp đỡ của các đồng minh còn lại, Avengers tập hợp một lần nữa để đảo ngược hành động của Thanos và khôi phục cân bằng cho vũ trụ.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cast
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Diễn viên',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'TẤT CẢ',
                          style: TextStyle(
                            color: Color(0xFF5BA3F5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cast.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(_cast[index]['image']!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 80,
                                child: Column(
                                  children: [
                                    Text(
                                      _cast[index]['name']!.split(' ')[0],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _cast[index]['role'] ?? 'Character',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Comments Section
                  CommentSection(movieId: widget.movieId),

                  const SizedBox(height: 24),

                  // Related Movies
                  Text(
                    'Có thể bạn thích',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            width: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF1A2332),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        'https://picsum.photos/130/160?random=$index',
                                      ),
                                      fit: BoxFit.cover,
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

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
