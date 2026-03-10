// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final PreferredSizeWidget?
  bottom; // Ubah dari Widget? ke PreferredSizeWidget?
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.bottom,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Size get preferredSize {
    if (bottom != null) {
      return Size.fromHeight(68.0 + bottom!.preferredSize.height);
    }
    return const Size.fromHeight(68.0);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 68.0,
      backgroundColor: AppColors.primary,
      elevation: 0,
      foregroundColor: Colors.white,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed:
                  onBackPressed ??
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
            )
          : null,
      title: subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withAlpha(204),
                    fontSize: 12,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontSize: 18.0,
              ),
            ),
      actions: actions,
      bottom: bottom, // Sekarang sudah compatible
    );
  }
}

// Pastikan SearchAppBarBottom juga implement PreferredSizeWidget
class SearchAppBarBottom extends StatelessWidget
    implements PreferredSizeWidget {
  final TextEditingController searchController;
  final String hintText;
  final int itemCount;
  final int groupCount;
  final VoidCallback onRefresh;
  final bool showGroupCount;

  const SearchAppBarBottom({
    super.key,
    required this.searchController,
    required this.hintText,
    required this.itemCount,
    required this.onRefresh,
    this.groupCount = 0,
    this.showGroupCount = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(92.0); // Height untuk bottom section

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: AppColors.disabled),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Stats & Actions Row
          Row(
            children: [
              // Stats
              SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$itemCount ${_getItemLabel(itemCount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (showGroupCount && groupCount > 0) ...[
                      const TextSpan(text: ' • '),
                      TextSpan(
                        text: '$groupCount ${_getGroupLabel(groupCount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Spacer(),

              // Refresh Button
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getItemLabel(int count) {
    return count == 1 ? 'item' : 'items';
  }

  String _getGroupLabel(int count) {
    return count == 1 ? 'group' : 'groups';
  }
}

// CompactSearchAppBar juga harus implement PreferredSizeWidget
class CompactSearchAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final TextEditingController searchController;
  final String hintText;
  final int itemCount;
  final int groupCount;
  final VoidCallback onRefresh;
  final bool showGroupCount;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CompactSearchAppBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.searchController,
    required this.hintText,
    required this.itemCount,
    required this.onRefresh,
    this.groupCount = 0,
    this.showGroupCount = false,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 120.0,
      backgroundColor: AppColors.primary,
      elevation: 0,
      foregroundColor: Colors.white,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed:
                  onBackPressed ??
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
            )
          : null,
      titleSpacing: showBackButton ? 0 : null,
      flexibleSpace: Column(
        children: [
          // Title Section
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showBackButton) const SizedBox(width: 48),
                Expanded(
                  child: subtitle != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              subtitle!,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withAlpha(204),
                              ),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Colors.white,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),

          // Search Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(color: AppColors.disabled),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Stats & Actions Row
                Row(
                  children: [
                    // Stats
                    SelectableText.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$itemCount ${_getItemLabel(itemCount)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (showGroupCount && groupCount > 0) ...[
                            const TextSpan(text: ' • '),
                            TextSpan(
                              text: '$groupCount ${_getGroupLabel(groupCount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),

                    // Refresh Button
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Refresh',
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

  String _getItemLabel(int count) {
    return count == 1 ? 'item' : 'items';
  }

  String _getGroupLabel(int count) {
    return count == 1 ? 'group' : 'groups';
  }
}

class UserRoleBadge extends StatelessWidget {
  final String role;

  const UserRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatRole(role),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatRole(String status) {
    switch (status.toLowerCase()) {
      case 'superadmin':
        return 'Super Admin';
      case 'koordinator':
        return 'Koordinator';
      case 'teknisi':
        return 'Teknisi';
      default:
        return status;
    }
  }
}
