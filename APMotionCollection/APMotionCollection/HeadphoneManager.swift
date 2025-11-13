//
//  HeadphoneManager.swift
//  APMotionCollection
//
//  Created by Anonymous on 6/24/25.
//

import CoreMotion
import Accelerate
import AVFoundation

enum DataFilter: Int {
    case Rotation = 0
    case Attitude
    case Acceleration
}

enum HeadPose {
    case LookingForward
    case LookingLeft
    case LookingRight
}

struct MotionData: Identifiable {
    let id = UUID()
    var motion: CMDeviceMotion
    var timestamp: Date
}

struct MathUtil {
    static func toDegree(_ radian: Double) -> Double {
        return (radian * 180) / Double.pi
    }
}


class HeadphoneManager: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
  
    @Published var hpMotionManager = CMHeadphoneMotionManager()
    @Published var isConnected: Bool = false
    
    @Published var samples = [MotionData]()
    @Published var inference: HeadPose = .LookingForward
    
    // To append rotation rate along Z axis
    var subSampleRotations = [Double]()
    
    let operationQueue = OperationQueue()
    
    let MAX_SAMPLES = 100
    let ROTATION_Z_SAMPLES = 5
    
    override init() {
        super.init()
        hpMotionManager.delegate = self
        hpMotionManager.startConnectionStatusUpdates()
        // rotation rate (gyroscope) - CMRotationRate
        // attitude - CMAttitude
        // acceleration (total + gravity) - CMAcceleration (only x and y needed)
    }
    
    func resetBuffer() -> Void {
        DispatchQueue.main.async {
            self.samples.removeAll()
        }
    }
    
    func restartActivity() -> Void {
        if self.hpMotionManager.isDeviceMotionActive {
            self.hpMotionManager.stopDeviceMotionUpdates()
        }
        
        self.hpMotionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: self.motionHandler)
        self.inference = .LookingForward
    }
    
    
    func motionHandler(_ motion: CMDeviceMotion?, _ error: (any Error)?) {
        
        DispatchQueue.main.async {
            guard let motion = motion else {
                return
            }
            let motionData = MotionData(motion: motion, timestamp: Date())
            
            self.samples.append(motionData)
            let absRate = abs(motion.rotationRate.z)
            
            
            self.subSampleRotations.append(absRate * absRate)
            
            if self.subSampleRotations.count >= self.ROTATION_Z_SAMPLES {
                // determine energy threshold
                // Finite length enrgy calculation:
                //      sum from 0 to n-1: abs(x[n])^2
                let energy = vDSP.sum(self.subSampleRotations)
                self.subSampleRotations.removeAll()
                
                // Check the yaw rotation here. If motion has been triggered (higher energy values), then we can see where the user is looking.
                if energy >= 0.75 && self.samples.count >= 2 {
                    
                    // compare recent reading to left-neighbor. If positive peak, we turned right.
                    let yawDegree = MathUtil.toDegree(motionData.motion.attitude.yaw)
                    
                    
                    if yawDegree >= 45 {
                        print("Yaw Left: \(yawDegree)")
                        self.inference = .LookingLeft
                    } else if yawDegree <= -45 {
                        print("Yaw Right: \(yawDegree)")
                        self.inference = .LookingRight
                    } else {
                        print("Yaw Forward: \(yawDegree)")
                        self.inference = .LookingForward
                    }
                    
                }
                
                if self.samples.count >= self.MAX_SAMPLES {
                    self.samples.removeFirst()
                }
                    
            }
            
        }
        
    }
    
    
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        //stub
        DispatchQueue.main.async {
            self.isConnected = true
        }
        
        
        self.hpMotionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: self.motionHandler)
        
    }
    
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        //stub
        DispatchQueue.main.async {
            self.isConnected = false
        }
        self.hpMotionManager.stopDeviceMotionUpdates()
    
    }
    

}
