# Stanomer Brand Identity & UI Consistency Rule

When creating any new screen, tab, modal, card, badge, or component — or updating existing UI — **always follow the Stanomer Brand Kit** instead of default Tailwind hues (`indigo-*`, `blue-*`, cold `slate-*`).

## Core Color Tokens (Web & Agency Panel)
- **Primary Brand Blue:** `#1B5888` (hover/active: `#12406A`)
- **Primary Soft Tint:** `#E5EEF6` (selected tabs, soft CTA backgrounds, active badges, paired with `text-[#1B5888]` and `border-[#1B5888]/25`)
- **Warm Neutral Surfaces & Borders:**
  - Card & control borders: `#E5E3DF`
  - Subtle surface / hover background: `#F8F7F5`
  - Primary text: `#1A1A1A`
  - Secondary text: `#4A4A4A`
  - Muted / label text: `#666666` and `#8A8A8A`
- **Semantic Status Colors:**
  - Success / Realized / Occupied: `bg-[#EAF5EE] text-[#2A6E43] border-[#2A6E43]/20`
  - Warning / Pending / Locked: `bg-[#FBF1DC] text-[#8A5206] border-[#8A5206]/20`
  - Destructive / Cancelled / Overdue: rose/red semantic tokens (`bg-rose-50 text-rose-700 border-rose-200`)

## Geometry & Component Conventions
- **Cards & Containers:** `bg-white rounded-[10px] border border-[#E5E3DF] shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)]` (or `rounded-xl` for modals/inner controls).
- **Primary CTA Button:** `bg-[#1B5888] hover:bg-[#12406A] text-white font-semibold rounded-[10px]`.
- **Secondary Branded Button:** `bg-[#E5EEF6] hover:bg-[#1B5888] hover:text-white text-[#1B5888] border border-[#1B5888]/25 font-semibold rounded-[10px]`.
- **Neutral Button:** `bg-white hover:bg-[#F8F7F5] text-[#1A1A1A] border border-[#E5E3DF] font-semibold rounded-[10px]`.
- **Never introduce `indigo-*` or off-brand accent colors** for primary actions, tabs, badges, or focus rings.

## Copy & Typography Rules
- **Never use em-dashes (`—`)** in UI copy, labels, descriptions, or translations. Use a colon (`:`), comma (`,`), or short hyphen (`-`) instead.
