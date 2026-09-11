# Privacy: App Store submission + website handoff

Companion to `docs/PRIVACY_POLICY.md`. That file is the policy itself and is
meant to be published verbatim. This file is working notes — it is not part of
the published policy.

---

## 1. Before you submit

- [x] **`privacy@zawmbi.com` receives mail.** Confirmed. Keep it that way — Apple
      treats a non-functioning privacy contact as grounds for rejection, and the
      GDPR/CCPA response deadlines quoted in the policy start running whether or
      not you see the message.
- [x] **zawmbi.com is live.**
- [x] **The policy page is live at its URL.** Verified 7 Sep 2026:
      <https://zawmbi.com/privacy/animal-restaurant-tracker/> returns HTTP 200
      with the policy text server-rendered into the HTML.
- [x] **The page is publicly reachable** — no login wall, no password, no
      staging-only domain, and the content is present without JavaScript.
- [x] **The URL is set in App Store Connect** (App Information -> Privacy Policy
      URL).
- [x] **The app links to it in two places** — the sign-in screen and Settings,
      both via `openPrivacyPolicy` in
      `lib/features/shared/utils/legal_links.dart`. Guideline 5.1.1(i) expects an
      app offering account creation to surface its policy, and reviewers look for
      it on the sign-in screen specifically.

The live URL is `https://zawmbi.com/privacy/animal-restaurant-tracker/`. It is
written down in exactly one place in the app — `legal_links.dart` — so if it ever
moves, change it there, in App Store Connect, and leave a 301 behind.

## 2. Where the URL goes in App Store Connect

- **App Store Connect → your app → App Information → Privacy Policy URL.**
  This is required for every app and is what reviewers click.
- **App Store Connect → your app → App Privacy → Privacy Policy URL.** Same URL.
- If you later add an EU-facing build, the same URL covers the Digital Services
  Act trader disclosures' privacy element, but the trader details themselves are
  entered separately.

## 3. App Privacy questionnaire ("nutrition label")

This is the questionnaire under **App Store Connect -> your app -> App Privacy**.
It is filled in by hand, Apple does not derive it from your policy, and reviewers
compare the two. It is also what prints on your public store listing.

Everything below is written to be read straight down while clicking, so you never
have to decide anything at the screen.

### 3.1 How the questionnaire is shaped

Three stages, in this order:

1. **"Do you or your third-party partners collect data from this app?" -> Yes.**
   You cannot answer "No data collected", because signing in collects an email
   address.
2. **Tick the data types you collect**, from one long list of checkboxes grouped
   under category headings. This is the screen that is easy to get lost on, so
   3.3 walks every single line of it.
3. **For each type you ticked**, Apple then asks three follow-ups on its own
   screen: what **purposes** it is used for, whether it is **linked to the
   user's identity**, and whether it is used for **tracking**. Answers in 3.4.

**"Collect" has a narrow meaning here:** transmitting data off the device and
keeping it longer than needed to serve the request in real time. Data that never
leaves the phone is not collected. That single rule decides most of the list
below — and it is why guest mode changes nothing, while *signed-in* progress
sync does count.

### 3.2 The pairs that look alike

These are the ones worth reading twice.

| This | is not this | The difference |
|---|---|---|
| **Name** | **User ID** | *Name* is a human name — "Linda Mansour". *User ID* is an account identifier you assign, here the random Firebase UID. We collect a UID and never a name, so Name is No and User ID is Yes. |
| **Other User Content** | **Other Usage Data** | *User Content* is what the user writes, makes, or saves. *Usage Data* is behavioural exhaust — taps, launches, screens viewed. Two unrelated categories that happen to both start with "Other". We have user content; we have no usage data at all. |
| **Customer Support** as a *data type* | **App Functionality** as a *purpose* | The phrase "customer support" turns up in both stages, which is genuinely confusing. In stage 2 it is a **type**: the contents of a support message. In stage 3 it is folded inside the **App Functionality** purpose, whose definition ends "...or perform customer support". There is no separate "Customer Support" purpose to pick. |
| **Gameplay Content** | **Other User Content** | Every "Other" box is a catch-all for things the named boxes above it do not cover. Synced progress *is* named: Apple defines Gameplay Content as "saved games, multiplayer matching or gameplay logic, or user-generated content in-game". So it goes in the specific box, and the catch-all stays empty. |
| **Linked to the user** | **Used to track the user** | *Linked* means tied to an identity in **your** systems — ours is, via the UID. *Tracking* means matched with **third-party** data for advertising, or shared with a data broker. Ours is linked but not tracking. Almost everything here is "Yes linked, No tracking". |

### 3.3 Every line on the list, in Apple's order

Tick the five marked **YES**. Leave every other box empty. Apple's own
definition is quoted where it is what settles the answer.

**Contact Info**

| Line | Answer | Why |
|---|---|---|
| Name | No | Apple sign-in requests email only (see section 4). No other flow asks for a name. |
| Email Address | **YES** | Email/password, Google and Apple sign-in. Also the feedback form's optional contact field when someone types an email into it. |
| Phone Number | No | Never requested. |
| Physical Address | No | Never requested. |
| Other User Contact Info | **YES** | The feedback form's contact field hints *"Email, Discord, etc."*, so it can receive a handle that is not an email address — Apple's definition is "any other information that can be used to contact the user outside the app". See the decision note under 3.5. |

**Health & Fitness** — Health: No. Fitness: No. No HealthKit, no Motion & Fitness.

**Financial Info** — Payment Info: No. Credit Info: No. Other Financial Info: No.
The app is free with no in-app purchases. The in-game currency figures the app
tracks are fictional and never leave as financial data.

**Location** — Precise Location: No. Coarse Location: No. The app never requests
location permission.

**Sensitive Info** — No.

**Contacts** — No. The app never reads the address book.

**User Content**

| Line | Answer | Why |
|---|---|---|
| Emails or Text Messages | No | The app does not read mail or messages. |
| Photos or Videos | No | No photo library or camera access. |
| Audio Data | No | No microphone access. |
| Gameplay Content | **YES** | The `unlocked` progress map synced to Firestore when signed in. Guest mode keeps it on device, but the signed-in path stores it server-side, which makes it collected. See the correction note under 3.5. |
| Customer Support | **YES** | The free-text feedback message — "data generated by the user during a customer support request" is exactly what the form produces. |
| Other User Content | No | Both kinds of user content we hold have a specific box above. Nothing is left for the catch-all. |

**Browsing History** — No. The app does not observe what you view outside it.

**Search History** — No. The app *does* have in-app search, but the query is
transient UI state: it is never stored and never transmitted. Apple's line covers
"searches performed in the app", so this one is worth pausing on — the answer is
still No, because nothing is collected.

**Identifiers**

| Line | Answer | Why |
|---|---|---|
| User ID | **YES** | The Firebase UID a synced progress record is filed under. Anonymous (guest) sign-in gets one too, so this is Yes regardless of how someone signs in. |
| Device ID | No | No IDFA, no vendor identifier, no device fingerprint. |

**Purchases** — Purchase History: No. Free app, no IAP, no subscriptions.

**Usage Data** — Product Interaction: No. Advertising Data: No. Other Usage Data:
No. There is no analytics SDK and no ad SDK in `pubspec.yaml`.

**Diagnostics** — Crash Data: No. Performance Data: No. Other Diagnostic Data: No.
There is no crash reporter.

**Surroundings** — Environment Scanning: No.

**Body** — Hands: No. Head: No.

**Other Data** — Other Data Types: No.

> **On server logs.** Signing in, syncing and sending feedback all involve a
> server that necessarily sees an IP address, and section 3 of the policy says so
> plainly. That is ordinary infrastructure logging by our providers for their own
> security purposes, not data we collect, keep or use — so it is not declared
> here. This is the conventional reading and it matches how the policy describes
> it.

### 3.4 The follow-up screens, for the five ticked types

Every one of the five gets the same three answers:

| Data type | Purpose to tick | Linked to identity? | Used for tracking? |
|---|---|---|---|
| Email Address | App Functionality | **Yes** | **No** |
| Other User Contact Info | App Functionality | **Yes** | **No** |
| User ID | App Functionality | **Yes** | **No** |
| Gameplay Content | App Functionality | **Yes** | **No** |
| Customer Support | App Functionality | **Yes** | **No** |

**App Functionality is the only purpose to tick, for all five.** Leave
Third-Party Advertising, Developer's Advertising or Marketing, Analytics,
Product Personalization and Other Purposes unticked every time.

Everything is **linked** because it is all filed under, or reachable from, the
Firebase UID. Nothing is **tracking**: no IDFA, no attribution SDK, no data
broker, nothing matched against third-party data for advertising.

**Final question — "Do you use data for tracking purposes?" -> No.** This is also
why the app needs no App Tracking Transparency prompt and no
`NSUserTrackingUsageDescription` key.

If a screen offers a way to mark a type as **optional** rather than always
collected, that applies to Email Address, Other User Contact Info and Customer
Support — the app is fully usable without an account and without ever opening the
feedback form.

### 3.5 Two changes from what this file said before

Both were found on 7 Sep 2026 by checking Apple's published list rather than
working from memory. **If you have already filled the questionnaire in, it needs
these two edits.**

**Gameplay Content was missing.** The old answer declared three types and none of
them covered synced progress — yet section 2 of the published policy tells users
their progress is stored in Firestore. A reviewer comparing the policy against
the label would have found a category of data described in one and absent from
the other. Ticking Gameplay Content closes that.

**Customer Support replaces Other User Content.** "Other" boxes are for what the
named boxes do not cover, and the feedback message has a named box.

There is also a **decision you can reverse**, on Other User Contact Info. It is
ticked because the feedback form's contact field invites a Discord handle:

```dart
hintText: 'Email, Discord, etc.',   // lib/features/support/ui/support_page.dart
```

Two consistent options — pick one, do not mix:

- **Keep it as is** (what the manifest and the table above now assume): no code
  change, one extra row on your public label.
- **Narrow the field** to `'Email address'` and accept email only: one string
  edit, then untick Other User Contact Info here and delete its entry from
  `ios/Runner/PrivacyInfo.xcprivacy`. Slightly shorter label.

### 3.6 This must match the privacy manifest, exactly

`ios/Runner/PrivacyInfo.xcprivacy` declares the same five types, all linked, none
tracking, all App Functionality — plus `UserDefaults` reason `CA92.1`, which is an
API-access declaration and has no questionnaire equivalent. Reviewers and the
automated checks compare the two, so they change together or not at all.

The manifest was also carrying an **invalid purpose string**,
`NSPrivacyCollectedDataTypePurposeCustomerSupport`. Apple publishes exactly six
purpose values and that is not one of them — the real list is
`ThirdPartyAdvertising`, `DeveloperAdvertising`, `Analytics`,
`ProductPersonalization`, `AppFunctionality`, `Other`. It has been corrected to
`AppFunctionality`.

Re-validate the manifest against Apple's published values at any time:

```bash
python3 - <<'PY'
import plistlib, json, urllib.request
base = ("https://developer.apple.com/tutorials/data/documentation/bundleresources/"
        "app-privacy-configuration/nsprivacycollecteddatatypes")
def allowed(leaf, prefix):
    raw = json.dumps(json.load(urllib.request.urlopen(f"{base}/{leaf}.json")))
    import re
    return {v for v in re.findall(prefix + r"[A-Za-z]{3,}", raw)}
types = allowed("nsprivacycollecteddatatype", "NSPrivacyCollectedDataType")
purps = allowed("nsprivacycollecteddatatypepurposes", "NSPrivacyCollectedDataTypePurpose")
p = plistlib.load(open("ios/Runner/PrivacyInfo.xcprivacy", "rb"))
bad = []
for e in p["NSPrivacyCollectedDataTypes"]:
    if e["NSPrivacyCollectedDataType"] not in types:
        bad.append(e["NSPrivacyCollectedDataType"])
    bad += [x for x in e["NSPrivacyCollectedDataTypePurposes"] if x not in purps]
print(bad or "all strings valid")
PY
```

**Watch out:** Firebase Analytics is *not* in `pubspec.yaml` today, and the label
above depends on that staying true. Adding `firebase_analytics`,
`firebase_crashlytics`, or any ad SDK later means updating this questionnaire,
the manifest and the policy before that build ships.

## 4. Apple sign-in requests email only (done)

`signInWithApple` in `lib/features/auth/data/auth_service.dart` used to request
`AppleIDAuthorizationScopes.fullName` alongside `email`, but nothing in the app
ever read or stored the returned name. The scope has been removed, which is why
there is no **Name** row in the table above and why section 1 of the policy says
Apple sign-in collects the email address only.

Nothing to migrate: no name was ever persisted, so there is no stored data to
clean up. Anyone who signed in before this change keeps their account and their
synced progress — the account is keyed on the Firebase UID, which is unaffected.

If a future feature ever wants to greet users by name, note that Apple returns
the name **only on the very first authorization** for a given Apple ID. Re-adding
the scope will not retrieve it for existing users, and it would mean restoring
the Name row here and in the policy.

## 5. Handoff to the zawmbi.com repo

Give the other repo `docs/PRIVACY_POLICY.md` and these constraints:

- **Publish the text as-is.** The wording is load-bearing — it is what Apple
  reviewers check against the questionnaire above, and it states legal bases and
  statutory response deadlines. Restyling is fine; rewording is not.
- **The page must be static, public, and permanently addressable.** No auth, no
  redirect chain, no client-side-only rendering that leaves an empty page for a
  reviewer with JS disabled. Server-rendered or plain HTML is safest.
- **Keep the URL stable forever.** If it ever moves, add a 301 — a dead privacy
  URL on a live App Store listing is a compliance problem, not just a broken link.
- **Render the markdown table in section 6** (third-party providers) as a real
  table, and keep the outbound provider links working.
- **Surface the two dates** ("Effective date" and "Last updated") near the top;
  they are referenced by section 12.
- **`mailto:` the contact address** in section 13 so requests are one tap away.
- Consider a matching `https://zawmbi.com/privacy` index page if you expect to
  ship more apps, with per-app policies underneath it.

## 6. Keep this in sync

Re-check the policy and the questionnaire whenever any of these change:

- a new dependency in `pubspec.yaml` that talks to a network or collects data;
- a new backend endpoint (today the only one outside Firebase is the feedback
  endpoint in `lib/features/settings/data/feedback_service.dart`);
- adding in-app purchases, ads, accounts features, or user-to-user contact;
- changing what syncs to Firestore beyond the `unlocked` map in
  `lib/features/shared/data/unlocked_store.dart`.
