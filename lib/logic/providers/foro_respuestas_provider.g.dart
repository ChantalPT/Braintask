// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foro_respuestas_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ForoRespuestas)
final foroRespuestasProvider = ForoRespuestasFamily._();

final class ForoRespuestasProvider
    extends $AsyncNotifierProvider<ForoRespuestas, List<ForoRespuesta>> {
  ForoRespuestasProvider._({
    required ForoRespuestasFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'foroRespuestasProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foroRespuestasHash();

  @override
  String toString() {
    return r'foroRespuestasProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ForoRespuestas create() => ForoRespuestas();

  @override
  bool operator ==(Object other) {
    return other is ForoRespuestasProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foroRespuestasHash() => r'95946746ad62e5e65a042a4870f6f791c5883489';

final class ForoRespuestasFamily extends $Family
    with
        $ClassFamilyOverride<
          ForoRespuestas,
          AsyncValue<List<ForoRespuesta>>,
          List<ForoRespuesta>,
          FutureOr<List<ForoRespuesta>>,
          int
        > {
  ForoRespuestasFamily._()
    : super(
        retry: null,
        name: r'foroRespuestasProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ForoRespuestasProvider call(int idPregunta) =>
      ForoRespuestasProvider._(argument: idPregunta, from: this);

  @override
  String toString() => r'foroRespuestasProvider';
}

abstract class _$ForoRespuestas extends $AsyncNotifier<List<ForoRespuesta>> {
  late final _$args = ref.$arg as int;
  int get idPregunta => _$args;

  FutureOr<List<ForoRespuesta>> build(int idPregunta);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ForoRespuesta>>, List<ForoRespuesta>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ForoRespuesta>>, List<ForoRespuesta>>,
              AsyncValue<List<ForoRespuesta>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
