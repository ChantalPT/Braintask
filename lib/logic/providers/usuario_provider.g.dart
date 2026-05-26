// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(usuarioRepository)
final usuarioRepositoryProvider = UsuarioRepositoryProvider._();

final class UsuarioRepositoryProvider
    extends
        $FunctionalProvider<
          UsuarioRepository,
          UsuarioRepository,
          UsuarioRepository
        >
    with $Provider<UsuarioRepository> {
  UsuarioRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usuarioRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usuarioRepositoryHash();

  @$internal
  @override
  $ProviderElement<UsuarioRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UsuarioRepository create(Ref ref) {
    return usuarioRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UsuarioRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UsuarioRepository>(value),
    );
  }
}

String _$usuarioRepositoryHash() => r'4881a0ebd1edacec95d4b94ac8ae557db0f78fd9';

@ProviderFor(UsuarioNotifier)
final usuarioProvider = UsuarioNotifierProvider._();

final class UsuarioNotifierProvider
    extends $AsyncNotifierProvider<UsuarioNotifier, UsuarioModel> {
  UsuarioNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usuarioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usuarioNotifierHash();

  @$internal
  @override
  UsuarioNotifier create() => UsuarioNotifier();
}

String _$usuarioNotifierHash() => r'6c160a50a1935ef1202ede8c1192674c908b2648';

abstract class _$UsuarioNotifier extends $AsyncNotifier<UsuarioModel> {
  FutureOr<UsuarioModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UsuarioModel>, UsuarioModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UsuarioModel>, UsuarioModel>,
              AsyncValue<UsuarioModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
