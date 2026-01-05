import 'dart:async';
import 'package:flutter/material.dart';

import '../Components/bottom_navbar.dart';
import '../Components/search_bar_widget.dart';
import '../Components/category_filter_list.dart';
import '../Components/search_results_grid.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';
import '../services/saved_movie_notifier.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MovieService _movieService = MovieService();

  int _currentIndex = 1;
  bool _isLoading = false;
  List<Movie> _searchResults = [];
  String _searchQuery = '';
  Timer? _debounce;

  // Categories for filter
  final List<String> _categories = [
    'Tất cả',
    'Hành động',
    'Tình cảm',
    'Kinh dị',
    'Hoạt hình',
    'Viễn tưởng',
  ];
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    savedMovieNotifier.addListener(_onSavedMoviesChanged);
    if (!savedMovieNotifier.isLoaded) {
      savedMovieNotifier.loadSavedMovies();
    }
  }

  @override
  void dispose() {
    savedMovieNotifier.removeListener(_onSavedMoviesChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSavedMoviesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _searchQuery = query;
    });

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    // Call API
    final results = await _movieService.searchMovies(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSaveMovie(Movie movie) async {
    final slug = movie.slug;
    final isCurrentlySaved = savedMovieNotifier.isMovieSaved(slug);

    if (isCurrentlySaved) {
      final success = await savedMovieNotifier.removeSavedMovie(slug);
      if (success && mounted) {
        AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
      } else if (mounted) {
        AppSnackBar.showError(context, 'Không thể xóa phim');
      }
    } else {
      final success = await savedMovieNotifier.saveMovie(slug);
      if (success && mounted) {
        AppSnackBar.showSuccess(context, 'Đã lưu phim thành công');
      } else if (mounted) {
        AppSnackBar.showError(context, 'Không thể lưu phim');
      }
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Widget destination;
      switch (index) {
        case 2:
          destination = const BookmarkScreen();
          break;
        case 3:
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Component
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: SearchBarWidget(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onFilterTap: () {
                        // Show filter bottom sheet or dialog
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter Component
            CategoryFilterList(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
                // TODO: Implement category filtering logic combining with search
              },
            ),

            const SizedBox(height: 16),

            // Search Results or Placeholder
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildEmptyState(
                      isDark,
                    ) // Show suggestions/history when empty
                  : SearchResultsGrid(
                      movies: _searchResults,
                      isLoading: _isLoading,
                      isBookmarked: (movie) =>
                          savedMovieNotifier.isMovieSaved(movie.slug),
                      onBookmark: _toggleSaveMovie,
                      onMovieTap: (movie) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(
                              movieId: movie.slug, // Pass slug as ID
                              movie: movie,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Suggestions Section with hardcoded data for now
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Gợi ý tìm kiếm',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip('🔥 Top Gun: Maverick', isDark),
                _buildSuggestionChip('Avatar 2', isDark),
                _buildSuggestionChip('Spider-Man', isDark),
                _buildSuggestionChip('Phim Hàn Quốc mới', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _onSearchChanged(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
