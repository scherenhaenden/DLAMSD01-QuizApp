# Versioning Strategy & Release Specification

> **Technical Versioning Specification for DLAMSD01 (Train-your-Brain Quiz App).**  
> Defines version naming standards, compatibility with Apple / Xcode build toolchains, and chronological traceability required by IU International University of Applied Sciences.

---

## 1. Analysis of Versioning Approaches

When designing the release and version management pipeline for a native iOS application within an academic degree project, two primary paradigms were evaluated:

### Approach A: Pure Calendar Versioning with Timestamps (`yyyy.MM.dd-HH.mm.sss`)
* **Concept:** Using the exact build compilation date and time as a unique identifier.
* **Advantages:**
  * Immediate chronological traceability: reveals at a glance when a specific build was compiled.
  * Direct structural alignment with IU examination submission naming conventions (`YYYYMMDD_Flores_Edward_...`).
  * Mathematical impossibility of build identifier collisions across successive compilations.
* **Technical Constraints within the Apple / iOS Ecosystem:**
  * **Apple Syntax Restriction (`Info.plist`):** Apple mandates that the public marketing version (`CFBundleShortVersionString`) must consist **strictly of period-separated integers** (format `X.Y.Z`). Hyphens (`-`), alphabetic characters, and sub-second fractions (`.sss`) are rejected by Apple validation toolchains (`xcrun altool` and App Store Connect).
  * **Maturity Communication:** Timestamp strings do not express functional maturity levels (e.g. distinguishing an alpha prototype `0.1`, a feature-complete beta `0.8`, or an exam-submission candidate `1.0.0`).

### Approach B: Semantic Versioning (SemVer 2.0.0: `MAJOR.MINOR.PATCH`)
* **Concept:** The de facto software industry standard for signaling backward compatibility and release stability.
* **Advantages:**
  * Methodological clarity: academic evaluators immediately identify the software lifecycle stage.
  * Native compatibility with Xcode project build settings and Swift Package Manager version requirements.
* **Limitations:**
  * Does not inherently encode the exact build timestamp unless supplemented by secondary metadata.

---

## 2. Adopted Architecture: Two-Tier Hybrid Strategy (Apple + IU Standard)

To achieve both academic traceability and native Xcode compatibility, the project adopts a **two-tier hybrid versioning model** strictly adhering to Apple platform guidelines:

```
┌─────────────────────────────────────────────────────────────┐
│                       APP VERSIONING                        │
├──────────────────────────────┬──────────────────────────────┤
│  Marketing Version (SemVer)  │   Build Number (CalVer/Time) │
│  CFBundleShortVersionString  │   CFBundleVersion            │
│  e.g., "1.0.0"               │   e.g., "20261022.0950"      │
└──────────────────────────────┴──────────────────────────────┘
```

### Tier 1: Marketing / Public Version (`CFBundleShortVersionString`)
Uses **Semantic Versioning** (`MAJOR.MINOR.PATCH`) to communicate functional milestones in the user interface and academic deliverables:

| Version | Project Milestone | Technical Scope & Deliverables |
| :---: | :--- | :--- |
| **`0.1.0`** | Sprint 1 (Architecture & Data Core) | Base MVVM structure, `Codable` domain models, `questions.json` decoding, and TDD test suite. |
| **`0.5.0`** | Sprint 2 (Core Gameplay UI) | Interactive SwiftUI screens, dynamic countdown timer, and color-coded answer feedback. |
| **`0.8.0`** | Sprint 3 (Persistence & Ergonomics) | Results dashboard, high-score tracking via `UserDefaults`, and Dark Mode support. |
| **`1.0.0`** | Sprint 4 (Final Academic Release) | Code freeze, comprehensive test execution logs, and submission candidate for IU examination. |

### Tier 2: Internal Build Number (`CFBundleVersion`)
Uses **Monotonic Numeric Calendar Versioning** (`YYYYMMDD.HHmm`), satisfying granular timestamp tracking while complying 100% with Apple syntax:

* **Syntax:** `YYYYMMDD.HHmm`
* **Example:** `20261022.0950` (Build generated on October 22, 2026 at 09:50).
* **Properties:**
  * Strictly monotonically increasing (each subsequent compilation produces a higher integer value).
  * Validated against Apple App Store Connect and TestFlight verification rules.
  * Unambiguous correlation between code commits, simulator runs, and physical iPad testing sessions.

---

## 3. Git Tagging Conventions

To mark milestone releases in the Git repository, both identifiers are combined:

```bash
# Tag naming convention
v<SemVer>+<BuildNumber>

# Concrete release examples:
git tag -a v0.1.0 -m "Release 0.1.0 (Build 20261022.1000): Initial core logic and domain tests"
git tag -a v1.0.0 -m "Release 1.0.0 (Build 20261025.1830): Final submission candidate for IU examination"
```

---

## 4. Xcode Project Configuration (`Info.plist`)

Within target build settings (`project.pbxproj` / Target General Settings):

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<key>CFBundleVersion</key>
<string>20261022.0950</string>
```

In the app footer or settings screen, the version string displays as:
```text
Train-your-Brain v1.0.0 (Build 20261022.0950)
```

---

## 5. Methodological Justification for the Projektbericht

In the **Implementation and Configuration Management** chapter of the academic project report, this architecture is justified formally:

> *"To manage software releases, a two-tier hybrid versioning model was implemented in strict accordance with Apple Human Interface Guidelines and App Store packaging standards. A semantic versioning scheme (SemVer) was assigned to `CFBundleShortVersionString` to classify lifecycle maturity (from initial prototype `0.1.0` to final delivery `1.0.0`), complemented by a monotonic calendar-based build number (`CFBundleVersion`, format `YYYYMMDD.HHmm`). This strategy guarantees absolute chronological traceability for each test build while fully respecting the syntax validation constraints of the iOS operating system."*
