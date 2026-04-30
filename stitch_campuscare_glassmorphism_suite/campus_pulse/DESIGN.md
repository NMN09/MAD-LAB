---
name: Campus Pulse
colors:
  surface: '#f7f9fc'
  surface-dim: '#d8dadd'
  surface-bright: '#f7f9fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f7'
  surface-container: '#eceef1'
  surface-container-high: '#e6e8eb'
  surface-container-highest: '#e0e3e6'
  on-surface: '#191c1e'
  on-surface-variant: '#434652'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f4'
  outline: '#737783'
  outline-variant: '#c3c6d4'
  surface-tint: '#2b5bb5'
  primary: '#003178'
  on-primary: '#ffffff'
  primary-container: '#0d47a1'
  on-primary-container: '#a1bbff'
  inverse-primary: '#b0c6ff'
  secondary: '#785900'
  on-secondary: '#ffffff'
  secondary-container: '#fdc003'
  on-secondary-container: '#6c5000'
  tertiary: '#720009'
  on-tertiary: '#ffffff'
  tertiary-container: '#9d0010'
  on-tertiary-container: '#ffa59c'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d9e2ff'
  primary-fixed-dim: '#b0c6ff'
  on-primary-fixed: '#001945'
  on-primary-fixed-variant: '#00429c'
  secondary-fixed: '#ffdf9e'
  secondary-fixed-dim: '#fabd00'
  on-secondary-fixed: '#261a00'
  on-secondary-fixed-variant: '#5b4300'
  tertiary-fixed: '#ffdad6'
  tertiary-fixed-dim: '#ffb4ac'
  on-tertiary-fixed: '#410003'
  on-tertiary-fixed-variant: '#93000e'
  background: '#f7f9fc'
  on-background: '#191c1e'
  surface-variant: '#e0e3e6'
typography:
  h1:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  h2:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  h3:
    fontFamily: Space Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.4'
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-padding: 20px
  gutter: 16px
  stack-sm: 12px
  stack-md: 24px
  stack-lg: 40px
---

## Brand & Style

This design system is engineered to foster a sense of institutional reliability while embracing cutting-edge mobile aesthetics. The brand personality is rooted in professional transparency and tech-forward efficiency, ensuring students and staff feel empowered to maintain their environment.

The visual style is defined by **Glassmorphism**. By utilizing multi-layered translucent surfaces and high-refraction background blurs, the interface creates a sense of depth and spatial awareness. This approach moves away from flat, static layouts toward a dynamic "living" interface that mirrors the fluid nature of campus life. Motion is treated as a first-class citizen, using spring-based physics for transitions to reinforce the premium, responsive feel of the application.

## Colors

The palette balances authority with visibility. **Deep Navy** serves as the anchor, providing a stable foundation for institutional trust. **Gold** is reserved for high-value interactions and critical highlights, ensuring that primary actions stand out against the glass layers.

For administrative contexts, **Deep Crimson** is introduced to signify urgency and elevated permissions, creating a clear psychological distinction between general reporting and crisis management. The background utilizes **Soft Grey** to reduce eye strain and provide a neutral canvas that allows the semi-transparent glass components to "pop" via contrast and blur.

## Typography

The typographic hierarchy prioritizes rapid information scanning. Headings utilize **Space Grotesk** (serving the 'Outfit' geometric style) to provide a modern, technical edge that feels academic yet innovative. Tight letter spacing in headings maintains a compact, premium look on mobile screens.

**Inter** is employed for all body and instructional text to ensure maximum legibility at smaller sizes. The use of a generous line height (1.5x - 1.6x) for body text prevents information density from becoming overwhelming during high-stress reporting scenarios.

## Layout & Spacing

This design system employs a **Fluid Grid** model optimized for edge-to-edge mobile experiences. A standard 8px baseline grid ensures vertical rhythm across all components. 

The layout relies on a 4-column structure for mobile, with a default 20px margin to provide breathing room for the semi-transparent glass cards. Spacing between elements is strictly categorized into "stacks" to maintain consistency: 12px for related items within a card, 24px for distinct sections, and 40px for major content transitions.

## Elevation & Depth

Elevation is achieved through a combination of **Backdrop Blurs** and **Ambient Shadows**. Instead of traditional drop shadows, this design system uses "Light-Leak Shadows"—highly diffused, low-opacity shadows that take on a slight tint of the background color.

- **Level 1 (Base):** Soft Grey background.
- **Level 2 (Cards):** Glass layers with a 20px blur and a 1px semi-transparent white border (0.2 opacity) to define edges.
- **Level 3 (Interactive):** Elements like Floating Action Buttons (FABs) use a stronger shadow with a 15% opacity Deep Navy tint to appear physically lifted above the glass cards.
- **Level 4 (Modals):** Full-screen blurs that desaturate the background to focus the user on the task at hand.

## Shapes

The shape language is consistently **Rounded**. A default 0.5rem (8px) radius is applied to standard inputs and small containers. Larger glass cards utilize a 1rem (16px) radius to soften the technological feel and make the app more approachable. 

Interactive elements such as Status Indicators and Chips follow a **Pill-shaped** (Full Radius) geometry to distinguish them from structural content. This contrast between the structured card shapes and the fluid pill shapes helps users instinctively identify clickable metadata.

## Components

### Buttons & FABs
Primary buttons are solid Deep Navy with Gold text or vice-versa for high emphasis. The Floating Action Button (FAB) is the primary entry point for reporting; it should be a perfect circle with a Gold background and a subtle Deep Navy icon.

### Glass Cards
The signature component. Cards must feature a background blur (min 16px) and a subtle 1px border. For "Urgent" reports, the border color shifts to Deep Crimson to catch the eye without breaking the glass aesthetic.

### Input Fields
Inputs are fully rounded with a Soft Grey fill (slightly darker than the background) and a subtle inner shadow. On focus, the border transitions to a 2px Gold stroke with a slight outer glow.

### Status Indicators
Pill-shaped chips using a semi-transparent version of the status color (e.g., Green for "Resolved", Gold for "In Progress"). Text inside chips must be bold and capitalized for legibility.

### Progress Fluidity
All state transitions (e.g., opening a report, submitting a form) must use a "Fluid-Ease" animation—a customized cubic-bezier curve `(0.22, 1, 0.36, 1)` that mimics the smooth movement of liquid glass.