# Manga Portal — Feature Roadmap

Features are implemented one at a time in order. Each feature ships with accompanying tests before moving on. Do not begin a feature until all tests from the previous feature pass.

---

## Feature 0 — Project Infrastructure ✅

**Goal**: Establish the foundation every subsequent feature builds on.

### Tasks

- [x] Add packages to `pubspec.yaml`:
  - `flutter_riverpod`, `riverpod_annotation` — state management
  - `go_router` — navigation
  - `dio` — HTTP client
  - `cached_network_image` — image caching
  - `shared_preferences` — local progress + library + settings storage
  - `flutter_secure_storage` — auth token storage (used in Deferred Feature 1)
  - `build_runner`, `riverpod_generator` — code generation (dev)
- [x] Run `flutter pub get`
- [x] Create `lib/app.dart`:
  - Define all named `GoRouter` routes
  - Wrap with `ProviderScope`
  - `ShellRoute` for the 3 bottom-nav tabs
- [x] Update `lib/main.dart`:
  - Replace `MaterialApp` with `MaterialApp.router` using the router from `app.dart`
  - Wrap root with `ProviderScope`
  - Apply dark-first Material 3 theme (dark as `themeMode` default, both `theme` and `darkTheme` defined)
  - Fix `AnimatedSwitcher` duration bug: `microseconds: 1000` → `milliseconds: 300`
- [x] Replace `test/widget_test.dart` default counter test with a smoke test that verifies `MangaPortal` renders without throwing

### Tests

- Widget test: `test/widget/app_test.dart` — smoke test that `MangaPortal` renders and bottom nav is present

---

## Feature 1 — Steel Thread: Hardcoded Reader ✅

**Goal**: Navigate from the app to a working chapter reader using a hardcoded manga and chapter ID. Proves the full image-fetching pipeline works end-to-end before building any discovery features.

### Context

The at-home server flow:

1. `GET /at-home/server/:chapterId` → `{ baseUrl, chapter: { hash, data[], dataSaver[] } }`
2. Construct page URL: `{baseUrl}/data/{hash}/{filename}`
3. For non-`mangadex.org` base URLs, report each image fetch result to `https://api.mangadex.network/report`
4. On 403: re-fetch the at-home server endpoint to get a fresh base URL

### Tasks

- [x] Create `lib/models/chapter_pages.dart` — `AtHomeServer` model with `fromJson`
- [x] Create `lib/services/mangadex_api.dart` — `MangaDexApiService`:
  - Dio instance with `User-Agent: manga-portal/1.0` interceptor
  - `Future<AtHomeServer> fetchAtHomeServer(String chapterId)`
- [x] Create `lib/providers/api_providers.dart`:
  - `mangaDexApiServiceProvider` — provides `MangaDexApiService`
  - `atHomeServerProvider(chapterId)` — `FutureProvider` wrapping `fetchAtHomeServer`
- [x] Create `lib/widgets/reader_page_image.dart`:
  - `Image` widget backed by `CachedNetworkImageProvider` for a single page
  - Reports success/failure to `api.mangadex.network/report` when base URL is not from `mangadex.org`
  - On failure: notifies parent to refresh the at-home server URL
- [x] Create `lib/pages/reader_page.dart` — `ReaderPage(chapterId: String)`:
  - Watches `atHomeServerProvider`
  - Builds `PageView` of `ReaderPageImage` widgets (horizontal paged, left-to-right)
  - Shows `CircularProgressIndicator` while loading
  - Shows human-readable error + retry button on failure
  - Preloads adjacent pages: immediate window (3 ahead, 1 behind) fired concurrently; background sequential preload for the entire chapter in distance order from current page
- [x] Add a temporary "Open Reader" button to `LibraryPage` with a hardcoded chapter ID pointing to a known-good MangaDex chapter

### Tests

- [x] Widget test: `test/widget/reader_page_test.dart`
  - Happy path: mock `atHomeServerProvider`, verify `PageView` and page images render
  - Loading state: verify `CircularProgressIndicator` shown while provider is loading
  - Error state: verify error message + retry button shown when provider throws
- [x] Integration test: `integration_test/reader_flow_test.dart`
  - Tap "Open Reader" button → `ReaderPage` navigates and loads pages (mocked HTTP)

---

## Feature 2 — Manga Detail Page & Real Chapter Navigation ✅

**Goal**: Replace the hardcoded chapter ID with real manga browsing. A detail page shows manga info and its chapter list; tapping a chapter opens the reader.

### Tasks

- [x] Create `lib/models/manga.dart` — `Manga`, `MangaAttributes`, `CoverArt` with `fromJson`
- [x] Create `lib/models/chapter.dart` — `Chapter`, `ChapterAttributes` with `fromJson`
  - `chapterNumber` must be `String?` — can be `null` (oneshots), `"1.5"` (bonus chapters), or absent. Never parse as a number.
  - Store scanlation group ID and name from the chapter's `scanlation_group` relationship
- [x] Add to `MangaDexApiService`:
  - `Future<Manga> fetchManga(String mangaId)` — `GET /manga/:id?includes[]=cover_art`
  - `Future<List<Chapter>> fetchChapterFeed(String mangaId, {int offset = 0})` — `GET /manga/:id/feed` with **no language filter** (fetch all languages so the UI can show availability), `includes[]=scanlation_group`, sorted by chapter ascending, up to 500 per page
- [x] Add to `api_providers.dart`:
  - `mangaProvider(mangaId)` — `FutureProvider`
  - `chapterFeedProvider(mangaId)` — paginated `FutureProvider`; fetches all languages (handles internal pagination) and groups chapters by chapter number client-side
- [x] Create `lib/widgets/manga_card.dart` — cover image + title, used in both detail and search
- [x] Create `lib/widgets/chapter_list_tile.dart` — one tile per unique chapter number:
  - Chapters are grouped by `chapterNumber` (`String?`); each tile represents one chapter number across all its available versions
  - **One group in preferred language**: shows chapter number, title, group name, date; tap opens reader directly
  - **Multiple groups in preferred language**: shows chapter number and date; tap expands an inline drawer listing all available scanlation groups to choose from
  - **Not available in preferred language** (other languages only): shown in a subdued style with a note (e.g. "Not available in English"); non-interactive
- [x] Create `lib/pages/manga_detail_page.dart`:
  - 512px cover image, title, description, chapter list sorted by chapter number descending (newest first)
  - Renders one `ChapterListTile` per unique chapter number using grouped data from `chapterFeedProvider`
  - Tap single-group chapter → `context.push('/reader/:chapterId')`
  - Tap multi-group chapter → expand inline group picker drawer, then navigate on selection
- [x] Register `/manga/:mangaId` route in `app.dart`
- [x] Update `LibraryPage` stub button to navigate to a hardcoded manga detail page instead of directly to the reader
- [x] Remove hardcoded "Open Reader" button (replaced with "Open Manga Detail (test)")
- [x] Create `lib/providers/settings_provider.dart` — `Settings` with `preferredLanguage` and `contentRating` defaults (needed for chapter language filtering)

### Tests

- [x] Widget test: `test/widget/manga_detail_page_test.dart`
  - Renders manga title, description, and chapter list from mocked providers
  - Shows loading state
  - Shows manga error + retry button
  - Shows chapters error section independently
  - Unavailable-language chapters shown subdued
  - Multi-group chapter expands to show group list
- [x] Integration test: `integration_test/reader_flow_test.dart` (updated)
  - Navigate to detail page → chapter list appears → tap chapter → reader opens

---

## Feature 3 — Search Page ✅

**Goal**: Users can search for any manga by title and navigate to its detail page.

### Tasks

- [x] Add to `MangaDexApiService`:
  - `Future<List<Manga>> searchManga(String query, {int offset = 0, List<String> contentRating = const ['safe', 'suggestive']})` — `GET /manga?title=...&includes[]=cover_art&limit=20` with `contentRating[]` params
- [x] Add to `api_providers.dart`:
  - `mangaSearchProvider(query)` — `AsyncNotifier` with debounce, supports pagination; reads `contentRating` from `settingsProvider`
- [x] Implement `lib/pages/search_page.dart`:
  - Search `TextField` at top
  - Debounced search (300ms) on text change
  - Scrollable grid of `MangaCard` widgets
  - Loading indicator, empty state, error state
  - Tap card → `context.push('/manga/:mangaId')`
- [x] Remove `Placeholder` from `SearchPage`

### Tests

- Widget test: `test/widget/search_page_test.dart`
  - Search results render from mocked provider
  - Empty query shows empty state
  - Error shows human-readable message
- Integration test: `integration_test/search_flow_test.dart`
  - Type query → results appear → tap card → detail page loads

_All tasks and tests complete. Verified on emulator: real MangaDex search returns results, covers load, tapping a card navigates to the detail page._

---

## Feature 4 — Reading Progress & Reader Polish ✅

**Goal**: The reader remembers where you left off per chapter. Quality modes and reading direction are configurable. MangaDex@Home reporting is fully compliant.

### Tasks

- [x] Create `lib/services/local_progress.dart` — `LocalProgressService`:
  - `saveProgress(mangaId, chapterId, pageIndex)`
  - `getProgress(mangaId)` → `{chapterId, pageIndex}`
  - Uses `SharedPreferences` keys: `progress_{mangaId}_chapter`, `progress_{mangaId}_page`
- [x] Create `lib/providers/reader_provider.dart`:
  - `readerModeProvider` — paged vs vertical scroll per manga (persisted locally)
  - `imageQualityProvider` — data vs data-saver (from settings)
- [x] Update `ReaderPage`:
  - Now accepts `mangaId` and the full sorted chapter list in addition to `chapterId`, so it can determine next/prev chapters without extra API calls
  - On open: restore saved page index for this chapter
  - On page change: save progress via `LocalProgressService`; call `precacheImage` for 3 pages ahead and 1 behind at all times
  - On reaching the last page: show a **chapter transition page** (inline interstitial in the scroll sequence) displaying current and next chapter; swiping/scrolling past it loads the next chapter using the rules below
  - On swiping back from the first page: show a chapter transition page for the previous chapter
  - **Next/prev chapter auto-selection**:
    1. One group in preferred language → select automatically
    2. Multiple groups in preferred language → prefer same scanlation group as current chapter; otherwise pick at random
    3. Chapter number exists but not in preferred language → show **language unavailability page** (full-screen message with button to return to chapter select)
  - On chapter completion (swiping past the transition page): enqueue `POST /chapter/:id/read` for when auth is added
  - Support image quality toggle (data vs data-saver) from `imageQualityProvider`
- [x] Fully implement `ReaderPageImage` MD@Home reporting:
  - Track `bytes` and `duration` for each image load
  - `cached` = response `X-Cache` header starts with `"HIT"`
  - POST to `https://api.mangadex.network/report` for non-`mangadex.org` base URLs
  - On failure: signal parent to re-fetch at-home server before retry

### Tests

- [x] Widget test: `test/widget/reader_progress_test.dart`
  - Progress is saved on page change
  - Reader opens to saved page index
  - Swiping past the last page shows the chapter transition page
  - Swiping back from the first page shows the previous chapter transition page
  - Next chapter not in preferred language shows the language unavailability page
- [x] Integration test: `integration_test/reader_progress_flow_test.dart`
  - Open chapter at page 3, close, reopen — starts at page 3
  - Swipe past last page → transition page shown → swipe again → next chapter loads
  - Chapter state indicators ("Start" / "Continue" / "Read") reflect progress correctly
  - "Continue" button on detail page opens reader at the saved page
  - Opening a chapter without paging does not overwrite in-progress state
  - Clearing reading history from Settings resets all chapter progress

### Extras

- **`SettingsPage` — Clear reading history**: Added a "Clear reading history" action to the Settings page. Tapping it shows a confirmation dialog; on confirm, all `SharedPreferences` progress keys are cleared and a snackbar confirms the action.
- **Chapter state indicators on detail page**: `MangaDetailPage` displays per-chapter status badges — "Start Ch. X", "Continue Ch. X" (with saved page shown), and "Read" — reflecting the current `LocalProgressService` state. The primary action button at the top of the page mirrors the most recent in-progress or next unread chapter.
- **`_hasUserPaged` guard**: Progress is only written to `LocalProgressService` after the user has actively swiped at least once in the reader session. Opening a chapter and immediately closing it does not overwrite a previously saved page index.
- **Integration test infrastructure fixes**: Three bugs in the integration test suite were diagnosed and fixed:
  - `reader_flow_test.dart` page count assertion updated from `"1 / 2"` to `"1 / 5"` to match the mock server's 5-page chapters.
  - `goRouter` singleton navigation state leak between `testWidgets` calls fixed by adding `goRouter.go('/') + pumpAndSettle()` at the start of each test's navigation helper.
  - `SharedPreferences` state leak between `testWidgets` calls fixed by adding a `setUp(() async { prefs.clear() })` block.

---

## Feature 5 — Library Page ✅

**Goal**: Users can save manga to a local library and return to them quickly.

### Tasks

- [x] Create `lib/providers/library_provider.dart` — `LibraryNotifier` (`AsyncNotifier`):
  - Stores list of manga IDs + cached title + cached cover URL in `SharedPreferences`
  - `addManga(Manga)`, `removeManga(mangaId)`, `isInLibrary(mangaId)`
  - On `app.dart` startup: pre-populate from saved IDs
- [x] Update `MangaDetailPage`:
  - Add "Add to Library" / "Remove from Library" toggle button
- [x] Implement `lib/pages/library_page.dart`:
  - Grid of `MangaCard` widgets from library provider
  - Empty state when no manga saved
  - Tap card → detail page
  - Remove `Placeholder`

### Tests

- [x] Widget test: `test/widget/library_page_test.dart`
  - Library grid renders saved manga
  - Empty state shows when no manga saved
- [x] Integration test: `integration_test/library_flow_test.dart`
  - Add manga from detail page → appears in library → tap → navigates to detail

### Extras

- **Persistent top bar**: The detail page uses a standard `AppBar` (always pinned) with the back button and bookmark icon clearly visible above the cover art, eliminating the issue of buttons being hard to see when overlaid on cover images.
- **Frosted-glass title strip**: The manga title is rendered at the bottom of the cover image on a `BackdropFilter`-blurred semi-transparent strip, keeping it legible regardless of the artwork behind it.
- **`clearSnackBars()` pattern**: Every snackbar is shown with `..clearSnackBars()..showSnackBar(...)` to prevent queue conflicts when adding and removing in quick succession.
- **Integration test runner fix**: Added per-file sequential execution to `tool/run_integration_tests.dart` and `tool/run_all_tests.dart` to prevent parallel APK installs from killing in-progress test sessions on the shared device.

---

## Feature 6 — Settings Page ✅

**Goal**: Users can configure language, image quality, and theme.

### Tasks

- [x] Create `lib/providers/settings_provider.dart` — `SettingsNotifier` (sync `Notifier<Settings>`):
  - `preferredLanguage` (default: `'en'`) — stored in `SharedPreferences`
  - `maxContentRating` (default: `'suggestive'`) — stored in `SharedPreferences`; `contentRating` computed getter returns all tiers at or below the max
  - `imageQuality` (`data` or `data-saver`) — stored in `SharedPreferences`
  - `themeMode` (`system` / `light` / `dark`) — stored in `SharedPreferences`
- [x] Update `main.dart` to read `themeMode` from `settingsNotifierProvider`
- [x] API calls already use `settings.contentRating` (computed getter) — no changes needed
- [x] Implement `lib/pages/settings_page.dart`:
  - Theme dropdown (System / Light / Dark)
  - Language dropdown (13 languages)
  - Max content rating dropdown (Safe / Suggestive / Erotica / Pornographic)
  - Image quality `SegmentedButton` (Full / Data saver)
  - "Clear reading history" tile with confirmation dialog
  - Remove `Placeholder`

### Tests

- [x] Widget test: `test/widget/settings_page_test.dart` (5 tests)
  - Settings render with correct initial values
  - Reflects non-default settings
  - Quality segmented button switches imageQuality
  - Content rating dropdown shows all tier options
  - Language dropdown shows available languages
- [x] Integration test: `integration_test/settings_flow_test.dart` (3 tests)
  - Settings page renders all sections
  - Change quality setting → opens reader → data-saver URLs confirmed in mock server logs
  - Language setting persists across navigation

### Extras

- **Max content rating as a cascade**: Rather than a multi-select checklist, content rating uses a single "maximum allowed" dropdown. Selecting "Suggestive" automatically includes Safe + Suggestive. The `contentRating` getter on `Settings` computes the list from `_ratingOrder`, keeping all API call sites unchanged.
- **Sync notifier with async init**: `SettingsNotifier` is a sync `Notifier<Settings>` so all existing `ref.watch(settingsNotifierProvider)` call sites continue working without destructuring. `build()` returns defaults synchronously and `_loadFromPrefs()` updates state asynchronously on first build.

---

## Feature 7 — Vertical Scroll (Webtoon) Mode ✅

**Goal**: Support vertical continuous scroll in addition to horizontal paged reading. Users set a preferred mode per series (stored locally).

### Tasks

- [x] Add per-manga reading direction to `LocalProgressService`:
  - `saveReadingMode(mangaId, ReadingMode mode)`
  - `getReadingMode(mangaId)` → `ReadingMode` (defaults to paged)
- [x] Update `ReaderPage`:
  - Check `readingModeProvider(mangaId)` on load
  - Paged mode: `PageView` (existing)
  - Vertical mode: `ListView` of `ReaderPageImage` widgets; track visible page for progress saving
- [x] Add reading mode toggle button in reader app bar
- [x] Add reading mode selector on `MangaDetailPage` (sets default for that series)

### Tests

- Widget test: `test/widget/reader_modes_test.dart`
  - Paged mode renders `PageView`
  - Vertical mode renders `ListView`
  - Mode toggle switches between them
- Integration test: `integration_test/reader_modes_flow_test.dart`
  - Set vertical mode on detail page → open reader → scrolls vertically

### Extras

- `ReadingModeNotifier` is a sync `Notifier<String>` that returns `'paged'` immediately and asynchronously loads the persisted preference in `build()` — no loading spinner for mode state.
- Scroll mode tracks reading progress via a `ScrollController` listener, estimating the current page from scroll fraction and marking the chapter read when 95% scrolled.
- A 70%-screen-height footer slot in scroll mode acts as the chapter transition interstitial, keeping the scroll-to-next-chapter flow consistent with paged mode.
- Storage key `reading_mode_{mangaId}` is intentionally excluded from `clearAllProgress()` — reading mode is a preference, not history.

---

## Feature 8 — Reader Info Bars & Settings Drawer ✅

**Goal**: Replace the always-visible static reader chrome with auto-hiding top and bottom info bars, and move reading mode configuration into a bottom drawer accessible from the reader.

### Tasks

- [x] Add visibility state to `ReaderPage` (bool `_barsVisible`, toggled on tap anywhere outside the bars)
- [x] Top bar (animated slide in/out from top):
  - Back button (pops the route)
  - Title: `"{chapter number}: {chapter name}"` — falls back to `"Chapter {number}"` when no title
  - Settings cog icon that opens the reader settings bottom sheet
- [x] Bottom bar (animated slide in/out from bottom):
  - "Prev" button — same behaviour as swiping past the first page (shows previous-chapter transition or does nothing on first chapter)
  - Centered page counter: `"{currentPage}/{totalPages}"`
  - "Next" button — same behaviour as swiping past the last page (shows next-chapter transition)
- [x] Auto-hide bars:
  - Paged mode: hide bars on any `PageView` page change
  - Scroll mode: hide bars when the user starts scrolling vertically
- [x] Tap-to-toggle: tapping anywhere in the reader that is NOT one of the bars toggles visibility
- [x] Reader settings bottom sheet (opened from the cog):
  - Reading mode selector — a `SegmentedButton` supporting `n` items (currently: Paged / Vertical); replaces the mode selector on `MangaDetailPage` and the toggle button in the AppBar
  - The `MangaDetailPage` reading mode selector and AppBar toggle button should be **removed** once the bottom sheet is in place
- [x] Bars and bottom sheet use `AnimatedSlide` + `AnimatedOpacity` (or equivalent) for smooth show/hide transitions

### Tests

- [x] Widget test: `test/widget/reader_modes_test.dart`
  - Bars are hidden on initial render
  - Tapping the reader body shows the bars
  - Tapping again hides the bars
  - Prev/Next buttons trigger chapter navigation callbacks
  - Settings cog opens the bottom sheet with the reading mode selector
- [x] Integration test: `integration_test/reader_modes_flow_test.dart`
  - Open reader → bars not visible → tap screen → bars appear → tap cog → bottom sheet with mode selector shown
  - Switch reading mode in bottom sheet → ListView / PageView rendered accordingly

### Extras

- Added three in-reader reading modes: `L->R`, `R->L`, and `Vertical/Scroll` in the reader settings sheet, replacing the old two-option selector and preserving per-series preference.
- Implemented full R->L page ordering (page 1 at far right, last page at far left), with transition-edge behavior and bottom bar button placement matched to direction (`Next` on left only in R->L).
- Direction switching now preserves the current logical page number when toggling between `L->R` and `R->L`.
- Reader settings control was resized to fit sheet width reliably on smaller screens so mode buttons no longer overflow.

---

## Feature 9 — Local Database Foundation ✅

**Goal**: Introduce a structured local database layer before offline downloads so download metadata, queue state, and file mapping are robust and queryable.

### Why this comes first

- Downloaded chapters need durable metadata: status (`queued/downloading/completed/failed`), progress, errors, file paths, and integrity checks.
- `SharedPreferences` is fine for small key/value settings but becomes brittle for queue orchestration and large offline libraries.
- A database-first foundation reduces rework when implementing pause/resume, cleanup, and "downloaded only" filtering.

### Tasks

- [x] Add DB package(s) in `pubspec.yaml` (`drift` + `sqlite3_flutter_libs` + build tooling) and run codegen.
- [x] Create local DB module (schema + DAOs) for:
  - manga table (id, title, cover url cache)
  - chapters table (id, mangaId, chapter number/title/language/group)
  - download jobs table (chapterId, status, progress, bytes, error, timestamps)
  - downloaded pages table (chapterId, page index, local file path, checksum/size)
  - Also: settings, library entries, manga progress, read chapters, reading modes tables
- [x] Add a storage abstraction service layer so providers/UI do not import DB directly.
- [x] Migrate progress persistence from SharedPreferences to Drift via `LocalProgressService`.
- [x] Add migration/versioning strategy for future schema changes.

### Tests

- [x] Widget smoke tests to ensure existing library/progress/settings behavior remains unchanged after backend swap.
- [x] All 29 widget tests pass with Drift-backed `LocalProgressService`; database queries validated.

### Extras

- **Removed legacy migration infrastructure**: Since the app was never published to public users, all `SharedPreferences`→Drift migration code and conditional fallback logic was removed. `LocalProgressService` now uses Drift exclusively — no dual-backend complexity.
- **In-memory test database**: Added `AppDatabase.forTesting()` factory for test isolation. Each test gets a fresh, isolated in-memory Drift database instance, ensuring test hermiticity.
- **Production-equivalent testing**: All widget tests now exercise the exact same Drift code path as production. Tests no longer use deprecated `SharedPreferences` constructor or legacy loaders — full feature parity between production and test execution.
- **Clean service API**: `LocalProgressService` is now a single-backend service with a simple constructor chain (`create()` factory loads from DB) and no nullable guards or conditional branching. All callers can assume Drift is always available.

---

## Feature 10 — Offline Chapter Downloads ✅

**Goal**: Let users download selected chapters to local storage and read them fully offline with zero network calls during reading.

### Tasks

- [x] Add download UI on `MangaDetailPage` and/or chapter rows:
  - queue/download/remove chapter
  - per-chapter status chip (Not downloaded / Queued / Downloading / Downloaded / Failed)
- [x] Implement `DownloadService`:
  - fetch chapter pages once and save image files under app documents storage
  - write all metadata/state to DB tables
  - bounded concurrency and retry/backoff on transient failures
  - mark completed only when all pages are present and validated
- [x] Reader offline-first resolution:
  - if chapter is downloaded, load local files only
  - do not call `at-home/server` or image network endpoints for downloaded chapters
  - fallback to online flow only when chapter is not downloaded
- [x] Add storage management:
  - remove one chapter download
  - remove all downloads for a manga
  - compute and display download size used
- [x] Add optional "Downloaded only" filter for library/detail chapter lists.

### Tests

- [x] Unit tests for download state machine and retry logic.
- [x] Widget tests for chapter download status rendering.
- [x] Integration test:
  - download chapter online
  - relaunch / disable network
  - open downloaded chapter and read pages with no network requests

---

## Feature 11 — Library Sections & Update Detection

**Goal**: Organize the library into "Continue Reading" and "The Shelf" sections with automatic detection of newly completed or updated manga, plus visual indicators for download status and new chapters.

### Context

**"Finished" status**: A manga is considered finished when the user reads the last chapter currently available in their preferred language.

**"Up" status**: A previously finished manga is "Up" if new chapters have been released in the user's preferred language since they last read. Detecting this requires a background check on library load.

**Section structure**:

- **Continue Reading**: Manga with in-progress reading (not yet finished), ordered by most recent read date (most recent first)
- **The Shelf**: Finished manga, ordered by most recent save date (can be made sortable later)
- Both sections merge by last-read-date if a finished manga becomes "Up"

### Tasks

- [ ] Add `finished_chapter_id` column to the manga progress table in `AppDatabase`:
  - `null` if not marked finished
  - Stores the chapter ID of the last chapter read when the user completes a series
- [ ] Add to `LocalProgressService`:
  - `finishManga(mangaId, lastChapterId)` — mark manga as finished
  - `isFinished(mangaId)` → bool
  - `getFinishedChapter(mangaId)` → chapterId
- [ ] Add to `DownloadService`:
  - `checkForUpdates(List<String> mangaIds, {Duration timeout = const Duration(seconds: 30)})` — fetch latest chapter feed for all given manga, compare with finished status, return list of manga IDs that are now "Up" (in preferred language only); store detected updates in a transient in-memory cache for this session
- [ ] Add "Check for new chapters on launch" setting to `SettingsNotifier`:
  - Three-state enum: `CheckForUpdates.always`, `CheckForUpdates.wifiOnly`, `CheckForUpdates.never`
  - Default: `CheckForUpdates.wifiOnly`
  - Persisted in `SharedPreferences`
  - Add conditional check for network type on app startup (if `wifiOnly`, skip if on cellular)
- [ ] Update `LibraryPage`:
  - On first build: if setting is not `never`, launch background `checkForUpdates()` for all finished manga
  - Display "Continue Reading" section (in-progress manga sorted by last read date, descending)
  - Display "The Shelf" section (finished manga, sorted by most recent save date, descending)
  - If any manga detected as "Up", show a short-lived toast (2 seconds) at the bottom: "New chapters available" — and reshuffle manga from Shelf back into Continue Reading (respecting last-read-date ordering)
  - If `checkForUpdates` times out or throws, silently ignore (no error toast)
- [ ] Add visual indicators on `MangaCard`:
  - **Download indicator** (top right): blue down-arrow icon in a rounded square background, shown if manga has any downloaded chapters
  - **Up indicator** (top left): green up-arrow icon in a rounded square background, shown if manga is "Up" (newly available chapters detected)
  - Both icons should have semi-transparent backgrounds (e.g., 80% opaque) so they are visible over any cover art color
- [ ] Update detail page chapter list:
  - When a user finishes the last chapter in their preferred language, automatically mark the manga as finished via `finishManga()`
  - Add a visual indicator next to the last-available chapter (e.g., a checkmark or "Latest" badge) so it's clear when reading the final chapter
- [ ] Update `SettingsPage`:
  - Add segmented button / radio group for "Check for new chapters on launch" with three options: Always / WiFi Only / Never
  - Persist selection immediately and respectfully

### Tests

- [ ] Widget test: `test/widget/library_organization_test.dart`
  - Library renders two sections: Continue Reading and The Shelf
  - In-progress manga appear in Continue Reading, sorted by last read date (most recent first)
  - Finished manga appear in The Shelf, sorted by most recent save date
  - Download indicator shown on manga with downloaded chapters
  - Up indicator shown on manga detected as "Up"
  - Toast appears when background update check finds new chapters
- [ ] Widget test: `test/widget/settings_update_check_test.dart`
  - Setting dropdown renders all three options and persists selection
  - Default is WiFi Only
- [ ] Integration test: `integration_test/library_sections_flow_test.dart`
  - Add manga to library, read some chapters (not all), verify it appears in Continue Reading
  - Read all chapters of that manga, verify it moves to The Shelf
  - Background check detects new chapters, manga moves back to Continue Reading with toast

### Extras

- **Deferred**: Sort order selector for "The Shelf" (most recent save, alphabetical, etc.) — can be added in a future iteration once the core structure is stable
- **Network type detection**: Uses `connectivity_plus` package (or similar) to differentiate WiFi from cellular. If unavailable or detection fails, treat as "always checking" to avoid silently skipping updates
- **Cache invalidation**: In-session "Up" status cache is cleared on resume (to pick up any manual refresh from settings), but not persisted to disk (fresh check on each app launch)

---

## Feature 12 — Explore Page & Discovery Lists

**Goal**: Replace the current Search tab with an Explore experience that still supports direct title search, but also exposes browse entry points for genres and curated discovery lists when the search field is empty.

### Context

- The bottom navigation tab should be renamed from **Search** to **Explore** and use a more browse-oriented icon.
- The search field remains at the top and keeps the current behavior: typing a query shows manga search results immediately.
- When the search field is empty, the page should show a simple vertical list of browse buttons with trailing chevrons.
- All browse/search flows must respect the user's configured maximum content rating.
- `Genre` is sourced from `GET /manga/tag`, filtered to tags whose `attributes.group` is exactly `genre`.
- `Search by tag` is intentionally deferred: this feature only adds a placeholder page for it so the navigation structure is in place.

### Tasks

- [ ] Rename the `SearchPage` concept in the UI to `ExplorePage`:
  - Update the bottom navigation label from `Search` to `Explore`
  - Replace the nav icon with a more discovery-oriented icon
  - Preserve the existing route path unless there is a clear reason to rename it internally
- [ ] Update the explore landing page behavior:
  - Keep the search bar pinned at the top
  - If the search field contains text, render the current manga search results behavior
  - If the search field is empty, render a vertical list of browse actions with trailing chevrons:
    - `Genre`
    - `Search by tag`
    - `Popular`
    - `Highly Rated`
    - `New`
    - `Recently Updated`
- [ ] Add tag-fetching support to `MangaDexApiService`:
  - Fetch the full tag list from `/manga/tag`
  - Expose a model/provider surface that can filter tags by `attributes.group`
  - Cache the fetched tag list in memory for the session to avoid redundant calls while browsing
- [ ] Add a `Genre` browse page:
  - Search bar at top with placeholder text `Search genres`
  - Show all tags where `attributes.group == 'genre'`
  - Sort genre buttons alphabetically by localized English tag name
  - Typing in the genre search field filters the visible buttons client-side
  - Tapping a genre opens a manga results page for that genre
- [ ] Add a reusable browse results page pattern:
  - Display manga in the same paginated grid style used by current search results
  - Support a page title matching the selected browse mode (`Popular`, `Highly Rated`, etc.)
  - Respect current content-rating filtering in every query
- [ ] Add browse queries for discovery lists:
  - `Popular` → `/manga` sorted with `order[followedCount]=desc`
  - `Highly Rated` → `/manga` sorted with `order[rating]=desc`
  - `New` → `/manga` sorted with `order[createdAt]=desc`
  - `Recently Updated` → `/manga` sorted with `order[latestUploadedChapter]=desc`
  - `Genre results` → `/manga` with `includedTags[]` for the selected genre tag ID
- [ ] Add a placeholder `Search by tag` page:
  - Reachable from the Explore landing page
  - Shows a simple `Coming soon` message
  - No real tag-search implementation yet; that remains the next feature
- [ ] Add/adjust routes in `app.dart` for:
  - Genre list page
  - Genre results page
  - Browse results pages (or one reusable results route)
  - Search-by-tag placeholder page

### Tests

- [ ] Widget test: `test/widget/explore_page_test.dart`
  - Empty search shows the browse action list
  - Entering text switches to manga search results
  - Bottom nav label shows `Explore`
- [ ] Widget test: `test/widget/genre_page_test.dart`
  - Only tags in the `genre` group are shown
  - Genres are sorted alphabetically
  - Genre search field filters the visible list client-side
- [ ] Widget test: `test/widget/discover_results_page_test.dart`
  - Popular / Highly Rated / New / Recently Updated pages render manga grids from mocked providers
  - Genre results page renders manga for the selected genre
  - Search-by-tag route renders `Coming soon`
- [ ] Integration test: `integration_test/explore_flow_test.dart`
  - Open Explore tab with empty search and see browse actions
  - Open Genre page, filter genres, tap one, and see manga results
  - Open Popular and verify sorted results page loads
  - Open Search by tag and see the placeholder page

### Extras

- **Future-ready route structure**: Keep the results-page implementation generic so the next feature can plug advanced tag filtering into the same browse results UI instead of creating a second, parallel flow.
- **Presentation intentionally simple for now**: The empty-state browse actions are a plain vertical list instead of card tiles so the feature focuses on behavior and navigation first.

---

## Feature 13 — Tag Search (Search by Tag)

**Goal**: Implement the `Search by tag` placeholder from Feature 12 into a fully functional tag-query builder that lets users include and exclude MangaDex tags, then browse matching manga in a results page that restores its tag state when the user navigates back.

### Layout (Option 2 — Two-Zone Composer)

The page uses two visible zones stacked vertically:

**Zone 1 — Query summary card** (always visible, not affected by filter):

- Shows included tags as green chips and excluded tags as red chips, each with an `✕` to remove
- A small summary line: `N included · N excluded`
- Does not scroll independently — collapses to compact if tall (capped, internally scrollable if needed)

**Zone 2 — Tag browser** (below the summary card):

- A filter text field at the top: `Filter tags...`
- A helper line: `Tap to include · tap again to exclude · tap once more to remove`
- Tags displayed as chips, sorted at all times in three groups in order: **Included** (green) → **Excluded** (red) → **Unselected** (neutral); alphabetically within each group
- Filter text only applies to the **unselected** group; included and excluded chips stay pinned in their groups at the top of the browser above the filter results
- Tapping an unselected chip → included (green); tapping included → excluded (red); tapping excluded → unselected (returned to bottom pool alphabetically)

**Bottom action bar** (always pinned):

- `Includes: AND | OR` segmented toggle — controls `includedTagsMode` sent to the API; excluded tags always use `OR` mode (API default)
  - Wrap this toggle in a clearly labeled region so it can be commented out in one block for A/B testing without touching surrounding code
- `[ Clear ]` (secondary color) — immediately unselects all tags, resets filter text
- `[ Search (N tags) ]` (primary color) — disabled until at least one tag is selected; shows count of total selected tags

### Results page behavior

- Navigating back from results restores the tag page in exactly the state it was left (included/excluded sets, filter text, AND/OR toggle value)
- State is session-only: persists only while staying within the Explore tab flow; cleared if the user leaves the Explore tab entirely or the app is killed
- Results page waits for the first API response before rendering anything (no skeleton/spinner mid-load)
- Once data arrives, show a count line at the top: `N manga found` (uses the `total` field from the API paginated response)
- Below the count, show the standard paginated manga grid
- All results respect the user's configured maximum content rating

### Alternate layout note (Option 3 — Sorted Chip Pool, for future A/B test)

User-proposed alternative to implement and compare separately:

- No separate query summary card at the top
- All tags live in a single pool, sorted dynamically: **Included (green)** → **Excluded (red)** → **Unselected (neutral)**, alphabetically within each group
- Tap cycle: unselected → green (included) → red (excluded) → unselected
- Filter only applies to the unselected group at the bottom; selected chips stay pinned at the top by sort order
- Same bottom action bar: AND/OR toggle, `Clear`, `Search`
- This layout trades the explicit query card for a unified view — simpler at a glance but less visually separated

### API details

- Tag list: reuse the cached `GET /manga/tag` result from Feature 12 (no extra call)
- Results query: `GET /manga` with `includedTags[]`, `excludedTags[]`, `includedTagsMode` (`AND` or `OR`), and `contentRating[]` from settings
- `excludedTagsMode` is always `OR` (API default; not exposed in UI)

### Tasks

- [ ] Remove the placeholder `Coming soon` content from the `Search by tag` route
- [ ] Create `lib/pages/tag_search_page.dart`:
  - Two-zone layout: query summary card + tag browser
  - Tap-cycle state machine per tag: `unselected → included → excluded → unselected`
  - Sort applied on every state change: included → excluded → unselected, alphabetical within each
  - Filter text field — affects only the unselected pool
  - `Clear` button resets all tag states and clears filter field
  - AND/OR segmented toggle for `includedTagsMode`; isolated in a labeled widget block for easy A/B removal
  - `Search` button enabled only when ≥ 1 tag selected; shows total selected count
- [ ] Session state: hold tag search state in a Riverpod notifier scoped to the Explore navigation stack; cleared when Explore tab is reset
- [ ] Create `lib/pages/tag_results_page.dart`:
  - Accepts included tag IDs, excluded tag IDs, and includedTagsMode as parameters
  - Waits for first API response before rendering
  - Shows `N manga found` count from API `total`
  - Standard paginated manga grid below the count
  - Back navigation returns to `TagSearchPage` with state intact (no re-init)
- [ ] Add `fetchTagSearchResults(...)` to `MangaDexApiService` (or reuse existing search with tag params)
- [ ] Register `TagResultsPage` route in `app.dart` (extra path params or query params for tag IDs and mode)

### Tests

- [ ] Widget test: `test/widget/tag_search_page_test.dart`
  - Tags render sorted: included → excluded → unselected, alphabetical within groups
  - Tap cycle correctly transitions unselected → included → excluded → unselected
  - Filter text only affects unselected chips; included/excluded chips stay visible
  - `Clear` button resets all selections and filter text
  - `Search` button disabled with zero selections; shows correct tag count when ≥ 1 selected
  - AND/OR toggle state changes `includedTagsMode`
- [ ] Widget test: `test/widget/tag_results_page_test.dart`
  - Page waits (empty) until data resolves
  - Renders count line and manga grid from mocked provider
  - Respects content rating setting in API call
- [ ] Integration test: `integration_test/tag_search_flow_test.dart`
  - Open `Search by tag` → include two tags → exclude one → tap `Search` → results page shows count and manga
  - Navigate back → tag page restores included/excluded state and filter text
  - Tap `Clear` → all tags return to unselected

---

## Feature 14 — More Page & Settings Reorganization

**Goal**: Reorganize the `Settings` tab into a `More` tab using an ellipsis icon, restructure the settings into distinct organized sections, add new reading mode preferences and data management controls, and expose app information and storage details.

### Context

**Navigation structure**: The bottom navigation tab is renamed from `Settings` to `More` with an ellipsis (`⋯`) icon. The `More` page acts as a hub with section buttons: tapping a button navigates to a dedicated settings page for that section.

**Reading mode defaults**: When opening a chapter, the reader checks in order:

1. Is there a manga-specific reading mode override (stored per-manga)? Use it.
2. If not, determine manga type: does it have a tag with name `"Web Comic"` (case-insensitive)? If yes, type is "Webcomic"; otherwise, type is "Paged".
3. Check the type-based default from Preferences: Paged defaults to `R->L`, Webcomic defaults to `Vertical`.
4. In the reader bottom sheet, show the current mode (derived from override or type-default). Selecting a new mode creates a manga-specific override, detaching future reads of this manga from the type-based preference.

### Sections and content

**Preferences page**:

- Appearance settings (theme, language, content rating — currently exists)
- Content settings (content rating — currently exists, may consolidate with Appearance)
- Reading settings:
  - Default reading direction for "Paged" manga: `SegmentedButton` with `L->R / R->L / Vertical`; default `R->L`
  - Default reading direction for "Webcomic" manga: `SegmentedButton` with `L->R / R->L / Vertical`; default `Vertical`
  - Check for new chapters on launch: `Always / WiFi Only / Never` (from Feature 11)
  - Placeholder toggle: `"Pre-download next chapter"` with a sub-setting `"Download next [1-10] chapters"` (inactive, noted as coming soon)
  - Placeholder toggle: `"Delete chapters when finished reading"` (inactive, noted as coming soon)

**FAQ page**:

- Collection of expandable drawer items with hardcoded Q&A
- Start with one Q: `"Why aren't all of the chapters available for my manga?"` with a concise answer
- Architecture designed to easily add more Q&A pairs (drawers in a list, each with a title and expandable body)

**Support the dev page**:

- Button/link labeled `"Donate"` that opens a webview or external link (non-functional for now; placeholder)
- Friendly message encouraging support

**Clear data page**:

- Six buttons, each with a confirmation dialog before executing. Confirmation message format: `"This will {action} and cannot be undone. Are you sure you want to proceed?"`
  - `Clear reading history` — deletes all progress and reading data via `LocalProgressService.clearAll()`
  - `Clear library` — unbookmarks all titles via `LibraryService.clearAll()` (or equivalent provider)
  - `Reset settings` — restores all Preferences to defaults (Appearance, Content, Reading, Pre-download toggles)
  - `Remove downloads` — deletes all downloaded chapters via `DownloadService.removeAll()`
  - `Clear cache` — clears:
    - `CachedNetworkImage` cache (covers, chapter pages)
    - DB metadata cache tables (cached manga attributes, cached chapter data)
    - In-memory tag list cache (from Feature 12)
  - `Clear all app data` — executes all of the above sequentially

**About page**:

- Read-only section displaying:
  - App name: `Manga Portal`
  - Version number (from `pubspec.yaml`)
  - Build number
  - `Privacy Policy` link (placeholder; opens webview or external URL)
  - `Terms of Service` link (placeholder)
  - Attribution section: `Built with Flutter`, credits to MangaDex, note about scanlation groups

**Storage info page**:

- Read-only display:
  - `Downloads: X MB` — size of all downloaded chapters from `DownloadService`
  - `Cache: Y MB` — combined size of `CachedNetworkImage` cache + DB metadata + tag list
  - `Total: Z MB`
- Informational only; complements "Clear data" by letting users see what's consuming space

### Tasks

- [ ] Rename `SettingsPage` to `MorePage` in the bottom navigation (label: `More`, icon: ellipsis `⋯`)
- [ ] Update `app.dart` routing: change the settings route or register `/more` instead of `/settings`
- [ ] Create a `MorePage` hub:
  - Vertical list of section buttons with trailing chevrons
  - Buttons: `Preferences`, `FAQ`, `Support the dev`, `Clear data`, `About`, `Storage info`
  - Each button navigates to its dedicated page
- [ ] Create `PreferencesPage`:
  - Consolidated display of Appearance, Content, and Reading settings
  - Add new reading mode sliders for Paged and Webcomic defaults
  - Add existing setting: Check for new chapters on launch
  - Add placeholder toggles: Pre-download next chapter (with sub-setting), Delete chapters when finished reading
  - All settings persist to `SharedPreferences` or Riverpod notifiers as appropriate
- [ ] Create `FAQPage`:
  - Simple list of FAQ items, each with a title (question) and expandable drawer body (answer)
  - Start with one Q&A: `"Why aren't all of the chapters available for my manga?"` with an appropriate explanation
  - Structure the data (e.g., a list of `{question, answer}` dicts) so adding more Q&A is trivial
- [ ] Create `SupportTheDevPage`:
  - Friendly message encouraging donations
  - Button labeled `"Donate"` (non-functional; placeholder for future donation URL)
- [ ] Create `ClearDataPage`:
  - Six buttons, each with a label and matching confirmation dialog
  - Implement each clear action by calling the appropriate service methods
  - On success, show a snackbar: `"[Action] cleared successfully"`
- [ ] Create `AboutPage`:
  - Display app name, version, build number
  - Links to Privacy Policy and Terms of Service (non-functional, placeholders)
  - Attribution section (text-only or small linked items)
- [ ] Create `StorageInfoPage`:
  - Read-only display of storage breakdown
  - Fetch size from `DownloadService.getTotalDownloadedSize()` and cache cleanup utilities
  - Format sizes in MB or GB as appropriate
- [ ] Update `ReaderPage`:
  - Determine manga type by checking for `"Web Comic"` tag (case-insensitive match) in manga's tag list
  - On load, check for manga-specific reading mode override; if not found, use the type-based default from Preferences
  - In the reader bottom sheet, display the current mode and allow selection
  - Selecting a new mode creates (or updates) a manga-specific override
- [ ] Add to `LocalProgressService` (or equivalent service):
  - `saveReadingModeOverride(mangaId, readingMode)` — create a per-manga override
  - `getReadingModeOverride(mangaId)` → `ReadingMode?` (null if no override)
  - `getMangaType(manga)` → `"Paged" | "Webcomic"` (checks for Web Comic tag case-insensitively)
- [ ] Add storage size calculation methods:
  - `DownloadService.getTotalDownloadedSize()` → bytes
  - Cache size helper (approximation is fine; can query `CachedNetworkImage` internals or estimate)
- [ ] Update `SettingsNotifier` to include type-based reading mode defaults

### Tests

- [ ] Widget test: `test/widget/more_page_test.dart`
  - More page displays six section buttons
  - Tapping each button navigates to its page
- [ ] Widget test: `test/widget/preferences_page_test.dart`
  - All existing settings (appearance, content, check for new chapters) render correctly
  - New Paged/Webcomic reading mode sliders render with correct defaults and persist on change
  - Placeholder toggles render as disabled/info state
- [ ] Widget test: `test/widget/faq_page_test.dart`
  - FAQ items render as titles
  - Tapping expands the drawer to show the answer
  - Multiple Q&A items can coexist
- [ ] Widget test: `test/widget/clear_data_page_test.dart`
  - All six buttons render
  - Tapping a button shows the confirmation dialog with the correct message
  - Confirming executes the action; canceling does nothing
- [ ] Widget test: `test/widget/about_page_test.dart`
  - Version, build number, links, and attribution text all render
- [ ] Widget test: `test/widget/storage_info_page_test.dart`
  - Storage breakdown renders (Downloads, Cache, Total)
  - Values update if a refresh is triggered (or show static values from mock)
- [ ] Integration test: `integration_test/more_page_flow_test.dart`
  - Open More tab → see section buttons → tap Preferences → sliders render and persist
  - Open FAQ → expand Q&A → answer shows
  - Open Clear data → confirm clearing reading history → snackbar shown, data cleared
  - Open About and Storage info pages without error

### Extras

- **Web Comic tag matching**: Uses case-insensitive string matching for robustness (e.g., "web comic", "Web Comic", "WEB COMIC" all match)
- **Future-proof FAQ structure**: Q&A items are stored in a simple data structure so future agents can add more items without touching the page layout
- **Placeholder settings**: Pre-download and Delete-on-finish toggles are visually marked as "Coming soon" so users understand they're planned but not yet active
- **Deferred features**: Advanced reader tap zones (Feature X) and Library sort order (Feature Y) are not in scope here but can be added to Preferences later

---

## Stretch Goal — Self-Hosted Server Support (Future, No Implementation Yet)

**Goal**: Allow users to point the app at one or more self-hosted manga servers that implement the same API contract as MangaDex. Searches and browse flows would aggregate results from MangaDex and any configured custom servers.

**Companion project**: A separate server project will expose the necessary MangaDex-compatible API endpoints so the app requires no special handling per source — a self-hosted server is treated identically to MangaDex.

**Design constraints to respect now** (so this does not require a rewrite later):

- `MangaDexApiService` accepts its base URL as a constructor parameter — never hardcode `https://api.mangadex.org` inside method bodies.
- Service logic must not assume MangaDex-specific domains except in the `User-Agent` interceptor and the MD@Home image-reporting logic (which only applies to `mangadex.network` base URLs anyway).
- When this feature is eventually implemented, a `SettingsPage` field will let users add/remove custom server URLs, and the provider layer will fan out requests and merge results.

**Do not implement** any multi-server UI, provider fan-out, or settings until the companion server project exists and the feature is formally prioritized.

---

## Stretch Goal — Dual-Page Landscape Mode (Future)

**Goal**: In landscape orientation, show two manga pages side by side (book spread format), useful for two-page art spreads.

**Design constraint to respect now**: Keep the page-rendering logic (`ReaderPageImage`) decoupled from the layout. The reader should compose pages into a layout container rather than baking layout assumptions into the image widget, so a two-column `Row` layout can be added without restructuring.

---

## Stretch Goal — Local Database Migration (Future)

Status note: Superseded by Feature 9 detour above. Keep this section only as historical context.

**Goal**: Move from `SharedPreferences` to a structured local database (`drift` or `sqflite`) to support full reading history, download queues, and richer library management.

**Design constraint to respect now**: All storage access goes through `LocalProgressService` and equivalent service classes — never call `SharedPreferences` directly from providers or UI. This makes the migration a service-layer swap with no upstream changes required.

---

## Deferred Feature 1 — MangaDex Authentication

**Status**: Blocked — MangaDex public OAuth clients are not available as of April 2026. Personal clients only work for the owning account.

**Goal**: Allow users to log in to MangaDex to sync reading history and library.

### When to implement

Revisit once MangaDex announces public client availability in `#dev-talk-api` on their [Discord](https://discord.gg/mangadex).

### Planned Tasks

- [ ] Register an OAuth2 public client with MangaDex
- [ ] Implement `authorization_code` flow opening `https://auth.mangadex.org` in system browser
- [ ] Handle redirect callback back into the app
- [ ] Store access + refresh tokens in `flutter_secure_storage`
- [ ] Dio interceptor: inject `Authorization: Bearer <token>` for `api.mangadex.org` only — never for image domains
- [ ] On chapter completion: `POST /chapter/:id/read`
- [ ] Retry queue: failed sync attempts stored in `SharedPreferences`; retried at end of each subsequent chapter completion
- [ ] Library sync: fetch MangaDex follows/MDList and merge with local library

### Tests

- Widget test: unauthenticated state shows login button; authenticated state shows username
- Integration test: token stored after login; retry queue retried on next chapter complete

---

## Testing Checklist (per feature)

Before marking a feature complete, verify:

- [ ] At least one widget test covering the primary happy path
- [ ] At least one widget test covering loading and error states
- [ ] At least one integration test covering the primary user flow
- [ ] All tests pass (`flutter test test/widget/` and `flutter test integration_test/`)
- [ ] `flutter analyze` reports no errors or warnings
