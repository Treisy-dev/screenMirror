//
//  ScreenCaster.swift
//  TestFFMPEG
//
//  Created by Кирилл Щёлоков on 02.04.2025.
//

import UIKit
import Swifter
import AVKit
import AVFoundation
import ReplayKit

class ScreenCaster: NSObject {

    private var webServer: HttpServer?

    private var backImageData: Data?
    private var tempImageData: Data?
    private var deviceOrientation: UIDeviceOrientation = .portrait

    func startServer() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .current) { [weak self] _ in
            self?.deviceOrientation = UIDevice.current.orientation
        }

        let httpServer = HttpServer()

        guard let bundlePath = Bundle.main.path(forResource: "ScreenCaster", ofType: "bundle") else {
            print("Can't find resource bundle path")
            return
        }

        guard let resourceBundle = Bundle(path: bundlePath) else {
            print("Wrong Bundle Init")
            return
        }
//        http://192.168.31.168:8085/
        guard let indexPath = resourceBundle.path(forResource: "index", ofType: "html"),
              let htmlString = try? String(contentsOfFile: indexPath, encoding: String.Encoding.utf8) else {
            print("Wrong Index HTML")
            return
        }

        httpServer.get["/"] = { _ in
                .ok(.htmlBody(htmlString))
        }

        if let imagePath = resourceBundle.path(forResource: "background", ofType: "jpeg"),
           let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) {
            self.backImageData = imageData
            httpServer["/background.jpg"] = { _ -> HttpResponse in
                let body: HttpResponseBody = .data(imageData, contentType: "image/jpeg")
                print("Requesting Bacground Image")
                return .ok(body)
            }
        }

        if let imagePath = resourceBundle.path(forResource: "background", ofType: "jpeg"),
           let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) {
            self.tempImageData = imageData

            httpServer["/screencast"] = { [weak self] _ -> HttpResponse in
                if let data = self?.tempImageData {
                    let body: HttpResponseBody = .data(data, contentType: "image/jpeg")

                    return .ok(body)
                } else if let backImageData = self?.backImageData {
                    let body: HttpResponseBody = .data(backImageData, contentType: "image/jpeg")
                    return .ok(body)
                } else {
                    return .ok(.text("Try Later"))
                }
            }
        }

        httpServer.middleware.append { request in
            print("Middleware: \(request.address ?? "unknown address") -> \(request.method) -> \(request.path)")
            return nil
        }

        do {
            try httpServer.start(in_port_t(8085), forceIPv4: true, priority: .background)
            print("Server Started")
        } catch {
            print(error)
        }

        self.webServer = httpServer
    }

    func proccessBuffer(_ buffer: CMSampleBuffer) {
        if let orientationAttachment = CMGetAttachment(buffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber,
           let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) {

            if let cvImageBuffer = CMSampleBufferGetImageBuffer(buffer) {
                let ciimage = CIImage(cvImageBuffer: cvImageBuffer)
                let context = CIContext()

                if let cgImage = context.createCGImage(ciimage, from: ciimage.extent),
                   let newImage = rotateImage(cgImage, orientation: orientation) {
                    let uiImage = UIImage(cgImage: newImage)
                    self.tempImageData = uiImage.jpegData(compressionQuality: 0.1)
                }

            }
        }

    }

    func rotateImage(_ image: CGImage, orientation: CGImagePropertyOrientation) -> CGImage? {
        let imageSize = CGSize(width: image.width, height: image.height)
        var angle: CGFloat = 0.0

        switch orientation {
        case .up:
            angle = 0.0
        case .upMirrored:
            angle = .pi
        case .down:
            angle = .pi
        case .downMirrored:
            angle = 0.0
        case .left:
            angle = -.pi / 2.0
        case .leftMirrored:
            angle = -.pi / 2.0
        case .right:
            angle = .pi / 2.0
        case .rightMirrored:
            angle = .pi / 2.0
        }

        let rotatedSize = CGRect(origin: .zero, size: imageSize).applying(CGAffineTransform(rotationAngle: angle)).size

        guard let context = CGContext(data: nil,
                                      width: Int(rotatedSize.width),
                                      height: Int(rotatedSize.height),
                                      bitsPerComponent: image.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: image.colorSpace!,
                                      bitmapInfo: image.bitmapInfo.rawValue) else {
            return nil
        }

        context.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)
        context.rotate(by: angle)
        context.draw(image, in: CGRect(origin: CGPoint(x: -imageSize.width / 2.0, y: -imageSize.height / 2.0), size: imageSize))

        return context.makeImage()
    }

}

extension UIImage {

    func imageRotated(on degrees: CGFloat) -> UIImage {
      // Following code can only rotate images on 90, 180, 270.. degrees.
      let degrees = round(degrees / 90) * 90
      let sameOrientationType = Int(degrees) % 180 == 0
      let radians = CGFloat.pi * degrees / CGFloat(180)
      let newSize = sameOrientationType ? size : CGSize(width: size.height, height: size.width)

      UIGraphicsBeginImageContext(newSize)
      defer {
        UIGraphicsEndImageContext()
      }

      guard let ctx = UIGraphicsGetCurrentContext(), let cgImage = cgImage else {
        return self
      }

      ctx.translateBy(x: newSize.width / 2, y: newSize.height / 2)
      ctx.rotate(by: radians)
      ctx.scaleBy(x: 1, y: -1)
      let origin = CGPoint(x: -(size.width / 2), y: -(size.height / 2))
      let rect = CGRect(origin: origin, size: size)
      ctx.draw(cgImage, in: rect)
      let image = UIGraphicsGetImageFromCurrentImageContext()
      return image ?? self
    }
}
