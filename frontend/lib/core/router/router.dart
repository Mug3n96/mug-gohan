import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/recipes/screens/recipe_list_screen.dart';
import '../../features/recipes/screens/recipe_detail_screen.dart';

part 'router.g.dart';

/// Bridges Riverpod auth state into a [ChangeNotifier] so GoRouter
/// can call [GoRouter.refresh] automatically on auth changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, next) => notifyListeners());
    _ref = ref;
  }

  late final Ref _ref;

  bool get isLoggedIn => _ref.read(authNotifierProvider).valueOrNull != null;
}

@riverpod
GoRouter router(Ref ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = notifier.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/recipes';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/recipes',
        builder: (context, state) => const RecipeListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => RecipeDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}
