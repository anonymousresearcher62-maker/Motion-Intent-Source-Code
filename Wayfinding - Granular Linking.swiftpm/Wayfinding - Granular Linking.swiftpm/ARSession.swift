import SwiftUI
import UIKit
import ARKit
import RealityKit


class CustomSessionDelegate: NSObject, ARSessionDelegate {
    
    var arview: ARView?
    
    var currFrame: CVPixelBuffer?
    var receivedMessage = false
    var imageCarousel: ImageCarousel?
    
    var locationHandler = Location()
    
    override init() {
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.captureFrame), name: Notification.Name("captureFrame"), object: nil)
    }
    
    
    
    
    
    func setCarousel(_ car: ImageCarousel) {
        self.imageCarousel = car
    }
    
    
    @objc func captureFrame(_ notif: Notification) {
        let frameCap = notif.object as! Bool
        receivedMessage = frameCap
    }
    
    func setupView(_ view: ARView) {
        view.session.delegate = self
        let config = ARWorldTrackingConfiguration()
        config.isAutoFocusEnabled = true
        
        
        arview = view
        arview?.session.run(config)
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if receivedMessage == true {
            
            CVPixelBufferLockBaseAddress(frame.capturedImage, .readOnly)
            let im = UIImage(pixelBuffer: frame.capturedImage)
            CVPixelBufferUnlockBaseAddress(frame.capturedImage, .readOnly)
            guard let im = im else {
                return
            }
            
            
            
            DispatchQueue.main.async {
                self.locationHandler.directionSemaphore.wait()
                self.imageCarousel!.directions.append(self.locationHandler.currentDirection)
                self.locationHandler.directionSemaphore.signal()
                
                withAnimation {
                    self.imageCarousel!.ims.append(UIImageW(im: im))
                    
                }
            }
            
            receivedMessage = false
        }
        
    }
    
}

struct ARViewContainer: UIViewRepresentable {
    
    let delegate = CustomSessionDelegate()
    
    @EnvironmentObject var imageCarousel: ImageCarousel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        
        delegate.setupView(arView)
        delegate.setCarousel(imageCarousel)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        //
    }
    
    
}
