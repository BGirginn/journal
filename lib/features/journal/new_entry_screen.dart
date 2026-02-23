import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
import 'package:journal_app/core/theme/tokens/brand_spacing.dart';
import 'package:journal_app/providers/journal_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NewEntryScreen extends ConsumerStatefulWidget {
  const NewEntryScreen({super.key});

  @override
  ConsumerState<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends ConsumerState<NewEntryScreen> {
  final _controller = TextEditingController();
  String _selectedMood = '😊';
  bool _isSaving = false;

  static const _moods = ['😊', '😃', '😔', '😍', '😎', '🤔', '😴', '🥳'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen günlüğün için bir metin yaz.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final createQuickEntry = ref.read(createQuickJournalEntryProvider);
      final journalId = await createQuickEntry(text);
      if (!mounted) return;
      context.go('/journal/$journalId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayıt sırasında hata: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/?tab=2');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;
    final spacing =
        Theme.of(context).extension<JournalSpacingScale>() ??
        JournalSpacingScale.standard;
    final dateStr = DateFormat('EEEE, d MMMM', 'tr_TR').format(DateTime.now());

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 22),
            decoration: BoxDecoration(
              color: semantic.elevated,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(radius.modal),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: LucideIcons.arrowLeft,
                        onTap: _handleBack,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Yeni Günlük',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: const Icon(LucideIcons.inbox),
                        tooltip: 'Inbox',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isSaving ? null : _saveEntry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              _isSaving
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : Icon(
                                      LucideIcons.send,
                                      size: 16,
                                      color: colorScheme.onPrimary,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                _isSaving ? 'Kaydediliyor' : 'Kaydet',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: semantic.card,
                      borderRadius: BorderRadius.circular(radius.large),
                      border: Border.all(
                        color: semantic.divider.withValues(alpha: 0.8),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 12,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Bugün nasıl geçti? Düşüncelerini yaz...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                            ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: semantic.card,
                      borderRadius: BorderRadius.circular(radius.large),
                      border: Border.all(
                        color: semantic.divider.withValues(alpha: 0.8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ToolItem(icon: LucideIcons.smile, label: 'Emoji'),
                        _ToolItem(icon: LucideIcons.image, label: 'Fotoğraf'),
                        _ToolItem(icon: LucideIcons.mapPin, label: 'Konum'),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: semantic.card,
                      borderRadius: BorderRadius.circular(radius.large),
                      border: Border.all(
                        color: semantic.divider.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bugün nasıl hissediyorsun?',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 58,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _moods.map((mood) {
                              final isSelected = mood == _selectedMood;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Material(
                                  color: isSelected
                                      ? colorScheme.primaryContainer
                                      : semantic.elevated,
                                  borderRadius: BorderRadius.circular(
                                    radius.medium,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      radius.medium,
                                    ),
                                    onTap: () =>
                                        setState(() => _selectedMood = mood),
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          radius.medium,
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : semantic.divider.withValues(
                                                  alpha: 0.8,
                                                ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          mood,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
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

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ToolItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Icon(icon, size: 18, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
