# Publicar Fimakyp en iOS

El código Flutter ya es multiplataforma y el proyecto Xcode está en el
repositorio. Lo que falta no es programar: es firmar, registrar la app en
Firebase y pasar la revisión de Apple. Este documento es la lista exacta, en
orden, con lo que ya quedó hecho marcado.

## Lo que ya está listo en el repositorio

- [x] Proyecto Xcode (`ios/Runner.xcodeproj`) y `AppDelegate`.
- [x] `Info.plist` con los cuatro textos de permiso que Apple exige **y rechaza
      si faltan**: micrófono, reconocimiento de voz, cámara y fotos. Están
      redactados diciendo para qué se usa cada uno, que es lo que revisa Apple.
- [x] `IPHONEOS_DEPLOYMENT_TARGET = 13.0` en las tres configuraciones. Con el
      12.0 que traía por defecto, `pod install` falla antes de compilar:
      `firebase_core` 3.x y `firebase_auth` 5.x piden iOS 13 como mínimo.
- [x] `ios/Podfile` con la plataforma fijada en 13.0 y un `post_install` que
      alinea el deployment target de todos los pods (varios traen 11.0 y el
      linker se queja de versiones mezcladas).
- [x] `.gitignore` para `Pods/`, `.symlinks/`, `Podfile.lock` y el
      `GoogleService-Info.plist`, que lleva claves y se descarga en cada
      máquina.

## Lo que hay que hacer, en orden

### 1. ~~Elegir el bundle identifier~~ — ya está: `app.fimakyp.finanzas`

Ya no es `com.example.fintrack`. El identificador quedó fijado en el proyecto
Xcode (las seis apariciones de `PRODUCT_BUNDLE_IDENTIFIER`, Runner y
RunnerTests) y es el mismo que usa Android, así que no hay dos identidades que
mantener. Ver `identificador_de_la_app.md`.

### 2. Cuenta de desarrollador de Apple

- Apple Developer Program: **USD 99 al año**. No hay forma de publicar en la
  App Store sin esto.
- Se necesita un **Mac** para compilar y subir el binario. No hay alternativa
  local en Windows; si no hay Mac a la mano, la salida es un servicio de CI con
  runners macOS (Codemagic tiene plan gratuito para proyectos pequeños, GitHub
  Actions cobra los minutos de macOS a 10x).

### 3. Registrar la app iOS en Firebase

En la consola de `fintrack-6b6d4` › Configuración › Agregar app › iOS:

1. Escribir el bundle id: `app.fimakyp.finanzas`.
2. Descargar `GoogleService-Info.plist` y arrastrarlo a `ios/Runner/` **desde
   Xcode** (con "Copy items if needed" marcado), no desde el explorador de
   archivos: tiene que quedar dentro del target Runner o Firebase no lo
   encuentra en tiempo de ejecución.
3. Regenerar las opciones de Dart:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=fintrack-6b6d4
   ```

   Esto agrega el bloque `ios` a `lib/firebase_options.dart`, que hoy lanza
   `UnsupportedError` en iOS a propósito.

### 4. Inicio de sesión con Google

`google_sign_in` en iOS necesita el esquema de URL invertido:

1. Abrir el `GoogleService-Info.plist` recién descargado y copiar el valor de
   `REVERSED_CLIENT_ID` (empieza por `com.googleusercontent.apps.`).
2. Agregarlo en `ios/Runner/Info.plist`:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.EL-VALOR-COPIADO</string>
       </array>
     </dict>
   </array>
   ```

No se dejó puesto en el repositorio porque ese valor sale del proyecto iOS de
Firebase, que todavía no existe: un placeholder haría que el login con Google
falle en silencio, que es peor que no tenerlo.

### 5. Compilar

En el Mac, con el repositorio clonado:

```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

### 6. Revisión de Apple: lo que suele rebotar en esta app

- **Permisos**: ya están los textos, pero Apple rechaza si un permiso se pide y
  la función no se puede probar. Hay que dejar el dictado por voz y la lectura
  de recibos accesibles sin cuenta de pago ni pasos raros, y explicarlo en las
  notas del revisor.
- **Cuenta de prueba**: la revisión necesita entrar. Hay que crear un usuario de
  demo con datos cargados y ponerlo en "App Review Information".
- **Sign in with Apple**: la guideline 4.8 exige ofrecerlo cuando la app ofrece
  login social de terceros. Hoy la app tiene Google, así que **hay que agregar
  Sign in with Apple** o el rechazo es prácticamente seguro. Es el único trabajo
  de programación real que queda del lado de iOS.
- **Movimientos detectados**: la función que lee las notificaciones del banco es
  exclusiva de Android. iOS no permite que una app lea las notificaciones de
  otra, y la pantalla ya lo dice en vez de ofrecer un botón que no haría nada.
  Conviene no mencionarla en la ficha de la App Store.

## Resumen honesto

Del lado del repositorio, iOS está tan listo como puede estarlo desde Windows.
Lo que falta es, en este orden: pagar los USD 99, conseguir un Mac (o un runner
macOS), registrar la app en Firebase, pegar el `REVERSED_CLIENT_ID` y agregar
Sign in with Apple.
