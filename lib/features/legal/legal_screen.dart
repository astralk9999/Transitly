import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/widgets/transit_app_bar.dart';

enum LegalDoc { terms, privacy }

/// Pantalla in-app para Términos de Uso y Política de Privacidad.
///
/// Antes ambos abrían `https://transitly.app/terms` y `/privacy` en el
/// navegador, pero el dominio no existe → el usuario veía una página
/// rota. Esta pantalla muestra el contenido localmente, alineado con
/// que la app es un TFG sin servicio comercial.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final title = doc == LegalDoc.terms
        ? 'Términos de Uso'
        : 'Política de Privacidad';

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Column(
        children: [
          TransitAppBar(title: title, transparent: true),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: doc == LegalDoc.terms
                    ? _TermsBody(c: c)
                    : _PrivacyBody(c: c),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.c});
  final String text;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: TransitTypography.heading(c.textHi)),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text, {required this.c});
  final String text;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TransitTypography.bodyPrimary(c.textHi),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody({required this.c});
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Última actualización: junio 2026',
            style: TransitTypography.bodySmall(c.textLo)),
        _SectionTitle('1. Introducción', c: c),
        _Paragraph(
            'Transitly es una aplicación educativa desarrollada como Trabajo Fin de Grado. Su finalidad es exclusivamente académica y de demostración técnica. No constituye un servicio comercial ni la app oficial de ninguna empresa de transporte.',
            c: c),
        _SectionTitle('2. Datos de transporte', c: c),
        _Paragraph(
            'La información sobre líneas, paradas y horarios procede de fuentes públicas (GTFS) y de datos contribuidos por la comunidad. Los horarios pueden no reflejar la realidad operativa. Verifica siempre con la operadora antes de planificar un viaje.',
            c: c),
        _SectionTitle('3. Uso de la aplicación', c: c),
        _Paragraph(
            'Te comprometes a usar Transitly de forma responsable: no publicar contenido ofensivo, no enviar información falsa intencionalmente y respetar a otros usuarios al crear rutas, reportar incidencias o votar.',
            c: c),
        _SectionTitle('4. Cuenta y contenido del usuario', c: c),
        _Paragraph(
            'Si inicias sesión, eres responsable de la información asociada a tu cuenta. Conservas la propiedad sobre el contenido que crees (rutas, sugerencias, comentarios), pero concedes a la app permiso no exclusivo para almacenarlo y mostrarlo a otros usuarios cuando lo publiques como público o lo compartas.',
            c: c),
        _SectionTitle('5. Limitación de responsabilidad', c: c),
        _Paragraph(
            'La aplicación se ofrece "tal cual", sin garantías de disponibilidad, exactitud ni continuidad del servicio. Al ser un TFG, podemos discontinuar funciones, datos o el servicio completo en cualquier momento sin previo aviso.',
            c: c),
        _SectionTitle('6. Modificaciones', c: c),
        _Paragraph(
            'Podemos actualizar estos términos en futuras versiones de la app. Los cambios significativos se anunciarán dentro de la propia app.',
            c: c),
        _SectionTitle('7. Contacto', c: c),
        _Paragraph(
            'Para cualquier duda relacionada con estos términos, escribe al autor del TFG a través de los canales indicados en la pantalla "Acerca de" del perfil.',
            c: c),
      ],
    );
  }
}

class _PrivacyBody extends StatelessWidget {
  const _PrivacyBody({required this.c});
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Última actualización: junio 2026',
            style: TransitTypography.bodySmall(c.textLo)),
        _SectionTitle('1. Quién es el responsable', c: c),
        _Paragraph(
            'Transitly es una aplicación de Trabajo Fin de Grado. El responsable del tratamiento es el autor del TFG, identificado en la sección "Acerca de" del perfil.',
            c: c),
        _SectionTitle('2. Qué datos tratamos', c: c),
        _Paragraph(
            '• Identificadores de cuenta: email y nombre/iniciales si inicias sesión.\n• Preferencias: tema, paleta, fondos, ajustes de accesibilidad.\n• Contenido contribuido: rutas, paradas, sugerencias, incidencias, favoritos.\n• Datos de uso anónimos: navegación entre pantallas, errores (PostHog/Sentry si están habilitados).\n• Ubicación: solo si concedes el permiso y solo durante el uso, para mostrar paradas cercanas. No se guarda en BD.',
            c: c),
        _SectionTitle('3. Para qué los usamos', c: c),
        _Paragraph(
            '• Autenticarte y sincronizar preferencias y favoritos entre tus dispositivos.\n• Mejorar la app diagnosticando errores y patrones de uso agregados.\n• Mostrarte información relevante (paradas, líneas, horarios) según tu ubicación.',
            c: c),
        _SectionTitle('4. Con quién los compartimos', c: c),
        _Paragraph(
            'No vendemos datos personales. Usamos:\n• Supabase (autenticación y BD) como encargado del tratamiento.\n• MapTiler/OpenStreetMap (servidor de teselas del mapa) — su servicio recibe tu IP al cargar el mapa.\n• PostHog (analítica anónima opcional, solo con tu consentimiento).\n• Sentry (informe de errores opcional, solo con tu consentimiento).',
            c: c),
        _SectionTitle('5. Cuánto tiempo conservamos los datos', c: c),
        _Paragraph(
            'Tu cuenta y datos asociados se conservan mientras la cuenta exista. Si solicitas eliminar tu cuenta desde Ajustes → Privacidad, se borran del servidor en un plazo razonable.',
            c: c),
        _SectionTitle('6. Tus derechos', c: c),
        _Paragraph(
            'Tienes derecho a acceder, rectificar, suprimir, oponerte y portar tus datos. La pantalla "Privacidad" del perfil incluye botones para exportar tus datos y eliminar tu cuenta.',
            c: c),
        _SectionTitle('7. Cookies y similares', c: c),
        _Paragraph(
            'En la app móvil no usamos cookies. Usamos almacenamiento local (Hive) para caché offline y secure storage para tokens de sesión.',
            c: c),
        _SectionTitle('8. Cambios en esta política', c: c),
        _Paragraph(
            'Si actualizamos esta política, lo veremos reflejado en la fecha al inicio del documento. Cambios significativos se anunciarán en la propia app.',
            c: c),
      ],
    );
  }
}
