# Enterprise ERP UI/UX Design Standard v3.0

> **Target Quality:** 9.8+/10 Enterprise Design Standard\
> Applies to desktop-first ERP systems built with Material 3 and modern
> flat design.

## Design Goals

-   Optimize for speed, accuracy, confidence, and consistency.
-   Design for completing business transactions, not displaying database
    fields.
-   Every control must justify its existence.

------------------------------------------------------------------------

# Layout System

## Grid

-   Desktop: 12-column grid
-   Tablet: 8-column grid
-   Mobile: Single column

## Content Width

  Screen         Recommended
  -------------- ---------------
  Form Content   1200--1400 px
  Dashboard      1440--1600 px
  Dialog         480--900 px

Never stretch forms edge-to-edge on wide monitors.

Increase margins instead.

------------------------------------------------------------------------

# Spacing Scale

Use only:

-   8
-   12
-   16
-   24
-   32
-   48
-   64

Never use arbitrary spacing.

------------------------------------------------------------------------

# Card Rules

Cards represent logical business groups.

Never create one card per field.

Example:

Customer Information

-   Customer
-   Contact
-   Credit Limit
-   Balance

NOT

Customer

Contact

Balance

Each inside separate cards.

------------------------------------------------------------------------

# Field Width Standards

Fields should size according to expected content.

Never allow controls to grow simply because empty space exists.

  Field                  Min   Preferred   Max
  ------------- ------------ ----------- -----
  Date                   160         170   180
  Time                   100         120   120
  Date & Time            200         220   240
  Currency               140         160   180
  Percentage             100         120   120
  Quantity               120         140   160
  Unit                    90         100   120
  Status                 120         140   180
  Invoice No             180         220   240
  Reference              180         220   280
  Phone                  180         220   260
  Email                  260         360   420
  Customer               300         420   600
  Warehouse              240         320   400
  Employee               280         360   500
  Search                 320         420   600
  Description     Full Width             
  Address         Full Width             
  Remarks         Full Width             

## Stretch Rules

Only these controls may occupy 100% width:

-   Address
-   Description
-   Notes
-   Remarks
-   HTML editors
-   Data grids
-   Attachments

Everything else should remain at preferred width.

------------------------------------------------------------------------

# Control Heights

  Control       Height
  ------------- ------------
  Text Field    40--44 px
  Dropdown      40--44 px
  Date Picker   40 px
  Button        40--44 px
  Text Area     80--120 px

------------------------------------------------------------------------

# Labels

Desktop label width:

140--160 px

Left aligned.

Input controls start on the same vertical line.

------------------------------------------------------------------------

# Typography

Maximum two font weights per section.

Recommended hierarchy:

-   Page Title
-   Section Title
-   Card Title
-   Field Label
-   Body
-   Caption

------------------------------------------------------------------------

# Information Hierarchy

Every field must be classified.

## Primary

Visible immediately.

## Secondary

Inside expandable section.

## Advanced

Overflow menu or Advanced panel.

## System

Hidden from users.

Includes:

-   IDs
-   GUIDs
-   API fields
-   Audit fields
-   Sync metadata
-   Timestamps

------------------------------------------------------------------------

# Forms

Show required fields first.

Use intelligent defaults.

Reveal dependent fields only when required.

Validate inline.

Do not show validation until interaction.

If more than eight editable fields are visible:

Use

-   Stepper
-   Accordion
-   Progressive disclosure
-   Tabs

------------------------------------------------------------------------

# Tables

Optimize for scanning.

Hide rare columns.

Allow:

-   Resize
-   Reorder
-   Pin
-   Save layouts

Numbers right aligned.

Text left aligned.

Status centered.

------------------------------------------------------------------------

# Action Hierarchy

One primary action.

Everything else:

-   Secondary
-   Text
-   Overflow

Avoid multiple primary buttons.

------------------------------------------------------------------------

# Navigation

Always include:

-   Page title
-   Breadcrumb
-   Module
-   Back action

------------------------------------------------------------------------

# Feedback

Every action must generate feedback.

Examples:

-   Saved
-   Posted
-   Deleted
-   Submitted

Prefer toast notifications.

------------------------------------------------------------------------

# Empty States

Always explain:

-   Why empty
-   What user should do
-   Primary CTA

------------------------------------------------------------------------

# Performance

Use:

-   Virtual scrolling
-   Lazy loading
-   Deferred rendering
-   Pagination where appropriate
-   Optimistic updates

------------------------------------------------------------------------

# Accessibility

WCAG AA.

Support:

-   Keyboard navigation
-   Screen readers
-   Focus indicators
-   High contrast
-   44 px touch targets

------------------------------------------------------------------------

# ERP Power User Features

Support:

-   Keyboard shortcuts
-   Inline editing
-   Auto-save drafts
-   Sticky totals
-   Sticky action bar
-   Recent selections
-   Autocomplete
-   Bulk actions
-   Undo where practical

------------------------------------------------------------------------

# Screen Review Checklist

Before implementing:

1.  Define the primary business task.
2.  Classify every field.
3.  Remove duplicate information.
4.  Limit initial editable fields.
5.  Verify preferred widths.
6.  Verify labels align.
7.  Verify only one primary action.
8.  Confirm responsive behavior.
9.  Confirm accessibility.
10. Confirm performance with thousands of records.

------------------------------------------------------------------------

# Golden Rules

-   Never stretch small fields.
-   Never expose database structure.
-   Prefer whitespace over borders.
-   Prefer recognition over recall.
-   Minimize clicks.
-   Keep workflows predictable.
-   Optimize for accountants and operators spending 8+ hours per day.
-   Every pixel should improve productivity.
