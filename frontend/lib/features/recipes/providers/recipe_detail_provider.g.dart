// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recipeDetailHash() => r'5ff9b962ba2e05eff8de68ccb4f5b77148a2a32e';

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

abstract class _$RecipeDetail
    extends BuildlessAutoDisposeAsyncNotifier<Recipe> {
  late final String id;

  FutureOr<Recipe> build(String id);
}

/// See also [RecipeDetail].
@ProviderFor(RecipeDetail)
const recipeDetailProvider = RecipeDetailFamily();

/// See also [RecipeDetail].
class RecipeDetailFamily extends Family<AsyncValue<Recipe>> {
  /// See also [RecipeDetail].
  const RecipeDetailFamily();

  /// See also [RecipeDetail].
  RecipeDetailProvider call(String id) {
    return RecipeDetailProvider(id);
  }

  @override
  RecipeDetailProvider getProviderOverride(
    covariant RecipeDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'recipeDetailProvider';
}

/// See also [RecipeDetail].
class RecipeDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<RecipeDetail, Recipe> {
  /// See also [RecipeDetail].
  RecipeDetailProvider(String id)
    : this._internal(
        () => RecipeDetail()..id = id,
        from: recipeDetailProvider,
        name: r'recipeDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$recipeDetailHash,
        dependencies: RecipeDetailFamily._dependencies,
        allTransitiveDependencies:
            RecipeDetailFamily._allTransitiveDependencies,
        id: id,
      );

  RecipeDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  FutureOr<Recipe> runNotifierBuild(covariant RecipeDetail notifier) {
    return notifier.build(id);
  }

  @override
  Override overrideWith(RecipeDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: RecipeDetailProvider._internal(
        () => create()..id = id,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<RecipeDetail, Recipe>
  createElement() {
    return _RecipeDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RecipeDetailRef on AutoDisposeAsyncNotifierProviderRef<Recipe> {
  /// The parameter `id` of this provider.
  String get id;
}

class _RecipeDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RecipeDetail, Recipe>
    with RecipeDetailRef {
  _RecipeDetailProviderElement(super.provider);

  @override
  String get id => (origin as RecipeDetailProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
