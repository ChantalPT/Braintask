// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solucion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(solucionesRepository)
final solucionesRepositoryProvider = SolucionesRepositoryProvider._();

final class SolucionesRepositoryProvider
    extends
        $FunctionalProvider<
          SolucionesRepository,
          SolucionesRepository,
          SolucionesRepository
        >
    with $Provider<SolucionesRepository> {
  SolucionesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'solucionesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$solucionesRepositoryHash();

  @$internal
  @override
  $ProviderElement<SolucionesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SolucionesRepository create(Ref ref) {
    return solucionesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SolucionesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SolucionesRepository>(value),
    );
  }
}

String _$solucionesRepositoryHash() =>
    r'ba88d2dca9fafbd60a29cc7571aa4c20a6b15bce';

@ProviderFor(SolucionesNotifier)
final solucionesProvider = SolucionesNotifierFamily._();

final class SolucionesNotifierProvider
    extends $AsyncNotifierProvider<SolucionesNotifier, List<Solucion>> {
  SolucionesNotifierProvider._({
    required SolucionesNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'solucionesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$solucionesNotifierHash();

  @override
  String toString() {
    return r'solucionesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SolucionesNotifier create() => SolucionesNotifier();

  @override
  bool operator ==(Object other) {
    return other is SolucionesNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$solucionesNotifierHash() =>
    r'a5a226654de14c5c5b383d7416e0bbcec5abb672';

final class SolucionesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SolucionesNotifier,
          AsyncValue<List<Solucion>>,
          List<Solucion>,
          FutureOr<List<Solucion>>,
          int
        > {
  SolucionesNotifierFamily._()
    : super(
        retry: null,
        name: r'solucionesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SolucionesNotifierProvider call(int idPublicacion) =>
      SolucionesNotifierProvider._(argument: idPublicacion, from: this);

  @override
  String toString() => r'solucionesProvider';
}

abstract class _$SolucionesNotifier extends $AsyncNotifier<List<Solucion>> {
  late final _$args = ref.$arg as int;
  int get idPublicacion => _$args;

  FutureOr<List<Solucion>> build(int idPublicacion);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Solucion>>, List<Solucion>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Solucion>>, List<Solucion>>,
              AsyncValue<List<Solucion>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
