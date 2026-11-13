# SpaceMac - Recupera tu Mac

![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![【entity-Apple¦canonical_name=Apple】 Silicon](https://img.shields.io/badge/Apple_Silicon-M1_M2_M3-black)
![License](https://img.shields.io/badge/License-Propietario-lightgrey)

**SpaceMac** es una app real para Mac, hecha en Swift, para liberar espacio sin romper tu sistema ni tus apps.

No es un MVP. Es modular, escalable y segura por diseño.

> **Seguridad primero:** Si SpaceMac no está seguro de un archivo, **NO LO BORRA**. Lo marca como NO BORRABLE.

---

## ✨ ¿Qué hace?

- Escanea todo tu Mac, incluyendo archivos ocultos
- Te muestra nombre, ruta, tamaño, fecha y categoría de cada archivo
- Te deja borrar archivo por archivo, o solo los que tú seleccionas
- Nunca tiene botón de **Borrar Todo**
- Detecta duplicados inteligentes por contenido, no por nombre
- Encuentra el **Espacio Hormiga**: miles de archivos chiquitos que juntos son gigas
- Tiene IA integrada, gratis, on-device, offline, sin API key ni cuenta
- Te avisa cuando te queda poco espacio, sin spam
- Guarda historial de todo lo que borraste

---

## 🛡️ R01 - Seguridad, lo más importante

SpaceMac **NUNCA** toca:

- `/System`
- Kernel y archivos del sistema
- `/Applications/*.app` - Tus apps instaladas
- `Application Support`
- Extensiones de VS Code
- Presets de 【entity-Adobe¦canonical_name=Adobe】

Si un archivo es del sistema, se marca en rojo como **🔴 No tocar** y no se puede seleccionar ni borrar.

Si no estamos seguros, se marca como **NO BORRABLE**.

---

## 📋 Requisitos - R01 a R15

| ID | Requisito | Estado |
| :--- | :--- | :---: |
| **R01** | No dañar sistema ni apps del usuario | ✅ |
| **R02** | Sin botón Borrar Todo, siempre revisar antes de borrar | ✅ |
| **R03** | Carpetas Privadas excluidas de escaneo / lista / borrado - Premium, ilimitadas | ✅ |
| **R04** | Escaneo total de todo el Mac, incluyendo ocultos | ✅ |
| **R05** | Lista con nombre, ruta, tamaño, fecha, categoría + buscador + filtros + orden por tamaño | ✅ |
| **R06** | Permisos solo cuando se necesitan, explicados en palabras simples, sin cuenta / login | ✅ |
| **R07** | IA integrada, gratis, on-device, offline, sin API key | ✅ |
| **R08** | Duplicados Inteligentes gratis - exactos, similares, versiones, dev | ✅ |
| **R09** | Rutas por perfil: Web + Mobile iOS + 【entity-Android¦canonical_name=Android】 + React Native + Backend, Devs, Diseñadores, Arquitectos | ✅ |
| **R10** | Historial de limpieza gratis, local | ✅ |
| **R11** | Aviso de poco espacio gratis, sin spam, 1 vez cada 24h | ✅ |
| **R12** | Feature Flags desde el inicio | ✅ |
| **R13** | Listo para Mac App Store, Sandbox, privacidad | 🚧 |
| **R14** | Pago al final, modelo definido desde el inicio | ✅ |
| **R15** | Modelo Premium: solo Carpetas Privadas ilimitadas es Premium | ✅ |

---

## 🐜 Espacio Hormiga

Miles de archivos chiquitos que juntos son gigas. Ejemplo: `DerivedData`, `CoreSimulator`, `Caches`.

SpaceMac no te deja borrar la carpeta entera. Entras a la carpeta, ves la lista de archivos, y borras uno por uno o solo los que seleccionas.

Con carga en vivo, progreso y botón de Cancelar, para que no se sienta que se trabó.

---

## 📄 Duplicados Inteligentes - R08 Gratis

- **Exactos:** Mismo contenido, mismo hash
- **Similares:** Mismo nombre, diferente contenido
- **Versiones:** `archivo_v1`, `archivo_v2`, `archivo_final_FINAL`
- **Dev:** `node_modules` duplicados, `DerivedData` duplicados

**Nunca borra el original.** El original es el primero de cada grupo y no se puede seleccionar.

Comparación por **hash de contenido**, no por nombre.

---

## 🗺️ Rutas - R09

Todos pueden usar todas las rutas, no hay bloqueo por perfil.

- **Dev Web + Mobile:** iOS + 【entity-Android¦canonical_name=Android】 + React Native + Backend
- **Diseñador:** 【entity-Adobe¦canonical_name=Adobe】, 【entity-Figma¦canonical_name=Figma】, cachés de diseño
- **Arquitecto:** CAD, renders, modelos 3D
- **Usuario común:** Descargas, Escritorio, Documentos

---

## 🤖 IA - R07 Gratis, On-Device

- **Opción A:** La app descarga el modelo de ~1GB la primera vez que lo usas
- Se guarda en `Application Support / SpaceMac`
- Con progreso, pausa y resume
- **Sin API key, sin cuenta, sin suscripción, sin internet después de descargarlo**

Si la IA no está descargada, SpaceMac sigue funcionando con reglas R01.

En la lista se ve así:
- Sin IA: `Seguro por regla` / `Revisar - Sin IA`
- Con IA: `Seguro por IA` / `Revisar con IA`

---

## 💎 Premium - R15

**Gratis incluye:**
- Escaneo total
- Lista completa + buscador + filtros
- IA on-device
- Protección R01
- Sin Borrar Todo
- Rutas básicas
- Historial básico
- Aviso de poco espacio
- Perfiles guardados
- Duplicados completos
- Soporte prioritario + updates tempranos

**Solo Premium:**
- Carpetas Privadas ilimitadas

En Gratis tienes **1 carpeta privada de prueba**.

**Sin** limpieza programada. Se quitó del proyecto a propósito.

---

## 🛠️ Cómo correrlo

### Requisitos

- Mac con 【entity-Apple¦canonical_name=Apple】 Silicon M1 o superior
- macOS 14.0 o superior
- Xcode 15 o superior
- 256 GB de disco recomendado, 18 GB libres mínimo para probar

### Pasos

```bash
git clone https://github.com/EriickChavez/SpaceMac.git
cd SpaceMac
open SpaceMac.xcodeproj
