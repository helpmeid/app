# App for iPhone

A lightweight, local-first messaging and voice/video calling web app served by GitHub Pages.

## Install
Open https://helpmeid.github.io/app/ in Safari, Share > Add to Home Screen, enable Open as Web App, and tap Add. GitHub Pages must be configured to deploy main / (root).

## Connect with a friend
Both users install the app and open Settings. Share a personal contact code, add the other user's code in Chats or People, and start a conversation. PeerJS 1.5.5 (loaded on demand from jsDelivr) uses its public signaling service and WebRTC for direct messaging and media. Both people need the app open and online; restrictive networks may prevent connections. There is no offline delivery server, account recovery, push calling, or background messaging. Delivery requires a recipient acknowledgment; unsuccessful messages can be retried manually.

## Storage and appearance
Messages, contact IDs, contacts, drafts, call history, profile and preferences are stored locally in the app's web storage. They survive ordinary updates, but iOS can clear web data. Export a JSON backup in Settings. Do not share the backup publicly. The name, icon and theme within the app are customizable. iOS manages the installed home-screen name/icon; Settings explains how to create a custom shortcut and export an icon.

## Power usage
No hidden-page update polling; the signaling connection closes when hidden unless a call is active. Audio/video capture runs only for calls. The version check fetches a tiny JSON file every 15 seconds while active (every two minutes with Battery saver). Actual battery usage depends on device, network and calls; it has not been benchmarked.

## Version policy
Current release: 1.0.17. Every requested app change must increment both the app-version meta tag in index.html and version.json, preferably in the same commit. GitHub Pages republishes main. The app checks for updates on launch, foreground and connectivity restoration, and at the configured foreground interval. Update now saves local data and reloads; Later postpones the prompt for two minutes. A service worker retains the installed shell until an approved update.

## Accounts, profiles and shared backgrounds
First launch (including migration from 1.0.2) requires a locally saved username. Usernames are not globally unique and are not a password-based account service; the existing random contact code remains the unique device identifier. Settings allows changing the display name and profile photo. Profile changes sync with contacts while connected. Chat settings allow local-only nickname and photo overrides, plus shared preset or custom-color backgrounds. Both phones save their copy; versioned background changes sync over WebRTC and retry while foregrounded. Offline changes remain pending until a peer connection succeeds. Both users need the updated app. Photos are resized to save local storage and bandwidth. Version 1.0.4 adds choosing a picture from Photos as an in-app icon and exporting it for a custom iOS Shortcuts Home Screen icon. The installed standalone web app's system icon cannot be changed directly.

Version 1.0.5 redesigns the message list, conversation header, grouped bubbles and composer in an iOS Messages-inspired style. Settings > Appearance > Home Screen icon & name provides a preview, photo export, name/link copying and Shortcuts setup. A custom Home Screen shortcut is separate from the installed PWA and may open Safari with a different storage context; keep the existing installation. iOS does not expose a web API to change the installed icon or label in place.

## Version 1.0.6
Contact codes shown in Settings now contain five uppercase letters or digits. The underlying random device ID is unchanged so existing chats, calls and wallpapers remain associated with the original contact. A second foreground-only PeerJS registration resolves the short code to the stable device ID; if a code is already in use, a new one is generated. Both devices must be open and online for initial short-code lookup. Codes are not permanently reserved or authentication secrets; confirm the displayed friend name and username. Legacy long IDs are still accepted. Message yourself using the new-contact dialog or your own code; self messages and wallpapers are saved locally without a network request, and calling yourself is disabled.

## Versions 1.0.7–1.0.9
Native iOS project: see [ios/README.md](ios/README.md) for Xcode, signing and installation. Native preset icon switching and local notification banners/badges require the signed native app. Closed-app delivery needs a push backend and is not implemented. Native binary updates must be signed; GitHub web-client updates continue to prompt and reload. Self messaging is replaced with local voice/video self-call testing; previous self messages are retained but hidden. Read receipts are queued for the peer, with a privacy toggle. Right-swipe returns to Messages. Photos support drag-to-position, zoom, rotation, reset and crop preview before saving. Both peers need the updated client for read receipts.

## Version 1.0.10
Six-digit numeric app numbers are displayed as 11-1111. Old five-character codes are replaced on upgrade; existing contacts and conversation IDs are retained. Calls start only from the Calls tab, including a numeric keypad and saved contacts. Numbers are app-only, not cellular numbers, and are not globally reserved while offline. Self calls are removed; adding your own app number opens an offline conversation that echoes each sent message once. Incoming calls ring on the receiving device while connected and audio is allowed; Settings includes a ringtone toggle and sound test. No closed-app calling or push delivery is supported.

## Version 1.0.11
Hold a message to react, reply, copy or remove it locally. Reactions synchronize with acknowledgments and retries; replies include a quoted preview. Choose a custom six-digit app number in Settings; availability is checked against currently connected users, not permanently reserved. Accounts and all existing local state are retained across normal updates, with a secondary IndexedDB backup when available and existing JSON export. Clearing site data or uninstalling may remove local data. Separate installations may use separate storage. Both peers need the new client for synchronized reactions and replies.

## Version 1.0.12
Messenger-inspired conversation layout with voice and video call buttons in the header, long-press contact avatars to edit nicknames, pictures and chat backgrounds, and a floating reaction strip and action menu anchored near the held message. Swipe a message right to reply; swipe the empty thread area right to go back. Text selection, drag and native context menus are blocked on interface elements, while text fields remain editable. Calls can now start from chats as well as the Calls tab. Existing local data and synchronization are retained.

## Version 1.0.13
Swipe right on a chat row for a live conversation preview that follows your finger. Release before the opening threshold to close the preview without sending read receipts; continue past the threshold and release to open the chat. No extra gesture button. Keyboard viewport recovery, cancelled-swipe cleanup and background cleanup prevent stale overlays. Call your own contact using existing voice/video controls or dial your own number; local self calls test microphone and camera without playing microphone audio back. Actual iPhone gesture behavior needs device testing.

## Version 1.0.14
Hold a contact avatar or open contact settings and choose Delete contact. A confirmation offers optional local chat and call history deletion. Contacts are removed from local lists; background profile sync does not restore removed contacts. Explicitly adding, dialing or receiving new messages or calls may restore them. This is not blocking and does not delete a friend's copy or exported backups.

## Version 1.0.15
Long-press a contact row to open the delete confirmation directly. Cancel returns to the list; regular taps still open chats, and the in-chat avatar still opens contact settings. History deletion remains optional.

## Version 1.0.16
Front-camera self preview is horizontally mirrored; remote video and rear-camera preview retain normal orientation. Switch front/rear cameras during video calls (including self calls) with Flip, preserving the microphone and replacing the outgoing video track. Unsupported camera switches attempt to restore the previous camera. Distinct synthesized sounds play for calling, connection, end, mute/unmute, sent and received messages, and camera switches; Settings includes independent sound-effects and ringtone controls. Web audio requires a user interaction and foreground playback. Native notification alerts may use system sounds. Physical device and two-peer media tests remain necessary.

## Version 1.0.17
Calls show the contact's profile picture with a green audio-reactive ring, replacing the self-call microphone meter. The ring follows incoming audio in friend calls and local microphone audio in self calls; it settles when quiet or muted. Audio analysis does not play back microphone audio and is disconnected at call end. Device playback and animation still require on-device testing.
