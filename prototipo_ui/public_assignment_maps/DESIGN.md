---
name: Public Assignment Maps
colors:
  surface: '#f7f9ff'
  surface-dim: '#d7dae0'
  surface-bright: '#f7f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f4fa'
  surface-container: '#ebeef4'
  surface-container-high: '#e5e8ee'
  surface-container-highest: '#dfe3e8'
  on-surface: '#181c20'
  on-surface-variant: '#414754'
  inverse-surface: '#2d3135'
  inverse-on-surface: '#eef1f7'
  outline: '#727785'
  outline-variant: '#c1c6d6'
  surface-tint: '#005bc0'
  primary: '#005bbf'
  on-primary: '#ffffff'
  primary-container: '#1a73e8'
  on-primary-container: '#ffffff'
  inverse-primary: '#adc7ff'
  secondary: '#006e2a'
  on-secondary: '#ffffff'
  secondary-container: '#8ffa9b'
  on-secondary-container: '#00752d'
  tertiary: '#b81d17'
  on-tertiary: '#ffffff'
  tertiary-container: '#dc392c'
  on-tertiary-container: '#ffffff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc7ff'
  on-primary-fixed: '#001a41'
  on-primary-fixed-variant: '#004493'
  secondary-fixed: '#8ffa9b'
  secondary-fixed-dim: '#73dc82'
  on-secondary-fixed: '#002108'
  on-secondary-fixed-variant: '#00531e'
  tertiary-fixed: '#ffdad5'
  tertiary-fixed-dim: '#ffb4a9'
  on-tertiary-fixed: '#410001'
  on-tertiary-fixed-variant: '#930004'
  background: '#f7f9ff'
  on-background: '#181c20'
  surface-variant: '#dfe3e8'
typography:
  display-sm:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: '0'
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: '0'
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: 0.01em
  title-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.01em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.015em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system is engineered for education assistants, substitute educators, and administrative school personnel participating in fast-paced public assignment events (*actos públicos*). The operational context is high-stress, mobile-first, and time-critical: candidates must rapidly locate institutions, calculate transit viability, inspect vacancy quotas, and commit to selections within seconds.

The aesthetic fuses Google's utility-first Material Design 3 guidelines with the pragmatic cartographic clarity of Google Maps. 

- **Personality:** Trustworthy, swift, systematic, and clear.
- **Visual Style:** Modern utility driven by crisp white floating surface sheets (`#FFFFFF`), Google blue functional focal points, unmistakable crimson map anchors (`#EA4335`), and legible typographic hierarchy that prevents cognitive overload in bright outdoor or crowded indoor assignment halls.

## Colors

The palette establishes instant recognition and high legibility across mobile displays:

- **Primary (`#1A73E8`):** The primary interaction anchor. Used for primary floating action buttons, focused input rings, selected chip backgrounds, transit route polylines, and active bottom navigation states.
- **Secondary (`#1E8E3E`):** Represents verified vacancies, open quotas, affirmative availability, and confirmed post selections.
- **Tertiary (`#EA4335`):** Reserved exclusively for map pins, urgent deadlines, vacancy expiration alerts, and error states.
- **Neutral (`#5F6368`):** Supports tertiary metadata, unselected icons, and secondary annotations.
- **Surfaces & Backgrounds:**
  - Base Map Canvas: `#F8F9FA`
  - Floating Sheets & Cards: `#FFFFFF`
  - Subtle Dividing Borders: `#E0E2E6`
  - Neutral High Text (Headline / Title): `#202124`
  - Selected Chip Container Surface: `#E8F0FE` (with `#1A73E8` label/icon)

## Typography

Typographic scale is constructed for high-scan utility using Inter. Numbers, shift designations (e.g., *Mañana*, *Tarde*), and school IDs (*E.E.S. Nº 14*) require instant distinction. 

- Numerics use tabular lining figures where comparisons occur (distance, quota counts, hours).
- Body copy remains strictly high contrast (`#202124` on `#FFFFFF` surfaces).
- `label-sm` is employed for pill tags denoting assignment turns, school categories, and transit durations.

## Layout & Spacing

The layout treats the cartographic engine as a dynamic base layer beneath responsive floating overlays.

- **Mobile Viewport Structure:**
  - Standard edge safe margins of `margin` (1rem / 16px).
  - Floating top search and filter app-bar spans the screen width minus `margin` on each side.
  - Interactive bottom sheet spans 100% of viewport width on mobile, docked with safe-area insets.
  - Horizontally scrolling filter chip carousels sit decoupled below the search bar with `space-sm` vertical gap and bleed gracefully through screen margins.
- **Touch Targets:**
  - All interactive elements adhere to a strict minimum hit area of 48×48px.

## Elevation & Depth

Visual hierarchy leverages crisp floating surfaces lifted above the map canvas using diffuse ambient shadows and faint low-contrast borders to preserve separation on high-brightness mobile screens:

- **Level 0 (Map Background):** Flat canvas (`#F8F9FA`).
- **Level 1 (Docked Bottom Sheet collapsed & static cards):** `0px 1px 3px rgba(60, 64, 67, 0.12), 0px 1px 2px rgba(60, 64, 67, 0.08)`, bounded by a 1px solid border in `#E0E2E6`.
- **Level 2 (Floating Filter Bar & Unfocused Search Bar):** `0px 2px 6px rgba(60, 64, 67, 0.15), 0px 1px 2px rgba(60, 64, 67, 0.10)`.
- **Level 3 (Focused Search Bar & Active Modal Bottom Sheets):** `0px 4px 12px rgba(60, 64, 67, 0.18), 0px 1px 3px rgba(60, 64, 67, 0.12)`.
- **Level 4 (Primary Action Buttons / Floating Re-center FAB):** `0px 6px 16px rgba(60, 64, 67, 0.20), 0px 2px 4px rgba(60, 64, 67, 0.12)`.

## Shapes

The design system implements a pill-shaped and rounded Material 3 aesthetic:

- **Search Capsules & Buttons:** Complete pill shape (`rounded-full`, 9999px / `1rem` base tokens) to mimic Google Maps search interfaces.
- **Filter Chips:** Full pill radius (`rounded-full`) for quick tactile scanning.
- **Floating Bottom Sheets & Facility Cards:** Top corners take `rounded-xl` (1.75rem / 28px) for sheet surfaces, while cards inside use `rounded-lg` (1rem / 16px) for approachable density.
- **Map Pin Markers:** Teardrop anchor markers terminating in a sharp coordinate base with rounded upper pin bulbs.

## Components

### Floating Search Bar
- **Structure:** Pill-shaped floating capsule (`#FFFFFF`) with search icon on the leading edge, voice/clear actions on the trailing edge.
- **Border & Shadow:** 1px border (`#E0E2E6`), Elevation Level 2.
- **Text:** Placeholder in `neutral_color_hex` (`#5F6368`), active query in `#202124`.

### Filter Chips
- **Inactive State:** Background `#FFFFFF`, 1px border `#DADCE0`, text `#3C4043` (`label-md`), height 32px, pill-shaped.
- **Active State:** Background `#E8F0FE`, border `#1A73E8`, text `#1A73E8` with a checkmark or down-caret icon.
- **Categories:** "Vacantes Disponibles" (Available Vacancies), "Turno Mañana/Tarde" (Shift), "Nivel Inicial/Primario/Secundario", "Radio de distancia" (Distance).

### Map Pins & Markers
- **Standard School Pin:** Teardrop red pin (`#EA4335`) containing an interior white graduation cap or building glyph.
- **Active / Selected School Pin:** Enlarged 1.25x with a `#1A73E8` outer ring pulse and elevation shadow.
- **Claimed / Taken Post:** Muted gray pin (`#9AA0A6`).

### School Assignment Bottom Sheet
- **Collapsed Peek View (Height ~140px):** Displays selected school name, district code, number of vacancies badge (`#E6F4EA` pill with `#1E8E3E` bold label), and quick transit time.
- **Expanded Detail View:** Draggable sheet pulling up to 90% screen height displaying:
  - Header: School name, direct phone, official ID number.
  - Roster Table: Available cargos (e.g., *Preceptor*, *Portería*, *Secretaría*), shift hours, vacancy source.
  - Action Bar: Primary "Postularme" button (`#1A73E8`, pill, text `#FFFFFF`) and secondary "Cómo llegar" (Directions) outline button.

### Form Inputs & Selectors
- Standard text fields use Material 3 outlined styling with 56px height, rounded corners (8px), `#5F6368` border idling to `#1A73E8` with a 2px stroke when focused.

### Status Badges
- **Available:** `#E6F4EA` background, `#137333` text (`label-sm`).
- **In Selection (*En Curso*):** `#FEF7E0` background, `#B06000` text.
- **Assigned (*Adjudicado*):** `#F1F3F4` background, `#5F6368` text.