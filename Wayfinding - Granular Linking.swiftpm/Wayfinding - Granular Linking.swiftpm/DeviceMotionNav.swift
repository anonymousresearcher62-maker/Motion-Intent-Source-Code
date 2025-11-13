import SwiftUI
import CoreMotion
// stripped down version of DeviceMotion class.
// This one simply emits device yaw for alignment events.
class DeviceMotionNav: NSObject {
    
    var motionManager = CMMotionManager()
    
    var inference: DevicePose = .LookingForward
    

    
    
    let operationQueue = OperationQueue()
    
    var currentYaw = 0.0
    
    let sem = DispatchSemaphore(value: 1)
    let semtwo = DispatchSemaphore(value: 1)
    
    override init() {
        super.init()
        self.beginStream()
    }
    
    func beginStream() {
        
        self.motionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: self.motionHandler)
    }
    
    
    
    
    
    func restartActivity() -> Void {
        if self.motionManager.isDeviceMotionActive {
            self.motionManager.stopDeviceMotionUpdates()
        }
        
        self.motionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: self.motionHandler)
        self.inference = .LookingForward
    }
    
    func stopActivities() -> Void {
        self.motionManager.stopDeviceMotionUpdates()
    }
    
    
    // on iPad M1 roughly 120 samples per second
    func motionHandler(_ motion: CMDeviceMotion?, _ error: (any Error)?) {
        
        
        
        guard let motion = motion else {
            return
        }
        
        let yaw =  motion.attitude.yaw.degree 
        semtwo.wait()
        
        if yaw >= 45 {
            //print("Yaw Left: \(yawDegree)")
            self.inference = .LookingLeft
            
        } else if yaw <= -45 {
            
            //print("Yaw Right: \(yawDegree)")
            self.inference = .LookingRight
            
        } else {
            
            //print("Yaw Forward: \(yawDegree)")
            self.inference = .LookingForward
            
        }
        semtwo.signal()
        sem.wait()
        currentYaw = yaw
        sem.signal()
        
    }
    
    func getYaw() -> Double {
        var yaw = 0.0
        sem.wait()
        yaw = self.currentYaw
        sem.signal()
        return yaw
    }
    
    
    func getDevicePose() -> DevicePose {
        var devicePose = DevicePose.LookingForward
        semtwo.wait()
        devicePose = self.inference
        semtwo.signal()
        return devicePose
    }
    
    
    
    
    
}
