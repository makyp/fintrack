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

## ⚠️ Falta un paso en la consola de Firebase

Un `applicationId` es una app distinta para Google. La app Android registrada
en el proyecto `fintrack-6b6d4` sigue siendo la vieja, y **el package de una app
de Firebase no se puede cambiar**: hay que registrar una nueva en el mismo
proyecto. No se pierde nada — Firestore, Storage y los usuarios son del
proyecto, no de la app.

Mientras tanto, el `google-services.json` del repositorio quedó **editado a
mano** para que el proyecto siga compilando. Sirve para compilar y para todo lo
que use las credenciales del proyecto, pero:

> **El inicio de sesión con Google va a fallar con `DEVELOPER_ERROR` (código 10)
> hasta que se haga el registro de abajo.** Google valida el par
> (package, huella del certificado) contra el cliente OAuth que tiene
> registrado, y ese cliente todavía apunta a `com.example.fintrack`.
> El acceso con correo y contraseña no se ve afectado.

### Los cuatro pasos

1. **Registrar la app nueva.** Consola de Firebase › proyecto `fintrack-6b6d4`
   › Configuración del proyecto › Tus apps › Agregar app › Android. Package name:
   `app.fimakyp.finanzas`.

2. **Agregar las huellas SHA-1.** En la misma pantalla, "Agregar huella digital".
   La de depuración se saca así:

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android
   ```

   La app vieja tenía registrada `6dd1e157ed4149011c6ae4fc1202016db7be1102`,
   que es justamente esa. Cuando exista una firma de release (hoy el
   `build.gradle` firma el release con las claves de depuración), hay que
   agregar también su SHA-1, y la que genere Play si se usa App Signing.

3. **Bajar el archivo de verdad y reemplazar los dos generados.**

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=fintrack-6b6d4
   ```

   Esto reescribe `android/app/google-services.json` y `lib/firebase_options.dart`
   con el `appId` correcto de la app nueva, y de paso agrega el bloque de iOS si
   ya se registró esa (ver `publicar_en_ios.md`).

4. **Borrar la app vieja** (opcional). Una vez que la nueva funcione, la entrada
   `com.example.fintrack` de la consola se puede eliminar para no confundirse.

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
