import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/config_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/assistant_avatar.dart';

class ChatEmptyState extends ConsumerWidget {
  const ChatEmptyState({super.key});

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
              AssistantAvatar(
                size: 216,
                colorFilter: ColorFilter.mode(
                  AppTheme.primaryLight.withAlpha(160),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.remyFooter,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
