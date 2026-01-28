import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/theme/journal_theme.dart';
import 'package:journal_app/providers/journal_providers.dart';
import 'package:journal_app/core/ui/custom_bottom_navigation.dart';
import 'package:journal_app/features/profile/profile_settings_screen.dart';

/// Library screen - displays list of journals
import 'package:journal_app/features/home/home_screen.dart';
import 'package:journal_app/features/friends/friends_screen.dart';
import 'package:journal_app/features/library/journal_library_view.dart';
import 'package:journal_app/features/library/theme_picker_dialog.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  final _titles = [
    'Anasayfa',
    'Profil ve Ayarlar',
    'Arkadaşlar',
    'Günlüklerim',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: const [
          HomeScreen(),
          ProfileSettingsScreen(),
          FriendsView(),
          JournalLibraryView(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
      floatingActionButton:
          _selectedIndex ==
              3 // Only show FAB on Journals tab
          ? Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: FloatingActionButton(
                onPressed: () => _showCreateDialog(context, ref),
                shape: const CircleBorder(),
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }

  // Removed _onItemTapped as it's replaced by onDestinationSelected inline

  // --- Create Dialog Logic (Moved locally or duplicated) ---
  // Ideally this should be in JournalLibraryView but FAB is usually on Scaffold.
  // We can keep it here for now.

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    String selectedThemeId = 'default';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final selectedTheme = BuiltInThemes.getById(selectedThemeId);

          return AlertDialog(
            title: const Text('Yeni Günlük'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Günlük Adı',
                    hintText: 'Örn: Seyahat Notlarım',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tema',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final theme = await showThemePicker(
                      context,
                      selectedThemeId: selectedThemeId,
                    );
                    if (theme != null) {
                      setState(() => selectedThemeId = theme.id);
                    }
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selectedTheme.coverGradient,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(selectedTheme.coverIcon, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          selectedTheme.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    _createJournal(
                      context,
                      ref,
                      controller.text.trim(),
                      selectedThemeId,
                    );
                  }
                },
                child: const Text('Oluştur'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createJournal(
    BuildContext context,
    WidgetRef ref,
    String title,
    String themeId,
  ) async {
    Navigator.pop(context);

    // Use the provider which handles ownerId and cloud sync
    final createJournal = ref.read(createJournalProvider);

    try {
      await createJournal(title: title, coverStyle: themeId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
}
