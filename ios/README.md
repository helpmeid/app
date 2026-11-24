# Native iPhone app (1.0.19)

This Xcode project builds a real iOS application with a UIKit shell and a persistent WKWebView running the existing HTTPS messaging client. It is not a PWA shortcut. The system icon can be switched among eight bundled presets using Settings > Appearance. iOS may show its own confirmation alert. A custom user photo can still be used inside the app, but not as a system app icon. The actual installed name is fixed by the signed app's Info.plist.

## Build on macOS
Install Xcode and XcodeGen (brew install xcodegen). In ios/ run:
    python3 generate_icons.py
    xcodegen generate
    open MessengerApp.xcodeproj
Select your own signing team in Signing & Capabilities and a unique bundle identifier if needed. Build to your connected iPhone, or archive and distribute through TestFlight using an Apple Developer account. The native app's local storage is separate from the existing installed web app; keep the original if it contains important messages.

## Updates
The web messaging client checks version.json and prompts before reloading when GitHub publishes a new version. Native code, bundled icons and app display name changes require a newly signed iOS build; TestFlight can distribute those updates. A native app cannot install arbitrary IPA updates on its own. App Store review rules apply to remote functionality; this is a development wrapper and has not been reviewed or approved.

## Notifications
Settings > Notifications > Enable / test requests Apple notification permission and posts a test alert. The native bridge shows local banners and badges for incoming messages and calls that reach the running client. Message previews can be disabled. It does not register APNs or deliver new alerts when the app is closed: that requires a message/push backend and Apple push configuration.

## Calling
Use Calls to dial a six-digit app number in 11-1111 format or choose a saved contact. Incoming calls ring while connected and audio is enabled. Self calls are removed; adding your own number opens a local echo conversation.

The CI workflow builds an unsigned app bundle for compile checking. It cannot install on an ordinary iPhone until code signed. No Apple signing credentials are stored here.

## Messaging and photos
Read receipts are enabled by default, can be disabled in Settings > Privacy, and are queued until peers can exchange acknowledgements. Swipe right to leave a conversation or return from another tab. Profile, contact and custom icon pictures support a circular crop preview with drag, zoom, rotate and reset before saving.

Version 1.0.11 adds hold-to-react actions, quoted replies, custom app numbers and local IndexedDB backup.

Version 1.0.12 updates the Messenger-inspired chat interface and restores direct call controls in chats.

Version 1.0.13 restores local self calls through standard call controls, adds live swipe previews and viewport recovery.

Version 1.0.14 adds local contact deletion with optional chat and call history cleanup.

Version 1.0.15 adds direct contact-row long-press deletion confirmation.

Version 1.0.16 adds mirrored front-camera preview, camera switching and configurable call/message sounds.

Version 1.0.17 replaces the microphone meter with an audio-reactive profile-picture ring.

Version 1.0.18 adds self-call ringing and acceptance, outgoing ringback and adaptive call-screen colors.

Version 1.0.19 adds camera on/off controls, signaling retries and contact presence indicators.

Version 1.0.20 declares the background audio mode and adds a voice-chat AVAudioSession bridge during connected calls. A signed rebuild is necessary. The WKWebView still depends on iOS WebRTC/media lifecycle behavior; background calling is not guaranteed. Web screen sharing uses getDisplayMedia when available. Full native system-wide screen broadcasting would require a ReplayKit extension and native media integration, not included here.

Version 1.0.21 redesigns the interface and introduces a full-screen dual-video call layout with a movable local preview and circular controls.

Version 1.1.0 adds preliminary CallKit lifecycle integration for real peer calls, WKWebView picture-in-picture configuration and system call controls. Requires signed rebuild and device tests. WebRTC remains in WKWebView; no native media stack or VoIP push service.

Version 1.1.1 adds an experimental AVKit PiP renderer and local video-frame bridge. It requests automatic native PiP on leaving a video call. This is not an independent native WebRTC engine and the frames may freeze when WKWebView is suspended. Build, sign and test on physical iPhone before relying on it.

Version 1.1.2 improves the shared web interface with a persistent outbox, history loading, and in-app call minimization.

Version 1.1.3 adds pinned chats, message search, unread indicators, ordered automatic delivery and improved connection recovery.

Version 1.1.4 unifies horizontal swipe navigation throughout the web interface, including safe dialog dismissal and active-call minimization.

Version 1.1.5 adds interactive chat-back transitions that reveal the previous main screen as the chat moves.

Version 1.1.6 improves read-receipt display and synchronization.

Version 1.1.7 adds finger-tracking transitions between the main tabs using actual destination content.
