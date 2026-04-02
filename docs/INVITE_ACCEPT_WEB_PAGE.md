# Group Invite — Web Accept & Registration Page

This document gives the web team everything needed to build a standalone TypeScript webpage that lets an invited user accept a group invitation and register an account before downloading the app.

---

## 1. User flow

```
Email link → /invite/:token
      │
      ├─ If user needs to register:
      │     1. Show registration form (email pre-filled, username, password)
      │     2. POST /api/v1/auth/register
      │     3. POST /api/v1/auth/login  (auto-login after registration)
      │     4. POST /api/v1/group-invites/accept  { token }
      │     5. Success screen — prompt to download the app
      │
      └─ If user already has an account:
            1. Show login form
            2. POST /api/v1/auth/login
            3. POST /api/v1/group-invites/accept  { token }
            4. Success screen — prompt to download the app
```

The token comes from the URL path parameter (e.g. `/invite/abc123`). It should be extracted on page load and held in memory for the accept call after auth.

---

## 2. API reference

All requests go to the same base URL as the mobile app backend. Content-Type is `application/json` throughout.

### Register

```
POST /api/v1/auth/register
```

Request body:
```json
{
  "email": "user@example.com",
  "username": "display_name",
  "password": "secret123"
}
```

- `email` — required, valid email format
- `username` — required, minimum 3 characters
- `password` — required, minimum 8 characters

Responses:
- `201` — success (no body needed; auto-login immediately after)
- `409` — email or username already in use
- `400` / `422` — validation error

### Login

```
POST /api/v1/auth/login
```

Request body:
```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

Response `200`:
```json
{
  "access_token": "<jwt>",
  "token_type": "bearer"
}
```

Store the `access_token` in memory and send it on subsequent requests as:
```
Authorization: Bearer <access_token>
```

The backend also sets an HTTP-only refresh token cookie. The web page does not need to manage this — the browser handles it automatically.

Responses:
- `200` — success, body contains `access_token`
- `401` / `403` — invalid credentials

### Accept invite

```
POST /api/v1/group-invites/accept
Authorization: Bearer <access_token>
```

Request body:
```json
{
  "token": "<invite_token_from_url>"
}
```

Response `200` — `GroupMembershipResponse`:
```json
{
  "group_id": "<uuid>",
  "user_id": "<uuid>",
  "username": "display_name",
  "role": "member",
  "status": "active",
  "created_at": "2026-04-02T12:00:00Z"
}
```

`role` values: `"owner"` | `"coach"` | `"member"`

Responses:
- `200` — invite accepted, membership created
- `400` — invite token invalid, already used, or expired
- `401` — not authenticated

---

## 3. Page states

The page has four distinct states to render:

| State | Trigger | What to show |
|---|---|---|
| **Loading** | Initial token validation (optional) or any in-flight request | Spinner, "Please wait…" |
| **Register / Login form** | Page loads with a valid token | Form fields (see §4) |
| **Success** | `accept` returns `200` | Confirmation + app download prompt |
| **Error** | Any API error or invalid/expired token | Error message + "Contact the person who invited you" |

---

## 4. Form fields and validation

### Registration form

| Field | Type | Validation |
|---|---|---|
| Email | `email` input | Pre-fill from the invite if available; valid email format; required |
| Username | `text` input | Min 3 characters; required |
| Password | `password` input (with show/hide toggle) | Min 8 characters; required |

### Login form (for existing users)

| Field | Type | Validation |
|---|---|---|
| Email | `email` input | Valid email format; required |
| Password | `password` input (with show/hide toggle) | Required |

Provide a toggle link below the form to switch between "Create account" and "Sign in" modes — the same pattern used in the app.

---

## 5. Design tokens

These values come directly from `lib/shared/design_system/theme.dart`. Use them to match the app as closely as possible.

### Colors

| Token | Hex | Usage |
|---|---|---|
| `backgroundLight` | `#FAF1EC` | Page / scaffold background (warm cream) |
| `backgroundMedium` | `#FFFFFF` | Cards, form containers |
| `backgroundSubtle` | `#EDE5DE` | Input fills, chip backgrounds |
| `backgroundDark` | `#1A1A1A` | Snackbars / toasts |
| `mainAccent` | `#9060C8` | Primary buttons, links, focus rings |
| `mainAccentHover` | `#A878D8` | Button hover state |
| `brandPurple` | `#5F2E8F` | Brand identity (logo, hero) |
| `brandCyan` | `#2FF9FA` | Brand accent (logo, hero) |
| `errorRed` | `#DE3737` | Error text, error borders |
| `warning` | `#E07B2A` | Warning text |
| `success` | `#2E8B57` | Success icons/text |
| `textPrimary` | `#1A1A1A` | Body text, headings |
| `textSecondary` | `#626262` | Subheadings, helper text, placeholders |
| `textDisabled` | `#AAAAAA` | Disabled inputs / buttons |
| `dividerLight` | `#E0D8D2` | Borders, dividers |

Primary container (e.g. chip selected background, progress track): `#9060C8` at ~15% opacity → `rgba(144, 96, 200, 0.15)`.

### Typography

No custom font is specified in the app — it uses the system default. Use a system sans-serif stack: `-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`.

| Role | Size | Weight | Letter-spacing | Notes |
|---|---|---|---|---|
| `headlineLarge` | 28px | 700 | -0.5px | Page titles |
| `headlineMedium` | 24px | 700 | -0.5px | Section headings |
| `headlineSmall` | 22px | 600 | -0.3px | Card headings |
| `titleLarge` | 20px | 600 | -0.2px | App-bar / dialog titles |
| `titleMedium` | 16px | 500 | -0.08px | Line-height 1.13 |
| `titleSmall` | 14px | 600 | -0.08px | |
| `bodyLarge` | 16px | 400 | -0.08px | |
| `bodyMedium` | 14px | 500 | -0.08px | Line-height 1.29; main body copy |
| `bodySmall` | 12px | 500 | — | Color: `textSecondary`; captions |
| `labelLarge` | 14px | 600 | -0.08px | Line-height 1.29; button text |
| `labelMedium` | 12px | 600 | — | Color: `textSecondary` |
| `labelSmall` | 11px | 500 | — | Color: `textSecondary` |

### Spacing

| Token | Value |
|---|---|
| `spacingXs` | 4px |
| `spacingSm` | 8px |
| `spacingMd` | 16px |
| `spacingLg` | 22px |
| `spacingXl` | 31px |

### Border radius

| Token | Value | Used on |
|---|---|---|
| `radiusXs` | 7px | Inputs, small containers |
| `radiusSm` | 18px | Cards, dialogs, form containers |
| `radiusMd` | 20px | Primary buttons |
| `radiusLg` | 50px | Large pill elements |
| `radiusPill` | 100px | Full pill / badge shapes |

### Shadows

Card shadow: `box-shadow: 0 2px 20px rgba(0, 0, 0, 0.06)`

### Buttons

**Primary (filled/elevated):**
- Background: `mainAccent` (`#9060C8`)
- Text: `#FFFFFF`, 14px, weight 600, letter-spacing -0.08px
- Border-radius: `radiusMd` (20px)
- Min-height: 48px
- Hover background: `mainAccentHover` (`#A878D8`)
- Disabled: background `backgroundSubtle`, text `textDisabled`
- Elevation: 0 (flat)

**Outlined (secondary):**
- Background: transparent
- Border: 1px solid `mainAccent`
- Text: `mainAccent`, same type as above
- Border-radius: 20px
- Min-height: 48px

**Text button / link:**
- Color: `mainAccent`
- No border/background
- Same type styles as above

### Inputs

- Background (fill): `backgroundSubtle` (`#EDE5DE`)
- Border: 1px solid `dividerLight` (`#E0D8D2`)
- Border-radius: `radiusXs` (7px)
- Padding: 16px horizontal, 16px vertical
- Label color: `textSecondary`
- Placeholder color: `textDisabled`
- Focus border: 1px solid `mainAccent`
- Error border: 1px solid `errorRed`; on focused+error: 2px solid `errorRed`

### Dialogs / Cards

- Background: `backgroundMedium` (`#FFFFFF`)
- Border-radius: `radiusSm` (18px)
- Border: 1px solid `dividerLight`
- Elevation: flat (0) for cards; slight for dialogs

---

## 6. Layout

The login/register page in the app centers content in a `maxWidth: 480px` column with `spacingLg` (22px) padding on all sides. Replicate this for the web form:

```
Page background: backgroundLight (#FAF1EC)
  └─ Centered column, max-width 480px, padding 22px
       ├─ Header: icon + headline + subtitle
       │     spacing below: spacingXl (31px)
       └─ Form card
             background: #FFFFFF
             border-radius: 18px
             border: 1px solid #E0D8D2
             padding: 22px
             ├─ Email field
             ├─ spacingMd (16px)
             ├─ Username field  (register mode only)
             ├─ spacingMd (16px)
             ├─ Password field
             ├─ Error text (if any), spacingSm (8px) above
             ├─ spacingLg (22px)
             ├─ Button row: [Cancel / Back] [Create account / Sign in]
             ├─ spacingSm (8px)
             ├─ Toggle link: "Already have an account? Sign in instead"
             ├─ spacingMd (16px)
             └─ Divider + footnote about future OAuth
```

The "Cancel" button on the web page can navigate back or close the tab — there's no native pop() like the app.

---

## 7. Success screen

After `accept` returns `200`:

```
✓ (success icon, color: #2E8B57, size ~64px)
  "You're in!"
  "<group_name> is waiting for you."   ← group_id from response if name isn't available
  [Download the app]                   ← link to App Store / Play Store
```

Mirror the app's success style: icon + `titleLarge` text + `bodyMedium` subtext + primary button.

---

## 8. Error handling

| Scenario | Message to show |
|---|---|
| Token missing from URL | "This invite link is invalid." |
| `accept` returns 400 | "This invite has already been used or has expired." |
| `accept` returns 401 | Should not happen if auth succeeded — show generic error |
| Register 409 | "An account with that email or username already exists." |
| Login 401/403 | "Incorrect email or password." |
| Network / unknown | "Something went wrong. Please try again." |

Show errors inline below the form fields in `errorRed` (`#DE3737`), `bodyMedium` size.
