import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/providers/config_provider.dart';
import '../../../../core/theme/app_theme.dart';

class ChatEmptyState extends ConsumerWidget {
  const ChatEmptyState({super.key, required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  static const _suggestions = [
    'Beschreibe das Rezept kurz',
    'Welche Zutaten fehlen noch?',
    'Mach mir einen vollständigen Vorschlag',
  ];

  static const _commands = ['/clear'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appConfigProvider).strings;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                strings.remyGreeting,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                strings.remySubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SvgPicture.asset(
                'assets/icons/remy.svg',
                height: 216,
                colorFilter: ColorFilter.mode(
                  AppTheme.primaryLight.withAlpha(160),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 16),
              ..._suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      onPressed: () => onSuggestionTap(s),
                    ),
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _commands
                    .map((c) => ActionChip(
                          avatar: const Icon(Icons.terminal, size: 13),
                          label: Text(
                            c,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          onPressed: () => onSuggestionTap(c),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
