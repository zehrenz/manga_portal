// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mangaDexApiServiceHash() =>
    r'6a46ffbab2dc10e14270fb96cc8d5f83076d5063';

/// See also [mangaDexApiService].
@ProviderFor(mangaDexApiService)
final mangaDexApiServiceProvider =
    AutoDisposeProvider<MangaDexApiService>.internal(
  mangaDexApiService,
  name: r'mangaDexApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mangaDexApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MangaDexApiServiceRef = AutoDisposeProviderRef<MangaDexApiService>;
String _$appDatabaseHash() => r'4db1c5efe1a73afafa926c6e91d12e49a68b1abc';

/// See also [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = AutoDisposeProvider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = AutoDisposeProviderRef<AppDatabase>;
String _$localProgressServiceHash() =>
    r'feab1b61a3a04163268b54e7471d331b53e2e3ac';

/// See also [localProgressService].
@ProviderFor(localProgressService)
final localProgressServiceProvider =
    AutoDisposeFutureProvider<LocalProgressService>.internal(
  localProgressService,
  name: r'localProgressServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localProgressServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocalProgressServiceRef
    = AutoDisposeFutureProviderRef<LocalProgressService>;
String _$downloadServiceHash() => r'92071e3c1bcfabb39c54abc59826c16241bf57d0';

/// See also [downloadService].
@ProviderFor(downloadService)
final downloadServiceProvider = AutoDisposeProvider<DownloadService>.internal(
  downloadService,
  name: r'downloadServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$downloadServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DownloadServiceRef = AutoDisposeProviderRef<DownloadService>;
String _$chapterDownloadStatusHash() =>
    r'd04d094733653df41924b7f910fb795e16572e3d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [chapterDownloadStatus].
@ProviderFor(chapterDownloadStatus)
const chapterDownloadStatusProvider = ChapterDownloadStatusFamily();

/// See also [chapterDownloadStatus].
class ChapterDownloadStatusFamily
    extends Family<AsyncValue<ChapterDownloadStatus>> {
  /// See also [chapterDownloadStatus].
  const ChapterDownloadStatusFamily();

  /// See also [chapterDownloadStatus].
  ChapterDownloadStatusProvider call(
    String mangaId,
    String chapterId,
  ) {
    return ChapterDownloadStatusProvider(
      mangaId,
      chapterId,
    );
  }

  @override
  ChapterDownloadStatusProvider getProviderOverride(
    covariant ChapterDownloadStatusProvider provider,
  ) {
    return call(
      provider.mangaId,
      provider.chapterId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chapterDownloadStatusProvider';
}

/// See also [chapterDownloadStatus].
class ChapterDownloadStatusProvider
    extends AutoDisposeFutureProvider<ChapterDownloadStatus> {
  /// See also [chapterDownloadStatus].
  ChapterDownloadStatusProvider(
    String mangaId,
    String chapterId,
  ) : this._internal(
          (ref) => chapterDownloadStatus(
            ref as ChapterDownloadStatusRef,
            mangaId,
            chapterId,
          ),
          from: chapterDownloadStatusProvider,
          name: r'chapterDownloadStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chapterDownloadStatusHash,
          dependencies: ChapterDownloadStatusFamily._dependencies,
          allTransitiveDependencies:
              ChapterDownloadStatusFamily._allTransitiveDependencies,
          mangaId: mangaId,
          chapterId: chapterId,
        );

  ChapterDownloadStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mangaId,
    required this.chapterId,
  }) : super.internal();

  final String mangaId;
  final String chapterId;

  @override
  Override overrideWith(
    FutureOr<ChapterDownloadStatus> Function(ChapterDownloadStatusRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChapterDownloadStatusProvider._internal(
        (ref) => create(ref as ChapterDownloadStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mangaId: mangaId,
        chapterId: chapterId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChapterDownloadStatus> createElement() {
    return _ChapterDownloadStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChapterDownloadStatusProvider &&
        other.mangaId == mangaId &&
        other.chapterId == chapterId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mangaId.hashCode);
    hash = _SystemHash.combine(hash, chapterId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChapterDownloadStatusRef
    on AutoDisposeFutureProviderRef<ChapterDownloadStatus> {
  /// The parameter `mangaId` of this provider.
  String get mangaId;

  /// The parameter `chapterId` of this provider.
  String get chapterId;
}

class _ChapterDownloadStatusProviderElement
    extends AutoDisposeFutureProviderElement<ChapterDownloadStatus>
    with ChapterDownloadStatusRef {
  _ChapterDownloadStatusProviderElement(super.provider);

  @override
  String get mangaId => (origin as ChapterDownloadStatusProvider).mangaId;
  @override
  String get chapterId => (origin as ChapterDownloadStatusProvider).chapterId;
}

String _$chapterDownloadStatusStreamHash() =>
    r'52a028c5e9dce10c2d54234f50c26b8a22c93993';

/// See also [chapterDownloadStatusStream].
@ProviderFor(chapterDownloadStatusStream)
const chapterDownloadStatusStreamProvider = ChapterDownloadStatusStreamFamily();

/// See also [chapterDownloadStatusStream].
class ChapterDownloadStatusStreamFamily
    extends Family<AsyncValue<ChapterDownloadStatus>> {
  /// See also [chapterDownloadStatusStream].
  const ChapterDownloadStatusStreamFamily();

  /// See also [chapterDownloadStatusStream].
  ChapterDownloadStatusStreamProvider call(
    String mangaId,
    String chapterId,
  ) {
    return ChapterDownloadStatusStreamProvider(
      mangaId,
      chapterId,
    );
  }

  @override
  ChapterDownloadStatusStreamProvider getProviderOverride(
    covariant ChapterDownloadStatusStreamProvider provider,
  ) {
    return call(
      provider.mangaId,
      provider.chapterId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chapterDownloadStatusStreamProvider';
}

/// See also [chapterDownloadStatusStream].
class ChapterDownloadStatusStreamProvider
    extends AutoDisposeStreamProvider<ChapterDownloadStatus> {
  /// See also [chapterDownloadStatusStream].
  ChapterDownloadStatusStreamProvider(
    String mangaId,
    String chapterId,
  ) : this._internal(
          (ref) => chapterDownloadStatusStream(
            ref as ChapterDownloadStatusStreamRef,
            mangaId,
            chapterId,
          ),
          from: chapterDownloadStatusStreamProvider,
          name: r'chapterDownloadStatusStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chapterDownloadStatusStreamHash,
          dependencies: ChapterDownloadStatusStreamFamily._dependencies,
          allTransitiveDependencies:
              ChapterDownloadStatusStreamFamily._allTransitiveDependencies,
          mangaId: mangaId,
          chapterId: chapterId,
        );

  ChapterDownloadStatusStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mangaId,
    required this.chapterId,
  }) : super.internal();

  final String mangaId;
  final String chapterId;

  @override
  Override overrideWith(
    Stream<ChapterDownloadStatus> Function(
            ChapterDownloadStatusStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChapterDownloadStatusStreamProvider._internal(
        (ref) => create(ref as ChapterDownloadStatusStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mangaId: mangaId,
        chapterId: chapterId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<ChapterDownloadStatus> createElement() {
    return _ChapterDownloadStatusStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChapterDownloadStatusStreamProvider &&
        other.mangaId == mangaId &&
        other.chapterId == chapterId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mangaId.hashCode);
    hash = _SystemHash.combine(hash, chapterId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChapterDownloadStatusStreamRef
    on AutoDisposeStreamProviderRef<ChapterDownloadStatus> {
  /// The parameter `mangaId` of this provider.
  String get mangaId;

  /// The parameter `chapterId` of this provider.
  String get chapterId;
}

class _ChapterDownloadStatusStreamProviderElement
    extends AutoDisposeStreamProviderElement<ChapterDownloadStatus>
    with ChapterDownloadStatusStreamRef {
  _ChapterDownloadStatusStreamProviderElement(super.provider);

  @override
  String get mangaId => (origin as ChapterDownloadStatusStreamProvider).mangaId;
  @override
  String get chapterId =>
      (origin as ChapterDownloadStatusStreamProvider).chapterId;
}

String _$downloadedChapterHash() => r'386aec43d6acd5f6461315ff3d252af008a60242';

/// See also [downloadedChapter].
@ProviderFor(downloadedChapter)
const downloadedChapterProvider = DownloadedChapterFamily();

/// See also [downloadedChapter].
class DownloadedChapterFamily extends Family<AsyncValue<DownloadedChapter?>> {
  /// See also [downloadedChapter].
  const DownloadedChapterFamily();

  /// See also [downloadedChapter].
  DownloadedChapterProvider call(
    String chapterId,
  ) {
    return DownloadedChapterProvider(
      chapterId,
    );
  }

  @override
  DownloadedChapterProvider getProviderOverride(
    covariant DownloadedChapterProvider provider,
  ) {
    return call(
      provider.chapterId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'downloadedChapterProvider';
}

/// See also [downloadedChapter].
class DownloadedChapterProvider
    extends AutoDisposeFutureProvider<DownloadedChapter?> {
  /// See also [downloadedChapter].
  DownloadedChapterProvider(
    String chapterId,
  ) : this._internal(
          (ref) => downloadedChapter(
            ref as DownloadedChapterRef,
            chapterId,
          ),
          from: downloadedChapterProvider,
          name: r'downloadedChapterProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$downloadedChapterHash,
          dependencies: DownloadedChapterFamily._dependencies,
          allTransitiveDependencies:
              DownloadedChapterFamily._allTransitiveDependencies,
          chapterId: chapterId,
        );

  DownloadedChapterProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chapterId,
  }) : super.internal();

  final String chapterId;

  @override
  Override overrideWith(
    FutureOr<DownloadedChapter?> Function(DownloadedChapterRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DownloadedChapterProvider._internal(
        (ref) => create(ref as DownloadedChapterRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chapterId: chapterId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DownloadedChapter?> createElement() {
    return _DownloadedChapterProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DownloadedChapterProvider && other.chapterId == chapterId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chapterId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DownloadedChapterRef on AutoDisposeFutureProviderRef<DownloadedChapter?> {
  /// The parameter `chapterId` of this provider.
  String get chapterId;
}

class _DownloadedChapterProviderElement
    extends AutoDisposeFutureProviderElement<DownloadedChapter?>
    with DownloadedChapterRef {
  _DownloadedChapterProviderElement(super.provider);

  @override
  String get chapterId => (origin as DownloadedChapterProvider).chapterId;
}

String _$downloadedChapterIdsForMangaHash() =>
    r'990955aff8c8df53a25562a9537a6d11503f43cb';

/// See also [downloadedChapterIdsForManga].
@ProviderFor(downloadedChapterIdsForManga)
const downloadedChapterIdsForMangaProvider =
    DownloadedChapterIdsForMangaFamily();

/// See also [downloadedChapterIdsForManga].
class DownloadedChapterIdsForMangaFamily
    extends Family<AsyncValue<Set<String>>> {
  /// See also [downloadedChapterIdsForManga].
  const DownloadedChapterIdsForMangaFamily();

  /// See also [downloadedChapterIdsForManga].
  DownloadedChapterIdsForMangaProvider call(
    String mangaId,
  ) {
    return DownloadedChapterIdsForMangaProvider(
      mangaId,
    );
  }

  @override
  DownloadedChapterIdsForMangaProvider getProviderOverride(
    covariant DownloadedChapterIdsForMangaProvider provider,
  ) {
    return call(
      provider.mangaId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'downloadedChapterIdsForMangaProvider';
}

/// See also [downloadedChapterIdsForManga].
class DownloadedChapterIdsForMangaProvider
    extends AutoDisposeFutureProvider<Set<String>> {
  /// See also [downloadedChapterIdsForManga].
  DownloadedChapterIdsForMangaProvider(
    String mangaId,
  ) : this._internal(
          (ref) => downloadedChapterIdsForManga(
            ref as DownloadedChapterIdsForMangaRef,
            mangaId,
          ),
          from: downloadedChapterIdsForMangaProvider,
          name: r'downloadedChapterIdsForMangaProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$downloadedChapterIdsForMangaHash,
          dependencies: DownloadedChapterIdsForMangaFamily._dependencies,
          allTransitiveDependencies:
              DownloadedChapterIdsForMangaFamily._allTransitiveDependencies,
          mangaId: mangaId,
        );

  DownloadedChapterIdsForMangaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mangaId,
  }) : super.internal();

  final String mangaId;

  @override
  Override overrideWith(
    FutureOr<Set<String>> Function(DownloadedChapterIdsForMangaRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DownloadedChapterIdsForMangaProvider._internal(
        (ref) => create(ref as DownloadedChapterIdsForMangaRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mangaId: mangaId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Set<String>> createElement() {
    return _DownloadedChapterIdsForMangaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DownloadedChapterIdsForMangaProvider &&
        other.mangaId == mangaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mangaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DownloadedChapterIdsForMangaRef
    on AutoDisposeFutureProviderRef<Set<String>> {
  /// The parameter `mangaId` of this provider.
  String get mangaId;
}

class _DownloadedChapterIdsForMangaProviderElement
    extends AutoDisposeFutureProviderElement<Set<String>>
    with DownloadedChapterIdsForMangaRef {
  _DownloadedChapterIdsForMangaProviderElement(super.provider);

  @override
  String get mangaId =>
      (origin as DownloadedChapterIdsForMangaProvider).mangaId;
}

String _$downloadedBytesForMangaHash() =>
    r'e45e8c41b781fb9e71df22ae8c9fe7b5a70ecdc8';

/// See also [downloadedBytesForManga].
@ProviderFor(downloadedBytesForManga)
const downloadedBytesForMangaProvider = DownloadedBytesForMangaFamily();

/// See also [downloadedBytesForManga].
class DownloadedBytesForMangaFamily extends Family<AsyncValue<int>> {
  /// See also [downloadedBytesForManga].
  const DownloadedBytesForMangaFamily();

  /// See also [downloadedBytesForManga].
  DownloadedBytesForMangaProvider call(
    String mangaId,
  ) {
    return DownloadedBytesForMangaProvider(
      mangaId,
    );
  }

  @override
  DownloadedBytesForMangaProvider getProviderOverride(
    covariant DownloadedBytesForMangaProvider provider,
  ) {
    return call(
      provider.mangaId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'downloadedBytesForMangaProvider';
}

/// See also [downloadedBytesForManga].
class DownloadedBytesForMangaProvider extends AutoDisposeFutureProvider<int> {
  /// See also [downloadedBytesForManga].
  DownloadedBytesForMangaProvider(
    String mangaId,
  ) : this._internal(
          (ref) => downloadedBytesForManga(
            ref as DownloadedBytesForMangaRef,
            mangaId,
          ),
          from: downloadedBytesForMangaProvider,
          name: r'downloadedBytesForMangaProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$downloadedBytesForMangaHash,
          dependencies: DownloadedBytesForMangaFamily._dependencies,
          allTransitiveDependencies:
              DownloadedBytesForMangaFamily._allTransitiveDependencies,
          mangaId: mangaId,
        );

  DownloadedBytesForMangaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mangaId,
  }) : super.internal();

  final String mangaId;

  @override
  Override overrideWith(
    FutureOr<int> Function(DownloadedBytesForMangaRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DownloadedBytesForMangaProvider._internal(
        (ref) => create(ref as DownloadedBytesForMangaRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mangaId: mangaId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _DownloadedBytesForMangaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DownloadedBytesForMangaProvider && other.mangaId == mangaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mangaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DownloadedBytesForMangaRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `mangaId` of this provider.
  String get mangaId;
}

class _DownloadedBytesForMangaProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with DownloadedBytesForMangaRef {
  _DownloadedBytesForMangaProviderElement(super.provider);

  @override
  String get mangaId => (origin as DownloadedBytesForMangaProvider).mangaId;
}

String _$mangaIdsWithDownloadsHash() =>
    r'65d789ea738738a0b5c91ebebf3ed3778a3c51bf';

/// See also [mangaIdsWithDownloads].
@ProviderFor(mangaIdsWithDownloads)
final mangaIdsWithDownloadsProvider =
    AutoDisposeFutureProvider<Set<String>>.internal(
  mangaIdsWithDownloads,
  name: r'mangaIdsWithDownloadsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mangaIdsWithDownloadsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MangaIdsWithDownloadsRef = AutoDisposeFutureProviderRef<Set<String>>;
String _$atHomeServerHash() => r'90bb36633d7153db3f323e600977eb8f754f4e39';

/// See also [atHomeServer].
@ProviderFor(atHomeServer)
const atHomeServerProvider = AtHomeServerFamily();

/// See also [atHomeServer].
class AtHomeServerFamily extends Family<AsyncValue<AtHomeServer>> {
  /// See also [atHomeServer].
  const AtHomeServerFamily();

  /// See also [atHomeServer].
  AtHomeServerProvider call(
    String chapterId,
  ) {
    return AtHomeServerProvider(
      chapterId,
    );
  }

  @override
  AtHomeServerProvider getProviderOverride(
    covariant AtHomeServerProvider provider,
  ) {
    return call(
      provider.chapterId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'atHomeServerProvider';
}

/// See also [atHomeServer].
class AtHomeServerProvider extends AutoDisposeFutureProvider<AtHomeServer> {
  /// See also [atHomeServer].
  AtHomeServerProvider(
    String chapterId,
  ) : this._internal(
          (ref) => atHomeServer(
            ref as AtHomeServerRef,
            chapterId,
          ),
          from: atHomeServerProvider,
          name: r'atHomeServerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$atHomeServerHash,
          dependencies: AtHomeServerFamily._dependencies,
          allTransitiveDependencies:
              AtHomeServerFamily._allTransitiveDependencies,
          chapterId: chapterId,
        );

  AtHomeServerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chapterId,
  }) : super.internal();

  final String chapterId;

  @override
  Override overrideWith(
    FutureOr<AtHomeServer> Function(AtHomeServerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AtHomeServerProvider._internal(
        (ref) => create(ref as AtHomeServerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chapterId: chapterId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AtHomeServer> createElement() {
    return _AtHomeServerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AtHomeServerProvider && other.chapterId == chapterId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chapterId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AtHomeServerRef on AutoDisposeFutureProviderRef<AtHomeServer> {
  /// The parameter `chapterId` of this provider.
  String get chapterId;
}

class _AtHomeServerProviderElement
    extends AutoDisposeFutureProviderElement<AtHomeServer>
    with AtHomeServerRef {
  _AtHomeServerProviderElement(super.provider);

  @override
  String get chapterId => (origin as AtHomeServerProvider).chapterId;
}

String _$mangaHash() => r'39de7003550875269d2f845f2db3d20f523c5493';

/// See also [manga].
@ProviderFor(manga)
const mangaProvider = MangaFamily();

/// See also [manga].
class MangaFamily extends Family<AsyncValue<Manga>> {
  /// See also [manga].
  const MangaFamily();

  /// See also [manga].
  MangaProvider call(
    String mangaId,
  ) {
    return MangaProvider(
      mangaId,
    );
  }

  @override
  MangaProvider getProviderOverride(
    covariant MangaProvider provider,
  ) {
    return call(
      provider.mangaId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'mangaProvider';
}

/// See also [manga].
class MangaProvider extends AutoDisposeFutureProvider<Manga> {
  /// See also [manga].
  MangaProvider(
    String mangaId,
  ) : this._internal(
          (ref) => manga(
            ref as MangaRef,
            mangaId,
          ),
          from: mangaProvider,
          name: r'mangaProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$mangaHash,
          dependencies: MangaFamily._dependencies,
          allTransitiveDependencies: MangaFamily._allTransitiveDependencies,
          mangaId: mangaId,
        );

  MangaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mangaId,
  }) : super.internal();

  final String mangaId;

  @override
  Override overrideWith(
    FutureOr<Manga> Function(MangaRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MangaProvider._internal(
        (ref) => create(ref as MangaRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mangaId: mangaId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Manga> createElement() {
    return _MangaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MangaProvider && other.mangaId == mangaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mangaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MangaRef on AutoDisposeFutureProviderRef<Manga> {
  /// The parameter `mangaId` of this provider.
  String get mangaId;
}

class _MangaProviderElement extends AutoDisposeFutureProviderElement<Manga>
    with MangaRef {
  _MangaProviderElement(super.provider);

  @override
  String get mangaId => (origin as MangaProvider).mangaId;
}

String _$chapterFeedHash() => r'a555a571aed100675c7ff652a5793f46f0005504';

/// Fetches all chapters for [mangaId], paginating internally (max 500/request).
/// Chapters are returned in API order (ascending by chapter number).
///
/// Copied from [chapterFeed].
@ProviderFor(chapterFeed)
const chapterFeedProvider = ChapterFeedFamily();

/// Fetches all chapters for [mangaId], paginating internally (max 500/request).
/// Chapters are returned in API order (ascending by chapter number).
///
/// Copied from [chapterFeed].
class ChapterFeedFamily extends Family<AsyncValue<List<Chapter>>> {
  /// Fetches all chapters for [mangaId], paginating internally (max 500/request).
  /// Chapters are returned in API order (ascending by chapter number).
  ///
  /// Copied from [chapterFeed].
  const ChapterFeedFamily();

  /// Fetches all chapters for [mangaId], paginating internally (max 500/request).
  /// Chapters are returned in API order (ascending by chapter number).
  ///
  /// Copied from [chapterFeed].
  ChapterFeedProvider call(
    String mangaId,
  ) {
    return ChapterFeedProvider(
      mangaId,
    );
  }

  @override
  ChapterFeedProvider getProviderOverride(
    covariant ChapterFeedProvider provider,
  ) {
    return call(
      provider.mangaId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chapterFeedProvider';
}

/// Fetches all chapters for [mangaId], paginating internally (max 500/request).
/// Chapters are returned in API order (ascending by chapter number).
///
/// Copied from [chapterFeed].
class ChapterFeedProvider extends AutoDisposeFutureProvider<List<Chapter>> {
  /// Fetches all chapters for [mangaId], paginating internally (max 500/request).
  /// Chapters are returned in API order (ascending by chapter number).
  ///
  /// Copied from [chapterFeed].
  ChapterFeedProvider(
    String mangaId,
  ) : this._internal(
          (ref) => chapterFeed(
            ref as ChapterFeedRef,
            mangaId,
          ),
          from: chapterFeedProvider,
          name: r'chapterFeedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chapterFeedHash,
          dependencies: ChapterFeedFamily._dependencies,
          allTransitiveDependencies:
              ChapterFeedFamily._allTransitiveDependencies,
          mangaId: mangaId,
        );

  ChapterFeedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mangaId,
  }) : super.internal();

  final String mangaId;

  @override
  Override overrideWith(
    FutureOr<List<Chapter>> Function(ChapterFeedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChapterFeedProvider._internal(
        (ref) => create(ref as ChapterFeedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mangaId: mangaId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Chapter>> createElement() {
    return _ChapterFeedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChapterFeedProvider && other.mangaId == mangaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mangaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChapterFeedRef on AutoDisposeFutureProviderRef<List<Chapter>> {
  /// The parameter `mangaId` of this provider.
  String get mangaId;
}

class _ChapterFeedProviderElement
    extends AutoDisposeFutureProviderElement<List<Chapter>>
    with ChapterFeedRef {
  _ChapterFeedProviderElement(super.provider);

  @override
  String get mangaId => (origin as ChapterFeedProvider).mangaId;
}

String _$mangaSearchHash() => r'b2a7521e593a96336d21374dc66ad4e494b13a2b';

/// See also [MangaSearch].
@ProviderFor(MangaSearch)
final mangaSearchProvider =
    AutoDisposeAsyncNotifierProvider<MangaSearch, MangaSearchState>.internal(
  MangaSearch.new,
  name: r'mangaSearchProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mangaSearchHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MangaSearch = AutoDisposeAsyncNotifier<MangaSearchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
