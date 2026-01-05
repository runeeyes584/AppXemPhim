import 'dart:math';
import 'package:flutter/material.dart';

/// Model cho thông tin diễn viên
class CastMember {
  final String name;
  final String? role;
  final String? imageUrl;

  const CastMember({required this.name, this.role, this.imageUrl});
}

/// Widget hiển thị danh sách diễn viên với ảnh từ assets
class CastList extends StatelessWidget {
  final List<CastMember> cast;
  final VoidCallback? onSeeAllTap;
  final Color primaryColor;

  // Danh sách ảnh local trong assets
  static const List<String> _localAvatars = [
    'Assets/img/avt1.png',
    'Assets/img/avt2.png',
    'Assets/img/avt3.png',
    'Assets/img/avt4.png',
  ];

  const CastList({
    super.key,
    required this.cast,
    this.onSeeAllTap,
    this.primaryColor = const Color(0xFF5BA3F5),
  });

  /// Lấy ảnh ngẫu nhiên từ thư mục assets
  String _getRandomAvatar(int index) {
    final random = Random(index); // Seed để cùng index ra cùng ảnh
    return _localAvatars[random.nextInt(_localAvatars.length)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
            if (onSeeAllTap != null)
              TextButton(
                onPressed: onSeeAllTap,
                child: Text(
                  'TẤT CẢ',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Cast horizontal list
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final member = cast[index];
              final avatarPath = member.imageUrl ?? _getRandomAvatar(index);
              final isLocalAsset = avatarPath.startsWith('Assets/');

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildCastCard(
                  context,
                  member,
                  avatarPath,
                  isLocalAsset,
                  isDark,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCastCard(
    BuildContext context,
    CastMember member,
    String avatarPath,
    bool isLocalAsset,
    bool isDark,
  ) {
    return Column(
      children: [
        // Avatar image
        Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isLocalAsset
                ? Image.asset(
                    avatarPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(isDark);
                    },
                  )
                : Image.network(
                    avatarPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(isDark);
                    },
                  ),
          ),
        ),

        const SizedBox(height: 10),

        // Name and role
        SizedBox(
          width: 90,
          child: Column(
            children: [
              Text(
                member.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (member.role != null) ...[
                const SizedBox(height: 2),
                Text(
                  member.role!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A2332) : Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 40,
        color: isDark ? Colors.grey[600] : Colors.grey[500],
      ),
    );
  }
}
