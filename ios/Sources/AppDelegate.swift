import UIKit
import WebKit
import UserNotifications
import AVFoundation
import CallKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = MessengerController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
final class WeakBridge: NSObject, WKScriptMessageHandler {
    weak var target: MessengerController?
    init(_ target: MessengerController) { self.target = target }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.receive(message)
    }
}
final class MessengerController: UIViewController, WKNavigationDelegate, WKUIDelegate, CXProviderDelegate {
    private let home = URL(string: "https://helpmeid.github.io/app/")!
    private var web: WKWebView!
    private var lastNotification = Date.distantPast
    private var iconChanging = false
    private var callAudioActive = false
    private let callController = CXCallController()
    private lazy var callProvider: CXProvider = {
        let config = CXProviderConfiguration()
        config.supportsVideo = true
        config.maximumCallsPerCallGroup = 1
        config.maximumCallGroups = 1
        config.supportedHandleTypes = [.generic]
        let provider = CXProvider(configuration: config)
        provider.setDelegate(self, queue: .main)
        return provider
    }()
    private var systemID: UUID?
    private var systemGeneration: Int?
    private var systemIncoming = false
    private var systemAnswered = false
    private var systemConnected = false
    private var systemMuted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.limitsNavigationsToAppBoundDomains = true
        config.userContentController.add(WeakBridge(self), name: "appBridge")
        web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.isOpaque = false
        web.backgroundColor = .systemBackground
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)
        NSLayoutConstraint.activate([
            web.topAnchor.constraint(equalTo: view.topAnchor),
            web.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            web.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        web.load(URLRequest(url: home, cachePolicy: .useProtocolCachePolicy))
    }

    private func trusted(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        return url.scheme == "https" && url.host == home.host && url.path.hasPrefix("/app/")
    }
    private func feedback(_ text: String) {
        guard let data = try? JSONSerialization.data(withJSONObject: [text]), let json = String(data: data, encoding: .utf8) else { return }
        web.evaluateJavaScript("if(typeof toast==='function')toast(" + json + "[0])", completionHandler: nil)
    }
    func receive(_ message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, trusted(message.frameInfo.request.url),
              let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "icon":
            guard let index = body["index"] as? Int, (0...7).contains(index), !iconChanging else { return }
            guard UIApplication.shared.supportsAlternateIcons else { feedback("Alternate icons aren't available on this build."); return }
            let name: String? = index == 0 ? nil : "Icon\(index)"
            guard UIApplication.shared.alternateIconName != name else { return }
            iconChanging = true
            UIApplication.shared.setAlternateIconName(name) { [weak self] error in
                DispatchQueue.main.async {
                    self?.iconChanging = false
                    self?.feedback(error == nil ? "Home Screen icon changed." : "iOS could not change the icon.")
                }
            }
        case "permission", "test":
            let test = type == "test"
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] allowed, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.feedback(allowed ? "Notifications enabled." : "Enable notifications in iPhone Settings.")
                    if allowed && test { self.notify(title: "App", body: "Notifications are working.") }
                }
            }
        case "notify":
            guard Date().timeIntervalSince(lastNotification) > 0.7,
                  let title = body["title"] as? String, let text = body["body"] as? String else { return }
            lastNotification = Date()
            notify(title: String(title.prefix(60)), body: String(text.prefix(200)))
        case "systemCallStart":
            guard let generation = body["generation"] as? Int, let name = body["name"] as? String else { return }
            startSystemCall(generation: generation, name: String(name.prefix(60)), video: body["video"] as? Bool ?? false, incoming: body["incoming"] as? Bool ?? false)
        case "systemCallAnswer":
            guard let id = matchingCall(body), systemIncoming, !systemAnswered else { return }
            systemAnswered = true
            callController.request(CXTransaction(action: CXAnswerCallAction(call: id))) { [weak self] error in
                if error != nil { DispatchQueue.main.async { if self?.systemID == id { self?.systemAnswered = false } } }
            }
        case "systemCallConnected":
            guard let id = matchingCall(body) else { return }
            systemConnected = true
            if !systemIncoming { callProvider.reportOutgoingCall(with: id, connectedAt: Date()) }
        case "systemCallMute":
            guard let id = matchingCall(body), let muted = body["muted"] as? Bool, muted != systemMuted else { return }
            systemMuted = muted
            callController.request(CXTransaction(action: CXSetMutedCallAction(call: id, muted: muted))) { _ in }
        case "systemCallEnd":
            guard let id = matchingCall(body) else { return }
            clearSystemCall()
            callProvider.reportCall(with: id, endedAt: Date(), reason: .remoteEnded)
        case "callAudio":
            guard let active = body["active"] as? Bool, active != callAudioActive else { return }
            if systemID != nil { callAudioActive = active; return }
            do {
                let session = AVAudioSession.sharedInstance()
                if active {
                    try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
                    try session.setActive(true)
                } else {
                    try session.setActive(false, options: .notifyOthersOnDeactivation)
                }
                callAudioActive = active
            } catch {
                NSLog("Call audio session: %@", String(describing: error))
            }
        case "badge":
            let count = max(0, min(9999, body["count"] as? Int ?? 0))
            UIApplication.shared.applicationIconBadgeNumber = count
        default: break
        }
    }
    private func matchingCall(_ body: [String: Any]) -> UUID? {
        guard let generation = body["generation"] as? Int, generation == systemGeneration else { return nil }
        return systemID
    }
    private func clearSystemCall() {
        systemID = nil
        systemGeneration = nil
        systemIncoming = false
        systemAnswered = false
        systemConnected = false
        systemMuted = false
    }
    private func configureCallAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
    }
    private func sendCallAction(_ action: String, generation: Int, value: Bool = false) {
        guard let data = try? JSONSerialization.data(withJSONObject: [action, generation, value]), let json = String(data: data, encoding: .utf8) else { return }
        web.evaluateJavaScript("window.nativeCallAction && window.nativeCallAction(..." + json + ")", completionHandler: nil)
    }
    private func startSystemCall(generation: Int, name: String, video: Bool, incoming: Bool) {
        if let old = systemID { callProvider.reportCall(with: old, endedAt: Date(), reason: .remoteEnded) }
        clearSystemCall()
        let id = UUID()
        systemID = id
        systemGeneration = generation
        systemIncoming = incoming
        let handle = CXHandle(type: .generic, value: name.isEmpty ? "App call" : name)
        let update = CXCallUpdate()
        update.remoteHandle = handle
        update.localizedCallerName = name
        update.hasVideo = video
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false
        if incoming {
            callProvider.reportNewIncomingCall(with: id, update: update) { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self, self.systemID == id else { return }
                    if error != nil { self.clearSystemCall(); return }
                }
            }
        } else {
            let action = CXStartCallAction(call: id, handle: handle)
            action.isVideo = video
            callController.request(CXTransaction(action: action)) { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self, self.systemID == id else { return }
                    if error != nil { self.clearSystemCall(); return }
                    self.callProvider.reportCall(with: id, updated: update)
                }
            }
        }
    }
    func providerDidReset(_ provider: CXProvider) {
        if let generation = systemGeneration { sendCallAction("end", generation: generation) }
        clearSystemCall()
        callAudioActive = false
    }
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        guard action.callUUID == systemID else { action.fail(); return }
        configureCallAudio()
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
        if systemConnected { provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date()) }
        action.fulfill()
    }
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard action.callUUID == systemID, let generation = systemGeneration else { action.fail(); return }
        configureCallAudio()
        systemAnswered = true
        sendCallAction("answer", generation: generation)
        action.fulfill()
    }
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard action.callUUID == systemID, let generation = systemGeneration else { action.fulfill(); return }
        clearSystemCall()
        sendCallAction("end", generation: generation)
        action.fulfill()
    }
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard action.callUUID == systemID, let generation = systemGeneration else { action.fail(); return }
        systemMuted = action.isMuted
        sendCallAction("mute", generation: generation, value: action.isMuted)
        action.fulfill()
    }
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        callAudioActive = true
        web.evaluateJavaScript("document.getElementById('remoteVideo')?.play().catch(()=>{})", completionHandler: nil)
    }
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        callAudioActive = false
    }
    private func notify(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if trusted(url) { decisionHandler(.allow); return }
        if navigationAction.navigationType == .linkActivated || navigationAction.targetFrame == nil {
            if ["https", "shortcuts"].contains(url.scheme ?? "") { UIApplication.shared.open(url) }
        }
        decisionHandler(.cancel)
    }
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(frame.isMainFrame && origin.protocol == "https" && origin.host == home.host ? .prompt : .deny)
    }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(alert.textFields?.first?.text) })
        present(alert, animated: true)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        let alert = UIAlertController(title: "Can't open app", message: "Connect to the internet for the first launch, then try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in guard let self = self else { return }; self.web.load(URLRequest(url: self.home)) })
        if presentedViewController == nil { present(alert, animated: true) }
    }
}
