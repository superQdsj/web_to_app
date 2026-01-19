part of '../thread_screen.dart';

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: _ThreadPalette.backgroundLight,
          border: Border(
            top: BorderSide(color: _ThreadPalette.borderLight),
          ),
        ),
        child: Row(
          children: [
            const _UserAvatar(name: 'You', size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Add a reply...',
                  hintStyle: const TextStyle(
                    color: _ThreadPalette.textSecondary,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: _ThreadPalette.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  color: _ThreadPalette.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: _ThreadPalette.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.send, size: 18),
                color: Colors.white,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

