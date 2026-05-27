const Set<String> dominiosCorreoUnimet = {
  'unimet.edu.ve',
  'correo.unimet.edu.ve',
};

String? validarCorreoUnimet(String? value) {
  final correo = value?.trim().toLowerCase() ?? '';

  if (correo.isEmpty) {
    return 'Ingresa tu correo';
  }

  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(correo)) {
    return 'Ingresa un correo valido';
  }

  final dominio = correo.split('@').last;
  if (!dominiosCorreoUnimet.contains(dominio)) {
    return 'Usa solo tu correo institucional UNIMET';
  }

  return null;
}
