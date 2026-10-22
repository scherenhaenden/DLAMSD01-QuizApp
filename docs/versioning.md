# Versioning Strategy & Release Specification

> **Documento de especificación técnica de versionado para DLAMSD01 (Train-your-Brain Quiz App).**  
> Define los estándares de nomenclatura de versiones, compatibilidad con los esquemas de Apple / Xcode y la trazabilidad temporal exigida por la IU International University of Applied Sciences.

---

## 1. Análisis de Alternativas de Versionado

Al planificar el versionado de una aplicación nativa iOS para un proyecto universitario, se evaluaron dos paradigmas principales:

### Alternativa A: CalVer con Marca Temporal (`yyyy.MM.dd-HH.mm.sss`)
* **Concepto:** Utilizar la fecha y hora exacta de compilación como identificador unívoco.
* **Ventajas:**
  * Trazabilidad cronológica inmediata: se identifica de un vistazo cuándo se construyó cada build.
  * Coherencia directa con la nomenclatura de entrega de trabajos de la IU (`YYYYMMDD_Project_Submission_...`).
  * Imposibilidad matemática de colisiones en compilaciones sucesivas.
* **Limitaciones técnicas en el ecosistema iOS:**
  * **Restricción de Apple (`Info.plist`):** Apple exige que la versión pública (`CFBundleShortVersionString`) contenga **únicamente números enteros separados por puntos** (formato `X.Y.Z`). No se permiten guiones (`-`), letras ni fracciones de segundo (`.sss`) si el paquete se valida contra las herramientas de verificación de Apple (`xcrun altool`).
  * **Comunicación de madurez:** No expresa el grado de avance funcional (si el proyecto está en fase alfa `0.1`, beta `0.8` o listo para entrega final `1.0.0`).

### Alternativa B: Semantic Versioning (SemVer 2.0.0: `MAJOR.MINOR.PATCH`)
* **Concepto:** Estándar de facto de la industria del software para comunicar compatibilidad y estabilidad.
* **Ventajas:**
  * Claridad metodológica: el evaluador académico reconoce de inmediato el ciclo de vida del software.
  * Compatibilidad total con los campos de versión de Xcode y Swift Package Manager.
* **Limitaciones:**
  * No refleja la fecha ni la hora de la compilación si no se acompaña de metadatos adicionales.

---

## 2. Estrategia Adoptada: Enfoque Híbrido Estándar Apple + IU

Para obtener lo mejor de ambos mundos (rigor técnico y compatibilidad nativa con Xcode), el proyecto adopta un **modelo híbrido de dos niveles**, alineado con la especificación de Apple:

```
┌─────────────────────────────────────────────────────────────┐
│                       APP VERSIONING                        │
├──────────────────────────────┬──────────────────────────────┤
│  Marketing Version (SemVer)  │   Build Number (CalVer/Time) │
│  CFBundleShortVersionString  │   CFBundleVersion            │
│  e.g., "1.0.0"               │   e.g., "20261022.0950"      │
└──────────────────────────────┴──────────────────────────────┘
```

### Nivel 1: Versión de Marketing / Pública (`CFBundleShortVersionString`)
Utiliza **Semantic Versioning** (`MAJOR.MINOR.PATCH`) para comunicar el estado del desarrollo en la interfaz de la app y en el informe académico:

| Versión | Fase del Proyecto | Alcance Técnico |
| :---: | :--- | :--- |
| **`0.1.0`** | Sprint 1 (Prototipo Inicial) | Estructura base MVVM, modelos `Codable` y decodificación de `questions.json`. |
| **`0.5.0`** | Sprint 2 (Core Gameplay) | Interfaz SwiftUI funcional, temporizador reactivo y flujo de preguntas. |
| **`0.9.0`** | Sprint 3 (Feature Complete) | Pantalla de resultados, persistencia con `UserDefaults` y Dark Mode. |
| **`1.0.0`** | Sprint 4 (Final Release IU) | Versión congelada para la entrega formal y capturas del *Projektbericht*. |

### Nivel 2: Número de Compilación / Build Interna (`CFBundleVersion`)
Utiliza **Calendar Versioning numérico** (`YYYYMMDD.HHmm`), satisfaciendo la propuesta de marca temporal del desarrollador de forma 100% compatible con Apple:

* **Sintaxis:** `YYYYMMDD.HHmm`
* **Ejemplo:** `20261022.0950` (Compilación generada el 22 de octubre de 2026 a las 09:50).
* **Propiedades:**
  * Estrictamente monótona creciente (cada build posterior tiene un número mayor).
  * Válida bajo los estándares del App Store / TestFlight de Apple.
  * Rastreo exacto del commit o build ejecutada en el simulador.

---

## 3. Convención de Etiquetas en Git (Git Tags)

Para marcar hitos clave en el repositorio Git, se combinan ambos identificadores en los tags:

```bash
# Formato de tag
v<SemVer>+<BuildNumber>

# Ejemplos prácticos:
git tag -a v0.1.0 -m "Release 0.1.0 (Build 20261022.1000): Initial core logic"
git tag -a v1.0.0 -m "Release 1.0.0 (Build 20261025.1830): Final submission candidate for IU"
```

---

## 4. Configuración Práctica en Xcode (`Info.plist`)

En el archivo de configuración del proyecto (`project.pbxproj` / Target General Settings):

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<key>CFBundleVersion</key>
<string>20261022.0950</string>
```

Y en la vista de pie de página (*Footer*) o en el menú de la app, se mostrará al usuario y al evaluador:
```text
Train-your-Brain v1.0.0 (Build 20261022.0950)
```

---

## 5. Resumen Justificativo para el Projektbericht

En el capítulo de **Implementación y Gestión de Configuración** del informe académico, esta decisión se justifica formalmente:

> *"Para la gestión de versiones se adoptó un enfoque híbrido en cumplimiento estricto de las directrices de Apple. Se asignó una versión semántica (SemVer) como `CFBundleShortVersionString` para clasificar las fases de madurez del software (desde el prototipo `0.1.0` hasta la versión final `1.0.0`), complementada por un número de build basado en Calendar Versioning (`CFBundleVersion`, formato `YYYYMMDD.HHmm`). Este esquema garantiza una trazabilidad temporal absoluta de cada compilación sin infringir los requisitos sintácticos de validación del sistema operativo iOS."*
