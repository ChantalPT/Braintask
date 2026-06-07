// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perfil_publico_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(perfilPublico)
final perfilPublicoProvider = PerfilPublicoFamily._();

final class PerfilPublicoProvider
    extends
        $FunctionalProvider<
          AsyncValue<UsuarioModel>,
          UsuarioModel,
          FutureOr<UsuarioModel>
        >
    with $FutureModifier<UsuarioModel>, $FutureProvider<UsuarioModel> {
  PerfilPublicoProvider._({
    required PerfilPublicoFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'perfilPublicoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$perfilPublicoHash();

  @override
  String toString() {
    return r'perfilPublicoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UsuarioModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UsuarioModel> create(Ref ref) {
    final argument = this.argument as String;
    return perfilPublico(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PerfilPublicoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$perfilPublicoHash() => r'1cddb277fb64ee6808d66dcd8c55bb50f712e93b';

final class PerfilPublicoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UsuarioModel>, String> {
  PerfilPublicoFamily._()
    : super(
        retry: null,
        name: r'perfilPublicoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PerfilPublicoProvider call(String userId) =>
      PerfilPublicoProvider._(argument: userId, from: this);

  @override
  String toString() => r'perfilPublicoProvider';
}
