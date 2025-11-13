import SwiftUI
import UIKit
import ARKit
import RealityKit



class CustomNavSessionDelegate: NSObject, ARSessionDelegate {
    
    var arview: ARView?
    
    var currFrame: CVPixelBuffer?
    var currentIm: UIImage?
    var receivedMessage = false
    
    var locationHandler = Location()
    
    var imSem = DispatchSemaphore(value: 1)
    override init() {
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.navFrame), name: Notification.Name("navFrame"), object: nil)
    }
    
    
    
    @objc func navFrame(_ notif: Notification) {
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
    
    func getIm() -> UIImage? {
        var im: UIImage? = nil
        imSem.wait()
        im = self.currentIm
        imSem.signal()
        return im
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        imSem.wait()
            CVPixelBufferLockBaseAddress(frame.capturedImage, .readOnly)
            let im = UIImage(pixelBuffer: frame.capturedImage)
            self.currentIm = im
            CVPixelBufferUnlockBaseAddress(frame.capturedImage, .readOnly)
        imSem.signal()
            
        
        
    }
    
}

struct ARNavViewContainer: UIViewRepresentable {
    
    let delegate = CustomNavSessionDelegate()
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        
        delegate.setupView(arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        //
    }
    
    
}

