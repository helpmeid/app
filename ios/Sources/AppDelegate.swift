import UIKit
import WebKit
import UserNotifications

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
final class MessengerController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private let home = URL(string: "https://helpmeid.github.io/app/")!
    private var web: WKWebView!
    private var lastNotification = Date.distantPast
    private var iconChanging = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
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
        case "badge":
            let count = max(0, min(9999, body["count"] as? Int ?? 0))
            UIApplication.shared.applicationIconBadgeNumber = count
        default: break
        }
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
