# Design System, UI Guidelines & Visual Tokens

## 1. Design Philosophy

The visual and interaction design of **Train-your-Brain** is guided by three core principles derived from Apple's Human Interface Guidelines (HIG) and evidence-based learning ergonomics:

1. **Clarity over Decoration (Distraction-Free Learning):**
   Every UI element directly serves comprehension. Excessive illustrations, heavy shadows, and decorative clutter are intentionally avoided so that the user's cognitive bandwidth remains focused on the question prompt and technical options (Cognitive Load Theory).

2. **Immediate & Unambiguous Feedback:**
   Microlearning relies on tight feedback loops. Responses must be acknowledged instantaneously via color transformation, tactile haptic response, and clear status indicators before automatically advancing to the next challenge.

3. **Universal Accessibility & Ergonomics:**
   The interface adapts seamlessly between the compact one-handed ergonomics of an iPhone (e.g., during transit) and the expansive desk workspace of an iPad (9th generation, 10.2"). Full support for Dynamic Type and high-contrast Light/Dark mode ensures readability under all lighting conditions.

---

## 2. Color Palette & Semantic Design Tokens

Colors are defined semantically where system adaptation is appropriate. Correct and incorrect answer fills use fixed, measured high-contrast values in both appearances.

| Token Name | Light Mode (Hex / RGB) | Dark Mode (Hex / RGB) | Semantic Role & Context |
| :--- | :--- | :--- | :--- |
| **`brandPrimary`** | `#0066CC` `(0, 102, 204)` | `#2997FF` `(41, 151, 255)` | Primary navigation tint, active category highlights, and progress anchors. |
| **`brandSecondary`** | `#5E5CE6` `(94, 92, 230)` | `#7D7AFF` `(125, 122, 255)` | Category chips, subtle gradient accents, and secondary button borders. |
| **`stateCorrect`** | `#1B5E20` `(27, 94, 32)` | `#1B5E20` `(27, 94, 32)` | High-contrast feedback fill for a correct answer choice. |
| **`stateIncorrect`** | `#B71C1C` `(183, 28, 28)` | `#B71C1C` `(183, 28, 28)` | High-contrast feedback fill for a wrong pick or timeout. |
| **`stateWarning`** | `#FF9500` `(255, 149, 0)` | `#FF9F0A` `(255, 159, 10)` | Timer urgency state when less than 5 seconds remain on the countdown bar. |
| **`bgBase`** | `#F2F2F7` (System Grouped) | `#000000` (Pure Black) | Canvas background across screens. |
| **`bgCard`** | `#FFFFFF` (Card Surface) | `#1C1C1E` (Dark Elevated) | Question cards and answer option surfaces. |
| **`textPrimary`** | `#000000` (100% Opacity) | `#FFFFFF` (100% Opacity) | Question prompts and primary answer text. |
| **`textSecondary`**| `#6C6C70` (Secondary Label)| `#8E8E93` (Secondary Label)| Category indicators, question counters, timer labels. |

---

## 3. Typography & Dynamic Type Scale

All textual components use the native Apple System Font (*San Francisco*) with standard semantic text styles. Hardcoded font sizes are strictly forbidden to ensure full compatibility with iOS **Dynamic Type**.

| Text Style | Target Size / Weight | Line Height | Usage in App |
| :--- | :--- | :--- | :--- |
| **`Large Title`** | 34pt / Bold | 41pt | Screen headers (`Train-your-Brain`, `Quiz Completed`) |
| **`Title 2`** | 22pt / Bold | 28pt | Active question prompt inside `QuestionCard` |
| **`Headline`** | 17pt / Semibold | 22pt | Answer option text inside `AnswerButton` |
| **`Subheadline`**| 15pt / Regular | 20pt | Category badges, streak counter, score status |
| **`Footnote`** | 13pt / Regular | 18pt | Explanations, timer seconds indicator |
| **`Caption 1`** | 12pt / Medium | 16pt | Difficulty badge (`Easy`, `Medium`, `Hard`) |

---

## 4. Layout, Spacing & Touch Ergonomics

### 4.1. 4-Point Grid Metric
All margins, paddings, and component dimensions adhere to a 4-point spacing scale:
- **`4pt`**: Inner icon-to-label spacing.
- **`8pt`**: Spacing between category badges and question counters.
- **`12pt`**: Vertical spacing between individual `AnswerButton` components.
- **`16pt`**: Standard content padding from screen boundaries on iPhone.
- **`20pt`**: Vertical gap between question card and answer stack.
- **`24pt`**: Card inner padding.
- **`32pt`**: Top/bottom section separation.

### 4.2. Touch Targets & Ergonomic Margins
- **Minimum Touch Target:** According to Apple HIG, interactive controls require a minimum target area of $44 \times 44\,\text{pt}$.
- **Implemented Standard:** `AnswerButton` components are engineered with a **minimum height of 56 pt** and full container width. This larger tap area minimizes error taps when the user is walking or commuting.
- **Corner Radii:**
  - `AnswerButton`: **14 pt** (smooth rounded continuous curves / squircle).
  - `QuestionCard`: **20 pt** with subtle border stroke (`0.5 pt` separator color).
  - Badges / Chips: **8 pt** capsule styling.

---

## 5. Multi-Device Adaptability: iPhone vs. iPad (9th Gen)

| Metric | iPhone (Compact Size Class) | Apple iPad 9th Gen (Regular Size Class) |
| :--- | :--- | :--- |
| **Display Size** | 4.7" (SE) to 6.7" (15 Pro Max) | 10.2" Retina (2160 × 1620 px @ 264 ppi) |
| **Max Content Width** | 100% of readable width | **Constrained to 640 pt centered** |
| **Orientation** | Portrait optimized | Portrait and Landscape fluid layout |
| **Option Button Layout** | Single vertical column | Single vertical column with generous touch width |
| **Padding** | 16 pt horizontal safe area | 32 pt outer padding with centered hero canvas |
