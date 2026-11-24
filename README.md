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
Current release: 1.0.9. Every requested app change must increment both the app-version meta tag in index.html and version.json, preferably in the same commit. GitHub Pages republishes main. The app checks for updates on launch, foreground and connectivity restoration, and at the configured foreground interval. Update now saves local data and reloads; Later postpones the prompt for two minutes. A service worker retains the installed shell until an approved update.

## Accounts, profiles and shared backgrounds
First launch (including migration from 1.0.2) requires a locally saved username. Usernames are not globally unique and are not a password-based account service; the existing random contact code remains the unique device identifier. Settings allows changing the display name and profile photo. Profile changes sync with contacts while connected. Chat settings allow local-only nickname and photo overrides, plus shared preset or custom-color backgrounds. Both phones save their copy; versioned background changes sync over WebRTC and retry while foregrounded. Offline changes remain pending until a peer connection succeeds. Both users need the updated app. Photos are resized to save local storage and bandwidth. Version 1.0.4 adds choosing a picture from Photos as an in-app icon and exporting it for a custom iOS Shortcuts Home Screen icon. The installed standalone web app's system icon cannot be changed directly.

Version 1.0.5 redesigns the message list, conversation header, grouped bubbles and composer in an iOS Messages-inspired style. Settings > Appearance > Home Screen icon & name provides a preview, photo export, name/link copying and Shortcuts setup. A custom Home Screen shortcut is separate from the installed PWA and may open Safari with a different storage context; keep the existing installation. iOS does not expose a web API to change the installed icon or label in place.

## Version 1.0.6
Contact codes shown in Settings now contain five uppercase letters or digits. The underlying random device ID is unchanged so existing chats, calls and wallpapers remain associated with the original contact. A second foreground-only PeerJS registration resolves the short code to the stable device ID; if a code is already in use, a new one is generated. Both devices must be open and online for initial short-code lookup. Codes are not permanently reserved or authentication secrets; confirm the displayed friend name and username. Legacy long IDs are still accepted. Message yourself using the new-contact dialog or your own code; self messages and wallpapers are saved locally without a network request, and calling yourself is disabled.

## Versions 1.0.7–1.0.9
Native iOS project: see [ios/README.md](ios/README.md) for Xcode, signing and installation. Native preset icon switching and local notification banners/badges require the signed native app. Closed-app delivery needs a push backend and is not implemented. Native binary updates must be signed; GitHub web-client updates continue to prompt and reload. Self messaging is replaced with local voice/video self-call testing; previous self messages are retained but hidden. Read receipts are queued for the peer, with a privacy toggle. Right-swipe returns to Messages. Photos support drag-to-position, zoom, rotation, reset and crop preview before saving. Both peers need the updated client for read receipts.
