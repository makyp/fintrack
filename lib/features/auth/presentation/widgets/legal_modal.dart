import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _LegalSection {
  final String title;
  final String body;
  const _LegalSection(this.title, this.body);
}

class _LegalDocument {
  final String title;
  final String subtitle;
  final String lastUpdated;
  final List<_LegalSection> sections;
  const _LegalDocument({
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
    required this.sections,
  });
}

// ── Public entry points ───────────────────────────────────────────────────────

void showTermsModal(BuildContext context) =>
    _showLegalModal(context, _termsDocument);

void showPrivacyModal(BuildContext context) =>
    _showLegalModal(context, _privacyDocument);

// ── Modal launcher ────────────────────────────────────────────────────────────

void _showLegalModal(BuildContext context, _LegalDocument doc) {
  final isWide = MediaQuery.of(context).size.width >= 800;

  if (isWide) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
        child: _LegalContent(doc: doc),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, scrollController) => _LegalContent(
          doc: doc,
          scrollController: scrollController,
          isSheet: true,
        ),
      ),
    );
  }
}

// ── Content widget ────────────────────────────────────────────────────────────

class _LegalContent extends StatelessWidget {
  final _LegalDocument doc;
  final ScrollController? scrollController;
  final bool isSheet;

  const _LegalContent({
    required this.doc,
    this.scrollController,
    this.isSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: isSheet
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ── Handle / header ────────────────────────────────────────────
          if (isSheet)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          _Header(doc: doc, isSheet: isSheet),
          const Divider(height: 1),
          // ── Scrollable body ────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              itemCount: doc.sections.length,
              itemBuilder: (_, i) => _SectionTile(
                number: i + 1,
                section: doc.sections[i],
              ),
            ),
          ),
          // ── Close button ───────────────────────────────────────────────
          _Footer(context: context),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final _LegalDocument doc;
  final bool isSheet;
  const _Header({required this.doc, required this.isSheet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, isSheet ? 12 : 24, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title, style: AppTextStyles.headlineMedium),
                const SizedBox(height: 2),
                Text(doc.subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500)),
                const SizedBox(height: 2),
                Text('Última actualización: ${doc.lastUpdated}',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey400, fontSize: 11)),
              ],
            ),
          ),
          if (!isSheet)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final int number;
  final _LegalSection section;
  const _SectionTile({required this.number, required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(section.title,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.grey700, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final BuildContext context;
  const _Footer({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Entendido'),
      ),
    );
  }
}

// ── Términos de Servicio ──────────────────────────────────────────────────────

const _termsDocument = _LegalDocument(
  title: 'Términos de Servicio',
  subtitle: 'FinTrack — Gestión de finanzas personales',
  lastUpdated: '1 de abril de 2025',
  sections: [
    _LegalSection(
      'Aceptación de los términos',
      'Al registrarse y utilizar FinTrack, usted acepta de manera libre, '
          'expresa e informada los presentes Términos de Servicio. Si no está '
          'de acuerdo con alguna de las condiciones aquí establecidas, le '
          'pedimos abstenerse de usar la aplicación. El uso continuado de '
          'FinTrack después de cualquier modificación implica la aceptación '
          'de los términos actualizados.',
    ),
    _LegalSection(
      'Descripción del servicio',
      'FinTrack es una aplicación de gestión de finanzas personales que '
          'permite registrar transacciones (ingresos, gastos y transferencias), '
          'administrar cuentas bancarias y de efectivo, definir metas de '
          'ahorro, visualizar reportes gráficos del comportamiento financiero, '
          'colaborar en un hogar compartido y recibir logros de gamificación. '
          'FinTrack NO constituye asesoría financiera, bancaria ni de '
          'inversión. La información presentada es de carácter informativo y '
          'referencial.',
    ),
    _LegalSection(
      'Registro y cuenta de usuario',
      'Para usar FinTrack debe crear una cuenta con correo electrónico y '
          'contraseña o a través de Google Sign-In. Usted es responsable de '
          'mantener la confidencialidad de sus credenciales y de todas las '
          'actividades realizadas desde su cuenta. Debe notificarnos '
          'inmediatamente ante cualquier uso no autorizado. No está permitido '
          'ceder, transferir ni compartir el acceso a su cuenta con terceros.',
    ),
    _LegalSection(
      'Uso permitido y restricciones',
      'Usted se compromete a utilizar FinTrack únicamente para fines lícitos '
          'y personales. Queda prohibido: (i) intentar vulnerar la seguridad '
          'de la aplicación o acceder a datos de otros usuarios; (ii) usar la '
          'plataforma para actividades fraudulentas o ilegales según la '
          'legislación colombiana; (iii) realizar ingeniería inversa o '
          'descompilar la aplicación; (iv) publicar datos falsos o '
          'información que induzca a error.',
    ),
    _LegalSection(
      'Colaboración en hogares',
      'La función de hogar compartido permite que múltiples usuarios '
          'registren gastos comunes. Al unirse a un hogar, usted autoriza que '
          'los demás miembros del grupo visualicen las transacciones marcadas '
          'como compartidas. Los reportes del hogar son visibles para todos '
          'los miembros. El administrador del hogar es responsable de gestionar '
          'las invitaciones. Los gastos personales no marcados como '
          'compartidos permanecen privados.',
    ),
    _LegalSection(
      'Propiedad intelectual',
      'Todos los derechos sobre FinTrack, incluyendo el diseño, código '
          'fuente, logotipos, gráficos y contenidos, son propiedad exclusiva '
          'de sus creadores y están protegidos por la Ley 23 de 1982 sobre '
          'derechos de autor en Colombia. Se concede al usuario una licencia '
          'limitada, no exclusiva e intransferible para usar la aplicación '
          'conforme a estos términos.',
    ),
    _LegalSection(
      'Limitación de responsabilidad',
      'FinTrack se proporciona "tal cual" sin garantías de ningún tipo. No '
          'somos responsables por: (i) pérdidas económicas derivadas de '
          'decisiones financieras basadas en la información de la app; '
          '(ii) interrupciones del servicio por mantenimiento o causas de '
          'fuerza mayor; (iii) pérdida de datos por fallas de conectividad '
          'fuera de nuestro control. La responsabilidad máxima frente al '
          'usuario en ningún caso superará el valor pagado por el servicio.',
    ),
    _LegalSection(
      'Modificaciones del servicio',
      'Nos reservamos el derecho de modificar, suspender o discontinuar '
          'cualquier funcionalidad de FinTrack en cualquier momento, con '
          'o sin previo aviso. Las modificaciones sustanciales a estos '
          'Términos se notificarán mediante la aplicación con al menos '
          '15 días de anticipación. El uso continuo del servicio después '
          'de dicha notificación implica la aceptación de los cambios.',
    ),
    _LegalSection(
      'Ley aplicable y jurisdicción',
      'Los presentes Términos se rigen por las leyes de la República de '
          'Colombia, en particular por la Ley 527 de 1999 (comercio '
          'electrónico), la Ley 1480 de 2011 (Estatuto del Consumidor) y '
          'demás normas concordantes. Cualquier controversia se someterá '
          'a la jurisdicción de los jueces competentes de la ciudad de '
          'Bogotá D.C., Colombia.',
    ),
    _LegalSection(
      'Contacto',
      'Para cualquier consulta sobre estos Términos puede comunicarse '
          'con nosotros a través de la sección de Perfil → Soporte dentro '
          'de la aplicación. Responderemos en un plazo máximo de 15 días '
          'hábiles.',
    ),
  ],
);

// ── Política de Privacidad (Ley 1581 de 2012) ─────────────────────────────────

const _privacyDocument = _LegalDocument(
  title: 'Política de Privacidad',
  subtitle: 'Tratamiento de datos personales — Ley 1581 de 2012',
  lastUpdated: '1 de abril de 2025',
  sections: [
    _LegalSection(
      'Responsable del tratamiento',
      'FinTrack actúa como responsable del tratamiento de los datos '
          'personales recolectados a través de la aplicación. De conformidad '
          'con la Ley 1581 de 2012 y el Decreto 1377 de 2013, nos comprometemos '
          'a proteger la información personal de nuestros usuarios y a '
          'tratarla únicamente para las finalidades autorizadas. Para '
          'ejercer sus derechos puede contactarnos desde la sección de '
          'Perfil → Soporte.',
    ),
    _LegalSection(
      'Datos personales recolectados',
      'Recolectamos la siguiente información: (i) Datos de identificación: '
          'nombre completo, correo electrónico, foto de perfil (si usa '
          'Google Sign-In); (ii) Datos financieros: montos de transacciones, '
          'nombres de cuentas, categorías de gasto, metas de ahorro y '
          'presupuestos (todos ingresados voluntariamente por usted); '
          '(iii) Datos técnicos: token de dispositivo para notificaciones '
          'push (FCM), datos de uso y rendimiento recolectados por Firebase '
          'Analytics y Crashlytics. No recolectamos números de cuentas '
          'bancarias reales, contraseñas bancarias ni información de '
          'tarjetas de crédito.',
    ),
    _LegalSection(
      'Finalidades del tratamiento',
      'Sus datos personales se tratan para: (i) Proveer y mejorar el '
          'servicio de gestión financiera personal; (ii) Personalizar la '
          'experiencia del usuario y sus reportes financieros; (iii) Enviar '
          'notificaciones push sobre logros, recordatorios y alertas '
          'financieras; (iv) Analizar patrones de uso para mejorar la '
          'aplicación (de forma agregada y anónima); (v) Detectar y '
          'prevenir errores técnicos mediante Crashlytics; (vi) Facilitar '
          'la colaboración en el módulo de hogar compartido con los '
          'miembros que usted mismo invite.',
    ),
    _LegalSection(
      'Base legal del tratamiento',
      'El tratamiento de sus datos se fundamenta en: (i) Su consentimiento '
          'libre, previo, expreso e informado otorgado al aceptar esta '
          'política durante el registro; (ii) La ejecución del contrato de '
          'prestación del servicio FinTrack; (iii) El interés legítimo para '
          'garantizar la seguridad e integridad de la plataforma. En '
          'cualquier momento puede revocar su autorización eliminando su '
          'cuenta desde Perfil → Seguridad → Eliminar cuenta.',
    ),
    _LegalSection(
      'Compartición de datos con terceros',
      'No vendemos ni comercializamos sus datos personales. Compartimos '
          'información únicamente con: (i) Google Firebase (infraestructura '
          'de autenticación, base de datos, almacenamiento, notificaciones '
          'y analítica) bajo las políticas de privacidad de Google LLC; '
          '(ii) Miembros del hogar compartido que usted mismo invita, '
          'limitado a las transacciones marcadas explícitamente como '
          'compartidas; (iii) Autoridades competentes cuando exista '
          'obligación legal de hacerlo. Todos los terceros están sujetos '
          'a acuerdos de confidencialidad.',
    ),
    _LegalSection(
      'Derechos del titular (Habeas Data)',
      'De conformidad con la Ley 1581 de 2012, usted tiene derecho a: '
          '(i) Conocer los datos personales que tenemos sobre usted; '
          '(ii) Actualizar y rectificar sus datos cuando estén incompletos '
          'o sean inexactos; (iii) Solicitar la supresión de sus datos '
          'cuando no sean necesarios para las finalidades informadas; '
          '(iv) Revocar la autorización de tratamiento; (v) Acceder '
          'gratuitamente a sus datos; (vi) Presentar quejas ante la '
          'Superintendencia de Industria y Comercio (SIC) si considera '
          'que sus derechos han sido vulnerados. Para ejercer cualquiera '
          'de estos derechos escríbanos desde la app.',
    ),
    _LegalSection(
      'Seguridad de la información',
      'Implementamos medidas técnicas y organizativas para proteger sus '
          'datos: (i) Transmisión cifrada mediante TLS/HTTPS; (ii) '
          'Autenticación segura con Firebase Auth, incluyendo soporte '
          'para autenticación con Google; (iii) Reglas de seguridad de '
          'Firestore que garantizan que cada usuario solo accede a sus '
          'propios datos; (iv) Los datos financieros ingresados son '
          'almacenados en servidores de Google Cloud con certificaciones '
          'ISO 27001. Ningún sistema es 100% infalible; en caso de '
          'brecha de seguridad que afecte sus datos, le notificaremos '
          'en el plazo establecido por la ley.',
    ),
    _LegalSection(
      'Retención y eliminación de datos',
      'Sus datos se conservan mientras su cuenta esté activa. Al eliminar '
          'su cuenta desde la aplicación, sus datos personales y financieros '
          'se eliminan de nuestros servidores en un plazo de 30 días '
          'calendario, excepto aquellos que debamos conservar por '
          'obligaciones legales o para resolver disputas pendientes. '
          'Los datos de Firebase Analytics se retienen según las políticas '
          'de Google (máximo 14 meses por defecto).',
    ),
    _LegalSection(
      'Transferencia internacional de datos',
      'Sus datos pueden ser procesados en servidores ubicados fuera de '
          'Colombia, incluyendo Estados Unidos, donde Google LLC tiene '
          'su sede principal. Dicha transferencia se realiza al amparo '
          'del Capítulo IV de la Ley 1581 de 2012 y del Decreto 1377 '
          'de 2013, garantizando que el receptor brinda niveles adecuados '
          'de protección. Google cumple con el Marco de Privacidad de '
          'Datos UE-EE.UU. y mecanismos equivalentes.',
    ),
    _LegalSection(
      'Cambios a esta política',
      'Podemos actualizar esta Política de Privacidad periódicamente. '
          'Los cambios sustanciales se notificarán dentro de la aplicación '
          'con al menos 10 días de anticipación a su entrada en vigor. '
          'Le recomendamos revisar esta política regularmente. La fecha '
          'de "Última actualización" al inicio del documento siempre '
          'indica la versión vigente.',
    ),
    _LegalSection(
      'Autoridad de control',
      'En Colombia, la autoridad de protección de datos personales es '
          'la Superintendencia de Industria y Comercio (SIC), con sede '
          'en Bogotá D.C. Si considera que sus derechos han sido '
          'vulnerados, puede radicar una queja en www.sic.gov.co o '
          'llamar a la línea gratuita 01 8000 910 165.',
    ),
  ],
);
