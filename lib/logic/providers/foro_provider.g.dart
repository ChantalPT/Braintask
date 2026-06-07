// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foro_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(foroRepository)
final foroRepositoryProvider = ForoRepositoryProvider._();

final class ForoRepositoryProvider
    extends $FunctionalProvider<ForoRepository, ForoRepository, ForoRepository>
    with $Provider<ForoRepository> {
  ForoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foroRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foroRepositoryHash();

  @$internal
  @override
  $ProviderElement<ForoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ForoRepository create(Ref ref) {
    return foroRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForoRepository>(value),
    );
  }
}

String _$foroRepositoryHash() => r'923a3c618899e0a0fe4512dcfc152d8176aa83c9';

@ProviderFor(ForoPreguntas)
final foroPreguntasProvider = ForoPreguntasProvider._();

final class ForoPreguntasProvider
    extends $AsyncNotifierProvider<ForoPreguntas, List<ForoPregunta>> {
  ForoPreguntasProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foroPreguntasProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foroPreguntasHash();

  @$internal
  @override
  ForoPreguntas create() => ForoPreguntas();
}

String _$foroPreguntasHash() => r'c76b50d20d908baad7714d10452f27050b7afbf0';

abstract class _$ForoPreguntas extends $AsyncNotifier<List<ForoPregunta>> {
  FutureOr<List<ForoPregunta>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ForoPregunta>>, List<ForoPregunta>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ForoPregunta>>, List<ForoPregunta>>,
              AsyncValue<List<ForoPregunta>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
