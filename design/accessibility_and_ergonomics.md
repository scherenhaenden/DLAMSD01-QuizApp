# Accessibility, Ergonomics & Multi-Device Specification

## 1. Ergonomic Foundation & HIG Alignment

Apple's *Human Interface Guidelines* emphasize that mobile educational software must accommodate users operating under diverse physical contexts: sitting at a desk with an iPad, holding an iPhone with one hand on a moving bus, or navigating with assistive technologies.

---

## 2. Touch Target Metrics & Hit-Testing

### 2.1. Standard vs. Enhanced Hit Targets
- **Apple HIG Baseline:** Minimum touch target of $44 \times 44\,\text{pt}$.
- **Train-your-Brain Standard:** 
  - `AnswerButton`: Minimum height of **56 pt**, spanning 100% of the content container width with a minimum touchable area exceeding $16{,}800\,\text{pt}^2$ on iPhone.
  - Category selector cards: Minimum height of **80 pt**.
  - Primary Action Buttons: Height of **56 pt** with 14 pt rounded corner radius.

### 2.2. Thumb-Zone Optimization (One-Handed Use)
On iPhone devices, all primary interactive components (answer options and CTA buttons) are anchored in the **Natural Thumb Zone** (bottom two-thirds of the screen), while informational headers (category badge, timer, and score) are placed in the visual display zone at the top.

---

## 3. Dynamic Type & Scalable Typography

1. **Semantic Text Styles:** The app relies strictly on Apple's standard dynamic text styles (`.largeTitle`, `.title2`, `.headline`, `.subheadline`, `.body`, `.footnote`).
2. **Flexible Container Constraints:** Buttons do not use hardcoded heights that clip text. The `AnswerButton` enforces `minHeight: 56` with flexible vertical expansion (`fixedSize(horizontal: false, vertical: true)`), allowing multi-line questions and options to expand gracefully when accessibility font sizes (such as `Accessibility Large` or `AX1-AX5`) are enabled.
3. **Line Limits & Wrapping:** All answer prompts allow infinite wrapping (`lineLimit(nil)`) with `.multilineTextAlignment(.leading)`.

---

## 4. Visual Contrast & Color-Blindness Safeguards

### 4.1. WCAG 2.1 AA Verification
- Normal text (17pt Regular): Minimum contrast ratio of **4.5:1** against button surfaces.
- Large text (18pt Bold / 24pt Regular): Minimum contrast ratio of **3.0:1**.
- State feedback colors:
  - Success Green (`#34C759` light / `#30D158` dark): Evaluated against white and dark backgrounds to ensure contrast ratio $> 4.6:1$.
  - Error Red (`#FF3B30` light / `#FF453A` dark): Evaluated against backgrounds to ensure contrast ratio $> 4.8:1$.

### 4.2. Redundant Cues (Non-Color Dependent Feedback)
To support users with color vision deficiencies (such as Deuteranopia or Protanopia), feedback never relies solely on color:
- **Correct State:** Green border/fill **plus** a checkmark icon `[✓]` and an announcement banner.
- **Incorrect State:** Red border/fill **plus** a cross icon `[✕]` and immediate visual revelation of the true correct answer.

---

## 5. Haptic Feedback Design (Tactile Sensory System)

To reinforce cognitive feedback without requiring the user to look exclusively at text, native iOS haptics are integrated via `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator`:

| Interaction Event | Haptic Generator / Style | Sensory Objective |
| :--- | :--- | :--- |
| **Option Tapped (Neutral)** | `UIImpactFeedbackGenerator(style: .light)` | Subtle physical confirmation of touch registration. |
| **Correct Answer Evaluated**| `UINotificationFeedbackGenerator().notificationOccurred(.success)` | Dual distinct celebratory tap confirming positive retrieval. |
| **Incorrect Answer / Timeout**| `UINotificationFeedbackGenerator().notificationOccurred(.error)` | Triple sharp vibration alerting error for cognitive correction. |
| **Category Selection** | `UISelectionFeedbackGenerator().selectionChanged()` | Mechanical tick sensation during horizontal browsing. |

---

## 6. VoiceOver & Assistive Technology Specification

1. **Descriptive Labels:**
   - Instead of reading *"Button B"*, VoiceOver announces:  
     *„Option B: Model-View-ViewModel (MVVM). Double tap to select answer.“*
2. **State Announcements:**
   - Upon evaluation, an accessibility announcement is posted:  
     *„Correct. Your score increased to 150 points.“* or  
     *„Incorrect. The correct answer was Model-View-ViewModel.“*
3. **Timer Trait:**
   - The countdown timer is annotated with an accessibility update trait, providing periodic verbal cues at 10s and 5s rather than continuous intrusive second-by-second updates.
