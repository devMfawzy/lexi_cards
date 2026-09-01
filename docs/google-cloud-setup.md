# Google Cloud setup for Drive sync

One-time developer setup. Registers the app with Google so it can call the Drive API on a
user's behalf. Done once, by the developer; end users never see any of it — they just link
their own Google account from Settings.

## Why this step exists

OAuth client IDs identify *the app* to Google. There is no way for an app to call a Google
API without being registered first, and the first project in an account has to be created
by a human in a browser. It isn't per-user configuration and it doesn't ship as a secret —
client IDs are compiled into every copy of the app.

The only scope requested is `https://www.googleapis.com/auth/drive.appdata`, the hidden
per-app folder. Google classifies it as **non-sensitive**, so there's no security review,
no CASA assessment and no verification queue before publishing — unlike `drive.readonly`
or full Drive access. The app also can't see any other file in the user's Drive.

## Three OAuth clients

| Type | Identifier | Used for |
|---|---|---|
| iOS | `com.devmfawzy.lexiCards` | Client ID goes in `Info.plist` |
| Android | `com.devmfawzy.lexi_cards` + SHA-1 | Matched automatically; nothing in code |
| Web | — | Android's `serverClientId` |

The web client catches people out: on Android, `google_sign_in` needs a *web* client ID
even though nothing here has a server.

**The two package names differ deliberately** — iOS is camelCase, Android is snake_case.
Entering one where the other belongs produces a client that silently never matches.

## Steps

Order matters: the consent screen must exist before any client can be created.

1. **Create the project** — [console.cloud.google.com](https://console.cloud.google.com) →
   project picker → **New Project** → name it `lexi-cards`. No billing account needed.

2. **Enable the Drive API** — *APIs & Services → Library* → search **Google Drive API** →
   Enable. Skip this and sign-in succeeds while every Drive call fails with a permission
   error, which is a confusing way to find out.

3. **Configure the consent screen** — *APIs & Services → OAuth consent screen*. Newer
   consoles renamed this to *Google Auth Platform*, split across Branding / Audience /
   Data access; same fields.

   - User type: **External**
   - App name: `Lexi Cards`, plus your support and developer email
   - Add scope: `https://www.googleapis.com/auth/drive.appdata`
   - Test users: add your own Google account
   - Leave it in **Testing** — up to 100 test users, and no publishing flow to deal with.

4. **iOS client** — *Credentials → Create Credentials → OAuth client ID* → **iOS**.
   Bundle ID: `com.devmfawzy.lexiCards`.
   Returns a client ID ending `.apps.googleusercontent.com` and a reversed form beginning
   `com.googleusercontent.apps.`.

5. **Android client** — same menu → **Android**.
   Package name: `com.devmfawzy.lexi_cards`
   SHA-1 (debug keystore on this machine):

   ```
   52:EB:67:31:AF:6B:A7:EF:D8:71:EA:9A:27:B3:60:78:42:D5:F4:A6
   ```

6. **Web client** — same menu → **Web application**, name it `lexi-cards server client`,
   leave redirect URIs empty. It exists only to be Android's `serverClientId`.

## What goes into the repo afterwards

- iOS client ID → `ios/Runner/Info.plist` as `GIDClientID`, plus its reversed form as a
  `CFBundleURLTypes` URL scheme for the OAuth callback.
- Web client ID → passed as `serverClientId` when initialising sign-in on Android.
- `INTERNET` permission → `android/app/src/main/AndroidManifest.xml`. It isn't declared
  today; debug builds work only because the Flutter tooling injects it.

The Android client ID isn't referenced anywhere in code — Google matches it by package
name and signing fingerprint at sign-in time.

## Two things to know

**Uninstalling deletes the backup.** Google's documentation is explicit that the
application data folder is removed when the user deletes the app from their Drive. It is a
sync store, not an archive, and the app should say so rather than let someone find out.

**Release builds need a second Android client.** The fingerprint above is the debug
keystore's; a release build is signed with a different key and sign-in will fail until that
key's SHA-1 is registered as another Android OAuth client. Read it with:

```
keytool -list -v -alias <alias> -keystore <path-to-release.jks>
```
