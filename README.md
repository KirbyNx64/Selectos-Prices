<p align="center">
  <img src="assets/icon_foreground.png" alt="Selectos Prices" width="128" />
</p>

# Selectos Prices

Aplicación móvil desarrollada en Flutter para la consulta rápida de precios, verificación de existencias por sala de venta y gestión de listas de compras en Súper Selectos (El Salvador).

---

## Características

- **Búsqueda en tiempo real:** Encuentra productos al instante con autocompletado y filtros de búsqueda.
- **Escáner de código de barras:** Utiliza la cámara del dispositivo para escanear productos directamente en los pasillos del supermercado.
- **Catálogo por categorías:** Navega a través de las categorías y subcategorías oficiales de Súper Selectos.
- **Precios y existencias por sala:** Consulta la disponibilidad y el precio exacto según la sala de venta seleccionada en cualquier departamento del país.
- **Detalle de ofertas:** Identificación de promociones (2x1, descuentos en segunda unidad, rebajas especiales).
- **Lista de compras y presupuesto:** Base de datos local (SQLite) para guardar listas sin conexión, ajustar cantidades y calcular el total proyectado de la compra.
- **Diseño moderno (Material 3 Expressive):** Interfaz adaptada con soporte para tema claro y tema oscuro, animaciones fluidas y soporte completo para Edge-to-Edge y navegación por gestos en Android 16.
- **Actualizaciones integradas (OTA):** Comprobación automática de versiones en GitHub con descarga e instalación directa del paquete APK correspondiente a la arquitectura del procesador.

---

## Tecnologías utilizadas

- **Framework:** [Flutter](https://flutter.dev/) (SDK ^3.13.5 / Dart 3)
- **UI:** [Material 3 Expressive](https://pub.dev/packages/material_3_expressive), `smooth_page_indicator`, `cached_network_image`, `flutter_svg`
- **Escáner de cámara:** [mobile_scanner](https://pub.dev/packages/mobile_scanner)
- **Almacenamiento local:** [sqflite](https://pub.dev/packages/sqflite), [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Actualizaciones OTA:** [ota_update](https://pub.dev/packages/ota_update), `http`

---

## Requisitos previos

- Flutter SDK (versión 3.13 o superior)
- Android SDK (compileSdk 37 / Android 16)
- Java JDK 17
- Dispositivo Android con depuración USB habilitada o emulador configurado

---

## Instalación y ejecución local

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/KirbyNx64/Selectos-Prices.git
   cd Selectos-Prices
   ```

2. Instalar las dependencias de Flutter:
   ```bash
   flutter pub get
   ```

3. Ejecutar la aplicación en modo desarrollo:
   ```bash
   flutter run
   ```

4. Ejecutar pruebas unitarias y de widgets:
   ```bash
   flutter test
   ```

---

## Compilación para producción

### Compilación dividida por arquitectura (Recomendado)
Genera APKs individuales y más livianos para cada arquitectura de procesador:
```bash
flutter build apk --split-per-abi
```
Los archivos compilados se encontrarán en:
- `build/app/outputs/apk/release/Selectos-Prices-v<version>-arm64-v8a.apk` (Mayoría de teléfonos modernos)
- `build/app/outputs/apk/release/Selectos-Prices-v<version>-armeabi-v7a.apk` (Teléfonos antiguos de 32 bits)
- `build/app/outputs/apk/release/Selectos-Prices-v<version>-x86_64.apk` (Emuladores y dispositivos x86_64)

### Compilación universal
Genera un único APK compatible con todas las arquitecturas:
```bash
flutter build apk --release
```
El archivo se generará en:
- `build/app/outputs/apk/release/Selectos-Prices-v<version>-universal.apk` (o `build/app/outputs/flutter-apk/app-release.apk`)

---

## Descargo de responsabilidad

Esta aplicación ha sido desarrollada de forma independiente con **fines estrictamente educativos y de aprendizaje personal**.

- **Sin fines de lucro:** Este proyecto no se vende, no se comercializa ni genera ningún tipo de beneficio económico.
- **Distribución:** La aplicación no está disponible ni se distribuye en Google Play Store ni en ninguna otra tienda de aplicaciones oficial o de terceros.
- **Sin afiliación:** No guarda relación, afiliación, patrocinio ni vínculo comercial alguno con **Grupo Calleja, S.A. de C.V.** ni con la cadena **Súper Selectos**.
- **Propiedad intelectual:** Todos los nombres comerciales, marcas registradas, logotipos e imágenes de productos referenciados pertenecen exclusivamente a sus respectivos titulares y se utilizan únicamente con fines ilustrativos y demostrativos dentro del contexto de este proyecto de aprendizaje.
