part of '../thread_screen.dart';

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, required this.size, this.avatarUrl});

  final String name;
  final double size;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final fallbackLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final imageProvider = (avatarUrl?.isNotEmpty ?? false)
        ? NetworkImage(avatarUrl!)
        : null;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _ThreadPalette.surfaceLight,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              fallbackLetter,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _ThreadPalette.textSecondary,
              ),
            )
          : null,
    );
  }
}
