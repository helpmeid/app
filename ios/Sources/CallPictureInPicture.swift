import UIKit
import AVKit
import AVFoundation
import CoreMedia
import CoreVideo
import CoreImage

// Native call PiP renderer. Frames originate only from the current in-app video.
// No frames are stored on disk or transmitted to a server by this renderer.
final class CallFrameView: UIView {
    override class var layerClass: AnyClass { AVSampleBufferDisplayLayer.self }
    var displayLayer: AVSampleBufferDisplayLayer { layer as! AVSampleBufferDisplayLayer }
}

final class CallPictureInPicture: NSObject, AVPictureInPictureControllerDelegate {
    private weak var sourceView: UIView?
    private var controller: AVPictureInPictureController?
    private var videoController: AVPictureInPictureVideoCallViewController?
    private var frameView: CallFrameView?
    private var generation: Int?
    private var pendingStart = false
    private var lastFrame: CFTimeInterval = 0
    private var readyObserver: NSKeyValueObservation?
    private let context = CIContext()
    var status: ((Int, String) -> Void)?

    func prepare(source: UIView, generation: Int) {
        if self.generation == generation, controller != nil { return }
        stop()
        self.generation = generation
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status?(generation, "unavailable")
            return
        }
        sourceView = source
        let viewController = AVPictureInPictureVideoCallViewController()
        viewController.preferredContentSize = CGSize(width: 320, height: 400)
        viewController.view.backgroundColor = .black
        let renderer = CallFrameView()
        renderer.displayLayer.videoGravity = .resizeAspect
        renderer.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(renderer)
        NSLayoutConstraint.activate([
            renderer.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            renderer.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            renderer.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            renderer.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        let content = AVPictureInPictureController.ContentSource(activeVideoCallSourceView: source, contentViewController: viewController)
        let pip = AVPictureInPictureController(contentSource: content)
        pip.delegate = self
        pip.canStartPictureInPictureAutomaticallyFromInline = true
        videoController = viewController
        frameView = renderer
        controller = pip
        readyObserver = pip.observe(\.isPictureInPicturePossible, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async { self?.startIfReady() }
        }
        status?(generation, "ready")
    }

    func pushFrame(_ encoded: String, generation: Int) {
        guard self.generation == generation, encoded.utf8.count <= 180_000,
              CACurrentMediaTime() - lastFrame >= 0.15,
              let data = Data(base64Encoded: encoded),
              let image = CIImage(data: data),
              let layer = frameView?.displayLayer else { return }
        let width = Int(image.extent.width), height = Int(image.extent.height)
        guard width > 0, height > 0, width <= 480, height <= 480 else { return }
        lastFrame = CACurrentMediaTime()
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]]
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer) == kCVReturnSuccess, let pixelBuffer = pixelBuffer else { return }
        context.render(image, to: pixelBuffer)
        var description: CMVideoFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &description) == noErr, let description = description else { return }
        var timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()), decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: description, sampleTiming: &timing, sampleBufferOut: &sample) == noErr, let sample = sample else { return }
        CMSetAttachment(sample, key: kCMSampleAttachmentKey_DisplayImmediately, value: kCFBooleanTrue, attachmentMode: kCMAttachmentMode_ShouldNotPropagate)
        if layer.status == .failed { layer.flush() }
        if layer.isReadyForMoreMediaData { layer.enqueue(sample) }
        startIfReady()
    }

    func toggle(generation: Int) {
        guard self.generation == generation, let controller = controller else { return }
        if controller.isPictureInPictureActive {
            pendingStart = false
            controller.stopPictureInPicture()
        } else {
            pendingStart = true
            startIfReady()
        }
    }

    private func startIfReady() {
        guard pendingStart, let controller = controller, controller.isPictureInPicturePossible, !controller.isPictureInPictureActive else { return }
        pendingStart = false
        controller.startPictureInPicture()
    }

    func stop() {
        pendingStart = false
        readyObserver = nil
        if let controller = controller {
            controller.canStartPictureInPictureAutomaticallyFromInline = false
            if controller.isPictureInPictureActive { controller.stopPictureInPicture() }
        }
        controller?.delegate = nil
        frameView?.displayLayer.flushAndRemoveImage()
        controller = nil
        videoController = nil
        frameView = nil
        generation = nil
        lastFrame = 0
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if let generation = generation { status?(generation, "active") }
    }
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if let generation = generation { status?(generation, "ready") }
    }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        pendingStart = false
        if let generation = generation { status?(generation, "failed") }
    }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(sourceView?.window != nil)
    }
}
