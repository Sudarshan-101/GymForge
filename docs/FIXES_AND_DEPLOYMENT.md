# GymForge — iPhone Compatibility Fixes & Netlify Deployment Roadmap

---

## 📋 What Was Audited

| Area | Files Checked |
|---|---|
| Web entry point | `web/index.html`, `web/manifest.json` |
| App bootstrap | `lib/main.dart` |
| Native-only features | `qr_scanner_screen.dart`, `member_home_tab.dart` |
| Services | `notification_service.dart`, `widget_service.dart` |
| Firebase config | `firebase_options.dart` |
| Dependencies | `pubspec.yaml` |

---

## ✅ FIXES APPLIED (in the files delivered)

### 1. `web/index.html` — iPhone/iOS Safari compatibility

**Problems found:**
- Missing `maximum-scale=1.0, user-scalable=no` → iOS Safari auto-zooms on input tap, breaking layout
- Missing `safe-area-inset` CSS padding → Dynamic Island / notch overlaps your UI on iPhone 14/15 Pro
- No iOS splash loading screen → user sees white flash before Flutter renders
- No `flutter-first-frame` listener → custom splash never hid itself

**Changes made:**
```html
<!-- BEFORE -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">

<!-- AFTER -->
<meta name="viewport" content="width=device-width, initial-scale=1.0,
      maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
```
- Added `env(safe-area-inset-*)` CSS padding on `html, body`
- Added native-looking splash `<div id="splash">` that disappears on `flutter-first-frame`
- Added `overflow: hidden` to prevent iOS bounce/scroll on the root elements
- Added `theme-color` meta tag for Safari tab bar

---

### 2. `web/manifest.json` — PWA / Add to Home Screen

**Problems found:**
- Icons only had `"purpose": "any"` or `"maskable"` but not both entries
- Missing `"scope"` and `"lang"` fields (required by Chrome / Safari for PWA install prompt)

**Changes made:** Added `scope`, `lang`, split icon entries correctly.

---

### 3. `lib/main.dart` — Bootstrap & startup error handling

**Problems found:**
- `GymForgeApp` constructor accepted `startup` as `Future<String?>` but passed it incorrectly
- No user-facing error screen when Firebase fails to init (e.g., wrong API key)
- `SystemChrome` calls executed on web (harmless but generates console errors)
- `SafeArea` missing from `_Splash` → content clips behind notch

**Changes made:**
- Wrapped all `SystemChrome` calls in `if (!kIsWeb)`
- Added `_ErrorScreen` widget with readable message when `_bootstrap()` fails
- Added `SafeArea` to splash screen
- Removed `_requestBatteryOptimizationExemption` from web path (uses `dart:io`)

---

### 4. `lib/screens/member/qr_scanner_screen.dart` — Web / iPhone Safari fallback

**Problems found:**
- `mobile_scanner` uses camera APIs not available on iPhone Safari as a web app
- Importing `mobile_scanner` on web causes a runtime crash
- No fallback for web users who cannot use the camera scanner

**Changes made:**
- Added `kIsWeb` check: on web, shows a **manual code entry** text field instead
- Code validation logic is identical to the native scanner
- Wrapped the native `MobileScanner` widget in `_NativeScannerWrapper` so the import stays tree-shaken on web

---

## 🔧 REMAINING MANUAL FIXES (you need to do these)

### Fix A — Firebase Web App (CRITICAL — app won't load without this)

Your `firebase_options.dart` has a placeholder for the web app:
```dart
// Current (broken):
appId: '1:659942518247:web:placeholder',
```

**Steps:**
1. Open [console.firebase.google.com](https://console.firebase.google.com)
2. Select project **gymforge-f9fe3**
3. Click the **⚙️ gear → Project Settings → Your apps**
4. Click **"Add app" → Web (</> icon)**
5. Register the app (name it "GymForge Web")
6. Copy the config object. It looks like:
   ```js
   const firebaseConfig = {
     apiKey: "...",
     authDomain: "gymforge-f9fe3.firebaseapp.com",
     projectId: "gymforge-f9fe3",
     storageBucket: "gymforge-f9fe3.firebasestorage.app",
     messagingSenderId: "659942518247",
     appId: "1:659942518247:web:REAL_ID_HERE"
   };
   ```
7. Replace in `lib/firebase_options.dart → DefaultFirebaseOptions.web`:
   ```dart
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'your-real-api-key',
     appId: '1:659942518247:web:REAL_ID_HERE',  // ← change this
     messagingSenderId: '659942518247',
     projectId: 'gymforge-f9fe3',
     storageBucket: 'gymforge-f9fe3.firebasestorage.app',
     authDomain: 'gymforge-f9fe3.firebaseapp.com',
   );
   ```

---

### Fix B — Firebase Authentication: Enable Web Domain

1. Firebase Console → **Authentication → Settings → Authorized domains**
2. Add your Netlify domain: `gymforge.netlify.app` (or your custom domain)
3. Also add `localhost` if not already there (for local dev)

---

### Fix C — Firebase Storage CORS (for photo uploads on web)

Photo uploads from the web will be blocked by CORS unless you configure it.

Create a file `cors.json`:
```json
[
  {
    "origin": ["https://gymforge.netlify.app", "http://localhost:*"],
    "method": ["GET", "POST", "PUT"],
    "maxAgeSeconds": 3600
  }
]
```

Then run:
```bash
gsutil cors set cors.json gs://gymforge-f9fe3.firebasestorage.app
```
(Install `gsutil` via `pip install gsutil` or use Google Cloud SDK)

---

### Fix D — `permission_handler` — remove from web build

`permission_handler` uses `dart:io` and **cannot run on web**. Even though `main.dart` wraps calls in `if (!kIsWeb)`, the import itself may cause a web compilation warning.

In `lib/screens/member/home/member_home_tab.dart`, line 9:
```dart
// REMOVE this line — or guard it with conditional import:
import 'package:permission_handler/permission_handler.dart';
```

Replace usages with a stub:
```dart
import 'package:flutter/foundation.dart';

// Use instead of permission_handler on web:
Future<bool> _checkPermission() async {
  if (kIsWeb) return false; // permissions not applicable
  // ... native code here
}
```

---

### Fix E — `native_splash` / splash screen for web (optional but recommended)

Add `flutter_web_plugins` splash config in `web/index.html` (already done in the delivered file).

---

## 🚀 NETLIFY DEPLOYMENT ROADMAP

### Step 1 — Build the Flutter Web app

```bash
# In your project root (gymforge_43/)
flutter build web --release --base-href "/"
```

The output lands in `build/web/`. This is what you deploy.

**If you use a sub-path** (e.g. `https://yoursite.netlify.app/app/`):
```bash
flutter build web --release --base-href "/app/"
```

---

### Step 2 — Create `netlify.toml` in project root

Create this file at the project root (next to `pubspec.yaml`):

```toml
[build]
  command   = "flutter build web --release --base-href /"
  publish   = "build/web"

[[redirects]]
  from   = "/*"
  to     = "/index.html"
  status = 200

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options        = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy        = "strict-origin-when-cross-origin"

[[headers]]
  for = "/flutter_bootstrap.js"
  [headers.values]
    Cache-Control = "no-cache"

[[headers]]
  for = "/main.dart.js"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

> **The `[[redirects]]` rule is critical.** Without it, refreshing any route (e.g. `/member/dashboard`) returns a 404 from Netlify instead of serving your `index.html`. Flutter's router handles the path — Netlify just needs to always serve `index.html`.

---

### Step 3 — Push to GitHub

```bash
git init          # if not already a repo
git add .
git commit -m "Initial GymForge web deployment"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/gymforge.git
git push -u origin main
```

---

### Step 4 — Connect to Netlify

1. Go to [app.netlify.com](https://app.netlify.com) → **"Add new site" → "Import an existing project"**
2. Choose **GitHub** → select your `gymforge` repo
3. Build settings are auto-detected from `netlify.toml` — verify:
   - **Build command:** `flutter build web --release --base-href /`
   - **Publish directory:** `build/web`
4. Click **"Deploy site"**

> First deploy takes ~5-8 minutes because Netlify installs Flutter on its build servers.

---

### Step 5 — Set Flutter version on Netlify (important!)

Netlify's default Flutter may be outdated. Pin the version:

Create `.flutter-version` in project root:
```
3.24.5
```

Or add an environment variable in Netlify UI:
- **Site settings → Environment variables**
- Add: `FLUTTER_VERSION` = `3.24.5` (or your current version, check with `flutter --version`)

---

### Step 6 — Add custom domain (optional)

1. Netlify site dashboard → **"Domain management" → "Add custom domain"**
2. Enter your domain (e.g. `gymforge.yourbrand.com`)
3. Follow DNS instructions (add a CNAME pointing to your Netlify URL)
4. Netlify auto-provisions an SSL certificate via Let's Encrypt

Then add the custom domain to Firebase Auth authorized domains (see Fix B).

---

### Step 7 — Verify on iPhone Safari

1. Open the Netlify URL in iPhone Safari
2. Tap **Share → Add to Home Screen** to install as PWA
3. Check:
   - [ ] No white flash on startup (splash appears instantly)
   - [ ] Status bar area not clipped (notch / Dynamic Island)
   - [ ] Input fields don't zoom when focused
   - [ ] Login works (Firebase Auth)
   - [ ] QR check-in shows manual code entry (not crash)
   - [ ] Photo upload works (or shows a permission message)
   - [ ] Bottom nav tabs all navigate correctly

---

## 📦 COMPLETE CHECKLIST BEFORE GOING LIVE

| # | Task | Done? |
|---|---|---|
| 1 | Replace Firebase web `appId` placeholder | ☐ |
| 2 | Add Netlify domain to Firebase Auth authorized domains | ☐ |
| 3 | Configure Storage CORS for web uploads | ☐ |
| 4 | Remove `permission_handler` import from web build paths | ☐ |
| 5 | Copy fixed `web/index.html` to project | ☐ |
| 6 | Copy fixed `web/manifest.json` to project | ☐ |
| 7 | Copy fixed `lib/main.dart` to project | ☐ |
| 8 | Copy fixed `lib/screens/member/qr_scanner_screen.dart` | ☐ |
| 9 | Create `netlify.toml` in project root | ☐ |
| 10 | Create `.flutter-version` file | ☐ |
| 11 | Push to GitHub and connect to Netlify | ☐ |
| 12 | Test on physical iPhone in Safari | ☐ |

---

## 🔑 KEY NOTES

- **`mobile_scanner`** does NOT work on iPhone Safari as a web app (no WebRTC barcode API). The delivered `qr_scanner_screen.dart` shows a manual code entry form as a graceful fallback.
- **`pedometer`** and **`home_widget`** are native-only — they have stubs already wired in your `services/` folder via conditional exports, so no changes needed.
- **`flutter_local_notifications`** on web does nothing (stub already in place). If you want push on web, add Firebase Cloud Messaging (FCM) web support.
- The app already has a `ResponsiveAppFrame` that centres it on wide screens — desktop users see a phone-sized UI. This is intentional.

---

*Generated by Claude for GymForge project — May 2026*
