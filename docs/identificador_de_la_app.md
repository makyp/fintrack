# El identificador de la app: `app.fimakyp.finanzas`

La app dejó de llamarse `com.example.fintrack`. Ese era el placeholder que
genera Flutter, y **Google Play rechaza cualquier paquete que empiece por
`com.example`**, así que no había forma de publicar con él.

El identificador nuevo es el mismo en las dos tiendas:

| | Valor |
|---|---|
| Android `applicationId` y `namespace` | `app.fimakyp.finanzas` |
| iOS / macOS bundle id | `app.fimakyp.finanzas` |
| Widget de pantalla de inicio | `app.fimakyp.finanzas.FimakypWidgetProvider` |

El código Java se movió de `android/app/src/main/java/com/example/fintrack/` a
`android/app/src/main/java/app/fimakyp/finanzas/`.

## Firebase: hecho

La app Android nueva ya está registrada en el proyecto `fintrack-6b6d4`:

| | |
|---|---|
| Alias | Fimakyp (Android) |
| Package | `app.fimakyp.finanzas` |
| App ID | `1:94712880912:android:c40ba73af444e121bf4f95` |
| Huella SHA-1 | `6d:d1:e1:57:ed:41:49:01:1c:6a:e4:fc:12:02:01:6d:b7:be:11:02` (depuración) |

El `google-services.json` del repositorio es el que descargó la consola —ya no
el parche a mano— y trae el cliente OAuth propio del package nuevo, así que el
inicio de sesión con Google funciona. El `appId` de Android en
`lib/firebase_options.dart` apunta a la app nueva.

El archivo conserva también la entrada de `com.example.fintrack`: así lo genera
Firebase mientras las dos apps existan en el proyecto. El plugin de Gradle
resuelve por `package_name`, así que no estorba.

### Lo que queda pendiente

- **SHA-1 de la firma de release.** Hoy `android/app/build.gradle` firma el
  release con las claves de depuración (`signingConfig = signingConfigs.debug`),
  por eso la huella de depuración alcanza. Cuando exista un keystore de release
  —y cuando Play App Signing genere el suyo— hay que agregar esas huellas en la
  misma pantalla, o el login con Google fallará solo en la versión publicada.
- **Borrar la app vieja** (opcional). La entrada `com.example.fintrack` se puede
  eliminar de la consola cuando ya no se necesite. No se tocó: borrar es
  irreversible y nada obliga a hacerlo ahora.

## Sobre reinstalar

Cambiar el `applicationId` hace que Android la trate como otra aplicación: la
instalada con el identificador viejo no se actualiza sola y hay que
desinstalarla. **Los datos no se pierden**: viven en Firestore contra la cuenta
del usuario, no en el teléfono. Al entrar con el mismo correo vuelve a aparecer
todo.

Lo único que sí queda en el dispositivo y se va con la desinstalación son las
preferencias locales: los recordatorios programados, la cuenta usada por última
vez en el formulario, la cola de movimientos detectados y el permiso de acceso a
notificaciones, que hay que volver a conceder.
