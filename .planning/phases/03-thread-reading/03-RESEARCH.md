# Phase 3: Thread Reading - Research

**Researched:** 2026-01-23
**Domain:** Flutter NGA forum thread reader with images and pagination
**Confidence:** HIGH

## Summary

Research for implementing thread reading with images, efficient loading, and gallery view. The NGA forum uses HTML-based thread pages that can be parsed to extract post content including images. The codebase already has foundational thread parsing and pagination infrastructure.

**Primary recommendations:**
- Use `cached_network_image` + `flutter_cache_manager` for image caching with progressive loading
- Use `photo_view` for full-screen gallery with zoom/pan gestures
- Enhance `ThreadParser` to extract image URLs from post content
- The existing pagination in `ThreadScreen` with scroll notifications is adequate for lazy loading

## NGA Thread API

### Endpoint Structure

NGA uses HTML pages rather than a JSON API. Thread content is fetched via:

```
https://bbs.nga.cn/read.php?tid={thread_id}&page={page_number}
```

**Parameters:**
| Parameter | Required | Description |
|-----------|----------|-------------|
| `tid` | Yes | Thread ID (numeric) |
| `page` | No | Page number (1-based, default: 1) |
| `order` | No | `pid` for chronological, default: desc |

**Current Implementation:**
The existing `NgaRepository.fetchThread()` method (line 47-75 in `nga_repository.dart`) already uses this pattern correctly with pagination support.

### Thread URL Structure

NGA thread URLs follow these patterns:
- `https://bbs.nga.cn/read.php?tid={tid}` - Thread landing page
- `https://bbs.nga.cn/read.php?tid={tid}&page={n}` - Specific page
- Deep link format: `nga://bbs.nga.cn/read.php?tid={tid}` (app scheme)

### HTML Structure Pattern

The existing `ThreadParser` has already reverse-engineered NGA's HTML structure:

```dart
// Post container selector (from thread_parser.dart line 46)
final postRows = doc.querySelectorAll('table.forumbox.postbox');

// Author info embedded in page as JSON
// commonui.userInfo.setAll({ ... }) - contains user data
// commonui.postArg.proc(floor, ..., 'deviceType', ...) - device info
```

## HTML Parsing Strategy

### Current Implementation

The `ThreadParser` class uses a hybrid approach:
1. **Regex extraction** for embedded JSON data (`commonui.userInfo.setAll`)
2. **DOM parsing** for post structure (`table.forumbox.postbox`)
3. **Legacy fallback** for edge cases

### Enhancement Needed: Image Extraction

**Current limitation:** `ThreadParser` only extracts `contentText` (plain text). Images in posts are not extracted.

**Recommended approach:** Parse the HTML content element to extract `<img>` tags:

```dart
// Example: Extract image URLs from post content
final contentEl = row.querySelector('[id^=postcontent]') ??
    row.querySelector('.postcontent.ubbcode');
final images = contentEl?.querySelectorAll('img').map((img) {
  return img.attributes['src'] ?? '';
}).where((src) => src.isNotEmpty).toList() ?? [];
```

### Image URL Patterns in NGA Posts

NGA hosts images on multiple domains:
- `img.nga.178.com` - Primary NGA image CDN
- `nga.178.com` - Alternative domain
- `pic4.nga.178.com` - Thumbnail/resized versions
- External images from various sources

**Important:** NGA uses a lazy-load system where `src` may be a placeholder and real URL is in `data-src` or `original` attribute.

## Image Handling

### Recommended Stack

| Package | Version | Purpose |
|---------|---------|---------|
| `cached_network_image` | ^3.4.1 | Image widget with caching |
| `flutter_cache_manager` | ^3.4.1 | Underlying cache infrastructure |
| `photo_view` | ^0.15.0 | Gallery with zoom/pan |

### cached_network_image Usage

For progressive loading with placeholders:

```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => Container(
    color: Colors.grey[200],
    child: const Center(child: CircularProgressIndicator()),
  ),
  progressIndicatorBuilder: (context, url, progress) {
    return LinearProgressIndicator(value: progress.progress);
  },
  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
  fadeInDuration: const Duration(milliseconds: 300),
  fit: BoxFit.contain,
);
```

### flutter_cache_manager Configuration

Create a custom cache manager for NGA images:

```dart
class NgaImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'nga_image_cache';

  static final NgaImageCacheManager _instance =
      NgaImageCacheManager._();
  factory NgaImageCacheManager() => _instance;
  NgaImageCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 100,
  ));
}
```

**Configuration recommendations:**
- `stalePeriod`: 7 days (forum images don't change often)
- `maxNrOfCacheObjects`: 100-200 for typical thread reading sessions
- Enable HTTP cache headers via `HttpFileService`

### NGA Image Domain Handling

NGA's image URLs may need URL resolution:

```dart
String resolveNgaImageUrl(String src) {
  if (src.startsWith('//')) {
    return 'https:$src';
  }
  if (!src.startsWith('http')) {
    return 'https://img.nga.178.com/$src';
  }
  return src;
}
```

**Common patterns:**
- Thumbnail URLs: `pic4.nga.178.com/xxx_120.jpg` (append `_120` for thumbnails)
- Full size: Remove thumbnail suffix for original

## Pagination/Lazy Loading

### Current Implementation Analysis

The existing `ThreadScreen` already implements pagination correctly:

```dart
// Line 63-77 in thread_body.dart
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (position.pixels >= position.maxScrollExtent - 200) {
      onLoadMore();
    }
    return false;
  },
  child: ListView(...),
)
```

**This approach is adequate for:**
- Automatic load-more trigger when nearing scroll end
- Pull-to-refresh via `RefreshIndicator`
- Loading states with proper UI feedback

### Alternatives Considered

| Package | When to Use |
|---------|-------------|
| `infinite_scroll_pagination` | Complex pagination with filters, PagedListView integration |
| Built-in (current) | Simple sequential page loading |

**Recommendation:** The current implementation is sufficient. No additional package needed.

### Large Thread Optimization (100+ pages)

For threads with 100+ pages, consider:

1. **Page caching:** Keep parsed posts in memory with a limit (e.g., last 10 pages)
2. **Image lazy loading:** Only load images when they enter viewport using `LazyLoadScrollView` or similar
3. **Virtual scrolling:** For extremely long threads, consider `SliverVirtualizedList`

```dart
// Page cache implementation concept
final _pageCache = LinkedHashMap<int, List<ThreadPost>>(
  maxSize: 10,
  // Keep last 10 pages in memory
);
```

## Full-screen Gallery

### Recommended Package: photo_view

`photo_view` ^0.15.0 provides:
- Pinch-to-zoom
- Pan gestures
- Rotation support
- `PhotoViewGallery` for swipeable image galleries
- Hero animation integration

### Implementation Pattern

```dart
// Full-screen image viewer
 Navigator.push(
   context,
   MaterialPageRoute(
     builder: (context) => PhotoViewGallery.builder(
       itemCount: imageUrls.length,
       builder: (context, index) {
         return PhotoViewGalleryPageOptions(
           imageProvider: CachedNetworkImageProvider(imageUrls[index]),
           minScale: PhotoViewCompressionScale.minimum,
           maxScale: PhotoViewCompressionScale.oversize,
         );
       },
       pageController: PageController(initialPage: initialIndex),
     ),
   ),
 );
```

### Alternative: extended_image

`extended_image` ^10.0.1 offers similar features with additional:
- Built-in caching integration
- Gesture-based zoom in `ExtendedImageGesturePageView`
- More customization options

**Decision:** `photo_view` is simpler for basic gallery needs. Use `extended_image` if you need tighter cache integration or advanced gesture handling.

### Gallery Integration with Thread Posts

When user taps an image in a post:

1. Extract all image URLs from the current post
2. Determine tapped image index
3. Show gallery starting at tapped image
4. Allow swipe to see other images in the same post

```dart
// In _MainPostHeader or post content widget
GestureDetector(
  onTap: () => _openGallery(post.images, index),
  child: CachedNetworkImage(imageUrl: url),
)
```

## Implementation Recommendations

### 1. ThreadParser Enhancement

Add image extraction to `ThreadPost` model:

```dart
class ThreadPost {
  // ... existing fields ...
  List<String> imageUrls;  // NEW: extracted image URLs
}
```

Update `parseHybrid` to extract images:

```dart
final imageElements = row.querySelectorAll('.postcontent.ubbcode img');
final imageUrls = imageElements
    .map((e) => e.attributes['src'] ?? e.attributes['data-src'])
    .where((u) => u != null && u.isNotEmpty)
    .map((u) => resolveNgaImageUrl(u!))
    .toList();
```

### 2. Post Content Widget Update

Display images below text content:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(post.contentText),
    if (post.imageUrls.isNotEmpty) ...[
      const SizedBox(height: 8),
      _PostImageGrid(images: post.imageUrls),
    ],
  ],
)
```

### 3. Image Grid Layout

For multiple images in a post:

```dart
Widget _buildImageGrid(List<String> images) {
  if (images.length == 1) {
    return _buildFullImage(images[0]);
  } else if (images.length <= 3) {
    return Row(
      children: images.map((url) => Expanded(child: _buildThumb(url))).toList(),
    );
  } else {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      children: images.map((url) => _buildThumb(url)).toList(),
    );
  }
}
```

### 4. Dependency Additions

Add to `pubspec.yaml`:

```yaml
dependencies:
  cached_network_image: ^3.4.1
  flutter_cache_manager: ^3.4.1
  photo_view: ^0.15.0
```

### 5. Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Image caching | Custom file cache | `cached_network_image` + `flutter_cache_manager` |
| Image download progress | Custom implementation | `cached_network_image` progressIndicatorBuilder |
| Full-screen zoom/pan | Custom gesture handling | `photo_view` |
| Cache storage/retrieval | SQLite manually | `flutter_cache_manager` |

## Common Pitfalls

### Pitfall 1: NGA Image Lazy Loading

**What goes wrong:** NGA uses `data-src` for actual image URLs, `src` shows a placeholder.

**How to avoid:**
```dart
// Check both src and data-src
final url = img.attributes['data-src'] ?? img.attributes['src'];
```

### Pitfall 2: Image URL Protocol

**What goes wrong:** URLs start with `//` (protocol-relative), failing on iOS.

**How to avoid:**
```dart
if (url.startsWith('//')) url = 'https:$url';
```

### Pitfall 3: Memory with Large Images

**What goes wrong:** Loading full-resolution images in thumbnail grid causes OOM.

**How to avoid:** Use thumbnail variants when available:
```dart
// NGA pattern: full.jpg -> thumb_200.jpg
String getThumbnail(String url) {
  if (url.contains('nga.178.com')) {
    return url.replaceAll('.jpg', '_120.jpg')
        .replaceAll('.png', '_120.png');
  }
  return url;
}
```

### Pitfall 4: Cache Key Conflicts

**What goes wrong:** Multiple cache managers with same key cause conflicts.

**How to avoid:** Use unique keys per manager:
```dart
class NgaImageCacheManager extends CacheManager {
  static const key = 'nga_images_v1';  // Versioned key
}
```

## Code Examples

### Full Gallery with Cached Images

```dart
// Source: photo_view + cached_network_image pattern
class ImageGalleryScreen extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageGalleryScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PhotoViewGallery.builder(
        itemCount: imageUrls.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(
              imageUrls[index],
              cacheManager: NgaImageCacheManager(),
            ),
            minScale: PhotoViewCompressionScale.minimum,
            heroAttributes: PhotoViewHeroAttributes(
              tag: 'image_$index',
            ),
          );
        },
      ),
    );
  }
}
```

### Progressive Loading Image Widget

```dart
// Source: cached_network_image pattern
class ProgressiveNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const ProgressiveNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      progressIndicatorBuilder: (context, url, progress) {
        return LinearProgressIndicator(
          value: progress.progress,
          backgroundColor: Colors.grey[200],
        );
      },
      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Basic NetworkImage | cached_network_image | 2019+ | Caching, placeholders, error handling |
| Custom gallery | photo_view/extended_image | 2019+ | Standardized zoom/pan gestures |
| Manual pagination state | infinite_scroll_pagination | 2020+ | Reduced boilerplate |
| Hardcoded cache | flutter_cache_manager | 2019+ | Configurable cache policies |

**Deprecated/outdated:**
- `flutter_cached_network_image` - deprecated, use `cached_network_image`
- `photo_view` pre-0.14 - older API, current version is stable

## Open Questions

1. **Image URL extraction:** The current ThreadParser extracts `contentText` only. Need to verify if NGA stores image URLs in a structured format or only as `<img>` tags in HTML.

2. **Thumbnail generation:** Not clear if NGA provides reliable thumbnail URLs for all images. May need client-side downsampling.

3. **Large thread memory:** For threads with 100+ pages and hundreds of images, may need aggressive image disposal. Consider using `ImageCache` configuration.

## Sources

### Primary (HIGH confidence)
- [cached_network_image pub.dev](https://pub.dev/packages/cached_network_image) - Latest version 3.4.1, features documented
- [flutter_cache_manager pub.dev](https://pub.dev/packages/flutter_cache_manager) - Latest version 3.4.1, cache configuration
- [photo_view pub.dev](https://pub.dev/packages/photo_view) - Latest version 0.15.0, gallery features
- [extended_image pub.dev](https://pub.dev/packages/extended_image) - Latest version 10.0.1, alternative gallery

### Secondary (MEDIUM confidence)
- [infinite_scroll_pagination pub.dev](https://pub.dev/packages/infinite_scroll_pagination) - Lazy loading pagination pattern

### Tertiary (LOW confidence)
- NGA API patterns inferred from existing codebase analysis

## Metadata

**Confidence breakdown:**
- NGA API/HTML structure: HIGH - verified from existing codebase
- Image caching packages: HIGH - documented on pub.dev
- Gallery implementation: HIGH - standard patterns
- NGA image domain specifics: MEDIUM - inferred from patterns

**Research date:** 2026-01-23
**Valid until:** 2026-07-23 (6 months for stable Flutter packages)
