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
   - Test users: **add every account you'll sign in with**, including your own
   - Leave it in **Testing** — up to 100 test users, and no publishing flow to deal with.

   Skipping the test-user step produces a confusing failure at sign-in; see
   *Access blocked* below.

4. **iOS client** — *Credentials → Create Credentials → OAuth client ID* → **iOS**.
   Bundle ID: `com.devmfawzy.lexiCards`.
   Returns a client ID ending `.apps.googleusercontent.com` and a reversed form beginning
   `com.googleusercontent.apps.`.

5. **Android client** — same menu → **Android**.
   Package name: `com.devmfawzy.lexi_cards`

   The SHA-1 is your machine's own debug keystore, since that's the key your debug builds
   are signed with. Read it with:

   ```
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore \
     -storepass android -keypass android | grep SHA1
   ```

6. **Web client** — same menu → **Web application**, name it `lexi-cards server client`,
   leave redirect URIs empty. It exists only to be Android's `serverClientId`.

## On the client IDs being in the repo

The iOS and web client IDs are checked in — `lib/core/sync/google_sign_in_config.dart` and
`ios/Runner/Info.plist`. That's deliberate, not an oversight: a client ID identifies the app
to Google and ships inside every copy of the binary, so it can't be a secret in the first
place. Google's own tooling commits them (`google-services.json` is version-controlled by
convention).

They're also useless to anyone else. An iOS client ID only works for its registered bundle
ID, and the Android client only accepts builds signed with the registered key — so a fork
has to create its own project regardless. The one thing that *doesn't* belong here is a
machine's debug SHA-1, which is why step 5 tells you to read your own rather than quoting one.

## What goes into the repo afterwards

- iOS client ID → `ios/Runner/Info.plist` as `GIDClientID`, plus its reversed form as a
  `CFBundleURLTypes` URL scheme for the OAuth callback.
- Web client ID → passed as `serverClientId` when initialising sign-in on Android.
- `INTERNET` permission → `android/app/src/main/AndroidManifest.xml`. It isn't declared
  today; debug builds work only because the Flutter tooling injects it.

The Android client ID isn't referenced anywhere in code — Google matches it by package
name and signing fingerprint at sign-in time.

## Troubleshooting

### "Access blocked: Lexi Cards has not completed the Google verification process"

Ignore the headline — it is wrong for this app. Verification is only required for
sensitive scopes, and `drive.appdata` is not one. The accurate part is the sentence
underneath: *"can only be accessed by developer-approved testers."*

The app is in Testing mode and the account signing in isn't on the test-user list. Either:

- **Add the account** — *Google Auth Platform → Audience → Test users → + Add users*.
  Takes a minute or two to propagate.
- **Or publish the app** — same page, **Publish app**. For a non-sensitive scope this
  needs no review and removes the 100-user limit entirely. This is the reason the hidden
  app-data folder was worth choosing over a broader Drive scope.

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
