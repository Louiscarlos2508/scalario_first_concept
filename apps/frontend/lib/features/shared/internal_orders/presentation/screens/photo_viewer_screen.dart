import 'package:flutter/material.dart';

/// Donnée d'une photo mock (placeholder avec couleur + caption).
class PhotoData {
  final Color color;
  final String caption;

  const PhotoData({required this.color, required this.caption});
}

/// Écran plein-écran de visualisation photo — Figma 32:344.
/// Mobile : plein écran noir, top bar gradient, thumbnails en bas, caption.
/// Desktop (≥ 1024) : Dialog centré avec la même UI.
void openPhotoViewer(
  BuildContext context, {
  required List<PhotoData> photos,
  required String title,
  required String subtitle,
  int initialIndex = 0,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

  if (isDesktop) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _PhotoViewerContent(
              photos: photos,
              title: title,
              subtitle: subtitle,
              initialIndex: initialIndex,
            ),
          ),
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewerContent(
          photos: photos,
          title: title,
          subtitle: subtitle,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _PhotoViewerContent extends StatefulWidget {
  final List<PhotoData> photos;
  final String title;
  final String subtitle;
  final int initialIndex;

  const _PhotoViewerContent({
    required this.photos,
    required this.title,
    required this.subtitle,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerContent> createState() => _PhotoViewerContentState();
}

class _PhotoViewerContentState extends State<_PhotoViewerContent> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Main photo (swipeable) ──────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              final p = widget.photos[i];
              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 37),
                  constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        p.color.withValues(alpha: 0.7),
                        p.color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text('\u{1F4F7}',
                      style: TextStyle(fontSize: 140)),
                ),
              );
            },
          ),

          // ── Top bar (gradient overlay) ──────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 64 + MediaQuery.paddingOf(context).top,
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xBF000000), Colors.transparent],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Close button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Text('\u2715',
                                style: TextStyle(
                                    fontSize: 22, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(widget.title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          Opacity(
                            opacity: 0.8,
                            child: Text(widget.subtitle,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom area: thumbnails + caption + counter ─────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xBF000000), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnails
                  if (widget.photos.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < widget.photos.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(i,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut);
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: widget.photos[i].color,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _currentIndex == i
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 1.6,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('\u{1F4F7}',
                                      style: TextStyle(fontSize: 22)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Caption
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '"${photo.caption}"',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Counter
                  Opacity(
                    opacity: 0.8,
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        fontFamily: 'Cousine',
                        fontSize: 11,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
