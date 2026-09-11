# Privacy Policy for Animal Restaurant Tracker

**Effective date:** September 4, 2026
**Last updated:** September 4, 2026

Animal Restaurant Tracker ("the app") is a progress tracker for the mobile game
Animal Restaurant. It is developed and operated by Linda Mansour ("we", "us"),
an independent developer. The app is unofficial and is not affiliated with,
endorsed by, or connected to the developers or publishers of Animal Restaurant.

This policy explains what the app collects, why, who it is shared with, and how
you can get it deleted. It applies to the iOS and Android versions of the app.

**The short version.** The app is a checklist for a game. You can use all of it
without ever creating an account, and in that mode your data never leaves your
phone. There are no ads, no analytics, no tracking, and nothing is ever sold. If
you choose to sign in, your progress is synced to a private cloud record so you
can restore it on another device, and you can delete that record and your
account from inside the app at any time.

---

## 1. Information you give us

**Account information (optional).** The app works fully without an account. If
you choose to create one so your progress syncs across devices, we collect:

- **Email and password sign-in** — your email address. Your password is sent
  directly to Google Firebase Authentication, which stores it in hashed form. We
  never see, receive, or store your password.
- **Sign in with Google** — your email address and Google account identifier, as
  provided to us by Google.
- **Sign in with Apple** — your email address only, as provided to us by Apple.
  The app does not request your name. If you use Apple's **Hide My Email**, we
  only ever receive Apple's private relay address, never your real one.
- **Guest sign-in** — an anonymous account identifier only. No email, no name,
  nothing that identifies you.

In every case, Firebase Authentication assigns your account a random user ID
(a "UID"). That UID, not your name, is what your saved progress is filed under.

**Feedback you send us.** The app has a feedback form. If you use it, we receive
the message you wrote and, only if you choose to fill in the optional contact
field, the contact details you typed there. The form does not attach your
account, your email, or your device information to the message — if you do not
fill in the contact field, we have no way to tell who sent it or to reply.

## 2. Information created by using the app

As you tick things off, the app records your in-game progress: which customers,
dishes, letters, facilities, courtyard facilities, posters, movie acts, acorns,
pets, staff, mementos and battle pass rewards you have marked as unlocked or
collected, along with your income figures, timers, and your theme preference.

This is game progress about a fictional restaurant. It contains no personal
information unless you deliberately type some into a free-text field.

Where it lives depends on whether you are signed in:

- **Signed out (guest).** Progress is stored only in the app's own storage on
  your device. It is never transmitted anywhere. Deleting the app deletes it.
- **Signed in.** Progress is stored on your device *and* synced to a single
  private record in Google Cloud Firestore, filed under your account's UID.
  Security rules restrict that record so that it can only be read or written by
  someone signed in as you.

## 3. Information collected automatically

The app contains **no** analytics SDK, **no** advertising SDK, **no** crash or
performance reporting, and **no** tracking or attribution technology of any kind.
We do not use cookies or similar identifiers, and we do not access the
Advertising Identifier (IDFA). We never ask for and never receive your location,
contacts, photos, camera, microphone, health data, or files.

We do not track you across other companies' apps or websites, and we do not
build advertising or marketing profiles.

The one unavoidable exception is ordinary server logging. When the app talks to a
server over the internet — to sign you in, to sync your progress, or to deliver
feedback you have sent — that server necessarily sees the connection's **IP
address** and basic technical details such as the time of the request and the
type of client making it. This is inherent to how the internet works. Our service
providers (see section 5) keep such logs for their own security and operational
purposes under their own privacy policies. We do not use these logs to identify
or profile you.

## 4. Notifications

The app can set timers for in-game events such as the buffet, tip jar, takeout
and performers, and notify you when they finish. These are **local
notifications**: they are scheduled and delivered entirely by your own device's
operating system, using your device's clock and time zone. There is no push
notification server, no push token, and nothing about your timers is sent to us
or to anyone else. You can decline or revoke notification permission at any time
in your device settings; the rest of the app continues to work.

## 5. How we use your information

We use the limited information described above only to:

- Provide the app's core function of saving and displaying your progress;
- Authenticate you and sync your progress between your devices when you have
  chosen to sign in;
- Read and, where you have supplied contact details, respond to feedback you
  send us;
- Keep the service working, diagnose problems, prevent abuse, and keep accounts
  secure;
- Comply with legal obligations.

We do **not** use your information for advertising, profiling, automated
decision-making, or any purpose unrelated to running the app.

## 6. Who we share it with

**We do not sell your personal information, and we do not share it for
advertising or cross-context behavioural advertising.** We do not disclose it to
data brokers.

We rely on a small number of service providers, who process data on our behalf
and are contractually restricted to that purpose:

| Provider | What it handles | Their policy |
|---|---|---|
| **Google Firebase** (Authentication, Cloud Firestore) — Google LLC | Account creation and sign-in; storage of your synced progress record | [firebase.google.com/support/privacy](https://firebase.google.com/support/privacy) |
| **Google Sign-In** — Google LLC | Only if you choose that sign-in method | [policies.google.com/privacy](https://policies.google.com/privacy) |
| **Sign in with Apple** — Apple Inc. | Only if you choose that sign-in method | [apple.com/legal/privacy](https://www.apple.com/legal/privacy/) |
| **Vercel Inc.** | Hosts the endpoint that receives in-app feedback messages | [vercel.com/legal/privacy-policy](https://vercel.com/legal/privacy-policy) |

The app also contains an optional link to **Buy Me a Coffee**, which opens in
your browser outside the app. If you follow it and choose to donate, you are
dealing with Buy Me a Coffee and its payment processors directly under their own
privacy policy. We never see, receive, or store your payment card details, and no
payment is ever taken inside the app.

Beyond this, we may disclose information only where we are legally required to —
for example in response to a valid legal demand — or where necessary to protect
our rights or someone's safety. We will not do so voluntarily otherwise.

## 7. Where your data is processed

Our service providers process and store data on servers in the **United States**
and in other countries where they operate. If you use the app from the European
Economic Area, the United Kingdom, or Switzerland, this means your information
may be transferred outside your home country. Where such a transfer takes place,
it is covered by the transfer mechanisms our providers maintain, including the
European Commission's Standard Contractual Clauses and, where applicable, the EU-US
Data Privacy Framework.

## 8. How long we keep it

- **Guest progress** stays on your device until you clear it in the app or delete
  the app. We never hold a copy.
- **Synced progress and your account** are kept for as long as your account
  exists. Deleting your account (section 9) removes both, immediately and
  permanently.
- **Feedback messages** are kept for as long as needed to act on them, and in
  any event no longer than 24 months, after which they are deleted.
- **Service providers' server logs** are retained according to their own
  schedules, which are typically measured in days or months.

## 9. Your choices and your rights

**You can use the entire app without an account.** No feature is locked behind
signing in; an account only adds cloud sync.

**You can delete everything yourself, from inside the app:**

- **Settings → Wipe all data** clears the progress stored on your device.
- **Settings → Delete account** permanently deletes both your account and the
  synced progress record that goes with it. This is irreversible. If you have
  been signed in for a long time, your device may ask you to sign in again first
  as a security check before it will complete the deletion.

**You can also revoke the app's access from outside it** — for example, by
removing it under "Sign in with Apple" in your Apple ID settings, or under
third-party app access in your Google account.

**If you are in the EEA, the UK, or Switzerland**, the GDPR gives you the right
to access your personal data, to have it corrected, to have it erased, to
restrict or object to how we process it, to receive it in a portable format, and
to withdraw consent at any time without affecting processing already carried out.
Our legal bases for processing are: **performance of a contract** (running the
account and sync features you asked for), **your consent** (optional feedback,
optional notifications), and our **legitimate interests** (keeping the app
working and secure). You also have the right to lodge a complaint with your local
data protection supervisory authority.

**If you are a California resident**, the CCPA/CPRA gives you the right to know
what personal information we collect and how it is used, to have it deleted, to
have it corrected, and to opt out of its sale or sharing. As stated above, **we
do not sell or share personal information**, and we do not use or disclose
sensitive personal information for any purpose beyond providing the app. We will
never discriminate against you for exercising these rights. Residents of other
US states with comparable privacy laws have equivalent rights.

To exercise any of these rights, use the in-app deletion controls above or email
us at **privacy@zawmbi.com**. We will respond within the time limit the
applicable law sets — no later than 30 days under the GDPR, or 45 days under the
CCPA. We may need to ask you for information to verify that the account is yours
before we act on a request.

## 10. Children

The app is not directed to children under 13, and we do not knowingly collect
personal information from them. The app shows no ads, has no social features, no
chat, no user-to-user contact, and no in-app purchases.

If you are a parent or guardian and believe your child has created an account
with us, email **privacy@zawmbi.com** and we will delete the account and its data
promptly. You can also delete it yourself using the in-app control described in
section 9.

## 11. Security

Traffic between the app and our service providers is encrypted in transit using
TLS. Passwords are hashed by Firebase Authentication and are never visible to us.
Firestore security rules are configured so that a stored progress record can only
be accessed by the account that owns it.

No method of transmission or storage is completely secure, and we cannot
guarantee absolute security. Please use a strong, unique password if you sign in
with email.

## 12. Changes to this policy

If we change this policy, we will post the updated version at this address and
update the "Last updated" date above. If a change materially affects how we
handle your information, we will give notice in the app before it takes effect.
Continuing to use the app after a change takes effect means you accept the
updated policy.

## 13. Contact us

Questions, privacy requests, or complaints:

**Email:** privacy@zawmbi.com
**Developer:** Linda Mansour
**App:** Animal Restaurant Tracker (`com.lindamansour.animalRestaurantTracker`)
