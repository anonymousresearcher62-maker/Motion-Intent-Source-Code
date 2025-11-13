import SwiftUI
import Combine
//
//  HeadphoneManager.swift
//  APMotionCollection
//
//  Created by Anonymous on 6/24/25.
//

import CoreMotion
import Accelerate



enum HeadPose: String {
    case LookingForward = "Forward"
    case LookingLeft = "Left"
    case LookingRight = "Right"
    case LookingUp = "Up"
    case LookingDown = "Down"
}




class HeadphoneManager: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
    
    @Published var hpMotionManager = CMHeadphoneMotionManager()
    @Published var isConnected: Bool = false
    
    @Published var samples = [MotionData]()
    @Published var inference: HeadPose = .LookingForward
    var prevPose: HeadPose = .LookingForward
    
    // To append rotation rate along Z axis
    var subSampleRotations = [Double]()
    
    
    let operationQueue = OperationQueue()
    
    let MAX_SAMPLES = 120
    let ROTATION_Z_SAMPLES = 5
    
    var headPosePublisher: MotionStateDelegate?
    
    var headDegree = 0.0
    var sem = DispatchSemaphore(value: 1)
    
    override init() {
        super.init()
        hpMotionManager.delegate = self
        hpMotionManager.startConnectionStatusUpdates()
        // rotation rate (gyroscope) - CMRotationRate
        // attitude - CMAttitude
        // acceleration (total + gravity) - CMAcceleration (only x and y needed)
    }
    
    
    func restartActivity() -> Void {
        print("restarting headphones")
        self.hpMotionManager = CMHeadphoneMotionManager()
        self.hpMotionManager.stopConnectionStatusUpdates()
        if self.hpMotionManager.isDeviceMotionActive {
            self.hpMotionManager.stopDeviceMotionUpdates()
            operationQueue.cancelAllOperations()
        }
        self.hpMotionManager.startConnectionStatusUpdates()
        self.hpMotionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: self.motionHandler)
        self.inference = .LookingForward
        self.prevPose = .LookingForward
        sem.wait()
        self.headDegree = 0.0
        sem.signal()
        self.subSampleRotations = [Double]()
        self.samples = [MotionData]()
    }
    
    deinit {
        
        self.stopActivity()
    }
    
    func stopActivity() -> Void {
        self.hpMotionManager.stopConnectionStatusUpdates()
        self.hpMotionManager.stopDeviceMotionUpdates()
        operationQueue.cancelAllOperations()
    }
    
    func getDegree() -> Double {
        var degree = 0.0
        sem.wait()
        degree = self.headDegree
        sem.signal()
        return degree
    }
    
    func motionHandler(_ motion: CMDeviceMotion?, _ error: (any Error)?) {
        
        
            guard let motion = motion else {
                return
            }
            let motionData = MotionData(motion: motion, timestamp: Date())
            
            self.samples.append(motionData)
            let absRate = abs(motion.rotationRate.z)
            
            
            sem.wait()
            self.headDegree = motion.attitude.yaw.degree
        
            sem.signal()
            
            self.subSampleRotations.append(absRate * absRate)
            
            if self.subSampleRotations.count >= self.ROTATION_Z_SAMPLES {
                // determine energy threshold
                // Finite length enrgy calculation:
                //      sum from 0 to n-1: abs(x[n])^2
                let energy = vDSP.sum(self.subSampleRotations)
                self.subSampleRotations.removeAll()
                
                // Check the yaw rotation here. If motion has been triggered (higher energy values), then we can see where the user is looking.
                if energy >= 0.70 && self.samples.count >= 2 {
                    
                    // compare recent reading to left-neighbor. If positive peak, we turned right.
                    let yawDegree = MathUtil.toDegree(motionData.motion.attitude.yaw)
                    
                    // we can use this same logic for up and down.
                    let pitchDegree = MathUtil.toDegree(motionData.motion.attitude.pitch)
                    
                    
                    if yawDegree >= 45 {
                        //print("Yaw Left: \(yawDegree)")
                        self.inference = .LookingLeft
                    } else if yawDegree <= -40 {
                        print("Yaw Right: \(yawDegree)")
                        self.inference = .LookingRight
                    } 
                    
                    if pitchDegree >= 23 {
                        self.inference = .LookingUp
                    } else if pitchDegree <= -23 {
                        self.inference = .LookingDown
                    } 
                    
                    if (pitchDegree < 23 && pitchDegree > -23) && (yawDegree < 45 && yawDegree > -39) {
                        self.inference = .LookingForward
                    }
                    
                    
                    // send publisher value if attached
                    if let headPosePublisher = headPosePublisher {
                        // also only send if the poses have changed. we dont need
                        // every update
                        if self.prevPose != self.inference {
                            prevPose = inference
                            headPosePublisher.motionEventListener(self.inference)
                        }
                    }
                    
                }
                
                if self.samples.count >= self.MAX_SAMPLES {
                    self.samples.removeFirst()
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
        operationQueue.cancelAllOperations()
        
    }
    
    
}
