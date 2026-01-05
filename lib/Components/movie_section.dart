import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../models/movie_model.dart';
import 'movie_card.dart';
import '../Views/movie_detail_screen.dart';

class MovieSection extends StatelessWidget {
  final String title;
  final List<Movie> movies;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final IconData? titleIcon;

  const MovieSection({
    super.key,
    required this.title,
    required this.movies,
    required this.isLoading,
    this.onSeeAll,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (titleIcon != null) ...[
                    Icon(titleIcon, color: const Color(0xFF5BA3F5), size: 24),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'XEM TẤT CẢ',
                    style: TextStyle(
                      color: Color(0xFF5BA3F5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 160,
                        child: MovieCard(
                          title: movie.name,
                          imageUrl: movie.posterUrl.isNotEmpty
                              ? movie.posterUrl
                              : 'https://picsum.photos/200/300',
                          year: movie.year.toString(),
                          genre: movie.type,
                          isBookmarked: false,
                          onBookmark: () {
                            // Xử lý hành động bookmark
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailScreen(
                                  movieId: movie.id,
                                  movie: movie,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
