# iOS release handoff

**Last verified:** 1 Sep 2026, at commit `7994de9` on
`claude/animal-restaurant-agents-features-9n8hrx` (pushed to origin, tree clean).

Goal: get the app onto Linda's iPhone over TestFlight, then to App Store review.
No cable is involved at any point.

---

## Read this first

Three separate agent sessions have worked on this. Each has repeated confident
claims that were false at the time. **Verify against the files before acting.**

Claims that keep resurfacing and are wrong:

| Claim | Reality |
|---|---|
| "Enable Anonymous in Firebase or you can't get past the login screen" | Anonymous, Email/Password, Google and Apple are **all already enabled**. Checked in the console directly, twice. |
| "The app icon is the Flutter placeholder" | Replaced in `c5856a9`. Check the pixels, not your memory. |
| "pubspec changed, likely flutter_launcher_icons" | It was `crypto`, for the Apple nonce. `flutter_launcher_icons` is not in this project. |
| "The nonce is the only way past the login screen" | The nonce affects Apple sign-in only. "Continue without an account" calls `signInAnonymously()` and never touches it. |

Re-verify current config in one command:

```bash
python3 - <<'PY'
import plistlib
g=plistlib.load(open("ios/Runner/GoogleService-Info.plist","rb"))
i=plistlib.load(open("ios/Runner/Info.plist","rb"))
print("bundle:", g["BUNDLE_ID"])
print("appId :", g["GOOGLE_APP_ID"])
print("url scheme matches REVERSED_CLIENT_ID:",
      i["CFBundleURLTypes"][0]["CFBundleURLSchemes"][0]==g["REVERSED_CLIENT_ID"])
PY
```

---

## Verified state

**Bundle ID is `com.lindamansour.animalRestaurantTracker`** (was
`com.example.animalRestaurantTracker`). Changed in all 6 configs of
`project.pbxproj`, plus `GoogleService-Info.plist`, the `Info.plist` URL scheme,
and the `ios` block of `firebase_options.dart`.

> The `macos` block of `firebase_options.dart` still points at `com.example`
> **on purpose**. The old Firebase iOS app still exists and macOS is out of
> scope. Do not "fix" it.

**Firebase:** a second iOS app is registered under the new bundle ID.
App ID `1:174067290396:ios:65223b309b6cd417c66ad9`, with its own auto-created
OAuth client. The `REVERSED_CLIENT_ID` and the `Info.plist` URL scheme must stay
in sync — if they drift, Google sign-in fails silently with no error.

**Signing:** `DEVELOPMENT_TEAM=ZQUQB39QGN` and `CODE_SIGN_STYLE=Automatic` in
`ios/Flutter/Debug.xcconfig` and `Release.xcconfig`, alongside
`CODE_SIGN_ENTITLEMENTS`. Deliberately via xcconfig, not pbxproj.
`ios/Runner/Runner.entitlements` declares `com.apple.developer.applesignin`.
A build already succeeded with this entitlement present, so it does not break
archiving.

**Also done:** `ITSAppUsesNonExemptEncryption` set; `PrivacyInfo.xcprivacy`
created and confirmed in the Runner target's Resources build phase (clears
ITMS-91053); Apple Sign In nonce implemented properly
(`sha256(rawNonce)` to Apple, `rawNonce` to Firebase); account deletion in
Settings deleting `users/{uid}` before the auth user (guideline 5.1.1(v));
real launch images replacing three 68-byte transparent pixels; custom app icon
in all 15 sizes, alpha-free.

**The last IPA on disk is stale.** Built 1 Sep 01:03 as `1.0.0+1`, under the
*old* bundle ID and the *old* placeholder icon. Do not upload it.

---

## Outstanding

### An agent can do these

1. **`flutter pub get && flutter analyze`** — this is the priority. The nonce fix
   in `lib/features/auth/data/auth_service.dart` and the deletion flow in
   `lib/features/settings/ui/settings_page.dart` were written by an agent with no
   Dart toolchain and **have never been compiled**. Any error is almost certainly
   in one of those two files. Report before changing anything else.

2. **Build 2**, once analyze is clean:
   ```bash
   flutter build ipa --release --build-name=1.0.0 --build-number=2
   ```
   Signing will want the new bundle ID. If automatic provisioning fails on the
   Sign in with Apple capability, say so — do not silently drop the entitlement
   to get a green build.

### Only Linda can do these — do not attempt, ask her

Anything needing Apple credentials: registering the App ID, the Sign in with
Apple capability, the App Store Connect record, app-specific passwords,
Transporter uploads, TestFlight. An agent should tell her exactly what to click,
then stop.

---

## Known risks

- **The bundle ID freezes** the moment a build reaches a public track. It is
  right now still cheap to change; after that it is not.
- The **old** `com.example` OAuth client was flagged by Google for deletion after
  6 months idle. Irrelevant to the new client, but do not resurrect the old ID.
- `flutter analyze` has never passed on the current tree. Treat build 2 as
  unproven until it does.

## Environment notes

Agents working through the desktop app's Linux sandbox could not delete files in
this folder, so every `git` write left a stale `.git/*.lock` that broke the next
command. If you see *"Another git process seems to be running"*:

```bash
find .git -name "*.lock" -delete
```

This does not happen when git runs natively in Terminal.
