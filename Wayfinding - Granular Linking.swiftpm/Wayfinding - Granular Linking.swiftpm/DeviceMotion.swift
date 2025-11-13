import SwiftUI
import Combine
//
//  DeviceMotion
//  motion buddy
//
//  Created by Anonymous on 6/24/25.
//

import CoreMotion
import Accelerate
import AVFoundation
import AudioToolbox
import CoreLocation

enum DataFilter: Int {
    case Rotation = 0
    case Attitude
    case Acceleration
}

typealias DevicePose = HeadPose


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


extension Double {
    var degree: Double {
        get {
            return (self * 180) / Double.pi
        }
    }
}



class Location: NSObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var currentDirection = ""
    var previousDirection = ""
    var directionSemaphore = DispatchSemaphore(value: 1)
    
    var locationPublisher: MotionStateDelegate?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        self.locationManager.startUpdatingHeading()
    }
    
    deinit {
        self.stopActivities()
    }
    
    func stopActivities() {
        self.locationManager.stopUpdatingHeading()
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        var direction = ""
        let heading  = Int(newHeading.magneticHeading)
        
        // This is a very basic algorithmic compensation for our use case.
        
        
        
        // standard 
        // 0/360 = north, 90 = east, 180 = south, 270 = west
        // We pick the closest point depending on heading,
        // for ex: an angle tolerance of less than 5 from the next point,
        // would give us the new point: 35 = NE
        
        if (heading >= 0 && heading < 35) {
            direction = "North"
        } else if (heading >= 35 && heading < 85) {
            direction = "Northeast"
        } else if (heading >= 85 && heading < 130) {
            direction = "East"
        } else if (heading >= 130 && heading < 175) {
            direction = "Southeast"
        } else if (heading >= 175 && heading < 220) {
            direction = "South"
        } else if (heading >= 220 && heading < 270) {
            direction = "Southwest"
        } else if (heading >= 270 && heading < 310) {
            direction = "West"
        } else if (heading >= 310 && heading < 340) {
            direction = "Northwest"
        } else if (heading >= 340) {
            direction = "North"
        }
        
        directionSemaphore.wait()
        self.currentDirection = direction
        
        // publish event to any listeners if attached
        if let locationPublisher = locationPublisher {
            // no need to emit every single direction change.
            // we are focused on strict changes
            if previousDirection != currentDirection {
                previousDirection = currentDirection
                locationPublisher.locationChangeListener(self.currentDirection)
            }
        }
        
        directionSemaphore.signal()
        
    }
    
    
    
    
}





class DeviceMotion: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    @Published var motionManager = CMMotionManager()
    
    
    var samples = [MotionData]()
    @Published var inference: DevicePose = .LookingForward
    @Published var isEnrollmentDone = false
    // To append rotation rate along X axis (points upward on the i-device). see
    // CMMotionManager on Apple's documentatio website.
    
    // IMPORTANT NOTE!! X POINTS UP WHEN THE DEVICE IS IN LANDSCAPE MODE!
    // Y POINTS UP WHEN THE DEVICE IS IN PORTRAIT MODE.
    // TO-DO: CREATE EITHER A SWITCH FOR THIS OR ALWAYS ASSUME DEVICE IS LANDSCAPE.
    var subSampleRotations = [Double]()
    
    
    let operationQueue = OperationQueue()
    
    let MAX_SAMPLES = 120
    let ROTATION_Z_SAMPLES = 50
    
    var rotationStateComplete = true 
    var enrollmentStateComplete = false
    
    var currentEnergy = 0.0
    var currentYaw = 0.0
    var previousYaw = 0.0
    
    // by default it should talk 
    var shouldTalk = true
    
    let u1 = AVSpeechUtterance(string: "Rotate Right")
    let u2 = AVSpeechUtterance(string: "Scene Captured")
    let u3 = AVSpeechUtterance(string: "Enrollment Complete")
    let u4 = AVSpeechUtterance(string: "Stop")
    
    let voice = AVSpeechSynthesisVoice(language: "en-US")
    let synthesizer = AVSpeechSynthesizer()
    
    let audioSession = AVAudioSession.sharedInstance()
    
    var player: AVAudioPlayer?
    let sem = DispatchSemaphore(value: 1)
    var disable = false
    
    var milestoneMask = [0,0,0,0]
    var snaphotMask = [0,0,0,0]
    var currentWall = 0
    
    override init() {
        super.init()
        
        
    }
    
    func beginStream() {
        
        self.motionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: self.motionHandler)
        synthesizer.delegate = self
        synthesizer.usesApplicationAudioSession = true
        do {
            try audioSession.setCategory(.playback)
        } catch {
            //
        }
        
        self.operationQueue.maxConcurrentOperationCount = 1
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
        sem.signal()
    }
    
    func restartActivity() -> Void {
        if self.motionManager.isDeviceMotionActive {
            self.motionManager.stopDeviceMotionUpdates()
        }
        
        self.motionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: self.motionHandler)
        self.inference = .LookingForward
    }
    
    // on iPad M1 roughly 120 samples per second
    func motionHandler(_ motion: CMDeviceMotion?, _ error: (any Error)?) {
        
        if disable {
            
            return
        }
        
        if enrollmentStateComplete {
            disable = true
            self.motionManager.stopDeviceMotionUpdates()
            DispatchQueue.main.async {
                self.isEnrollmentDone = true
            }
            operationQueue.cancelAllOperations()
            return
        }
        
        guard let motion = motion else {
            return
        }
        let motionData = MotionData(motion: motion, timestamp: Date())
        
        self.samples.append(motionData)
        
        
        let absRate = abs(motion.rotationRate.x)
        self.subSampleRotations.append(absRate * absRate)
        
        if self.subSampleRotations.count >= self.ROTATION_Z_SAMPLES {
            // determine energy threshold
            // Finite length enrgy calculation:
            //      sum from 0 to n-1: abs(x[n])^2
            self.currentEnergy = vDSP.sum(self.subSampleRotations)
            self.subSampleRotations.removeAll()
            
            if self.currentEnergy >= 1.6 {
                if rotationStateComplete == true {
                    rotationStateComplete = false
                }
                //As the user is moving, check to see if we've rotated about 90 degrees from previous (with a tolerance for roughly +/- 1. 
                
                var yaw =  motionData.motion.attitude.yaw.degree 
                
                if yaw >= 0  {
                    // flipped to left-side rotations. treat new yaw as offset.
                    yaw = yaw - 360
                }
                
                yaw  = abs(yaw)
                previousYaw = currentYaw
                currentYaw = yaw
                
                // Add an audible cue to tell the user when they have completed a 90 degree rotation. 
                // set rotationStateComplete to true
                if (84 <= Int(yaw) && Int(yaw) <= 94) {
                    
                    currentWall = 1
                    
                    if milestoneMask[0] != 1 {
                        sem.wait()
                        synthesizer.speak(u4)
                        
                        if rotationStateComplete == false {
                            rotationStateComplete = true
                        }
                        
                        if shouldTalk == false {
                            shouldTalk = true
                        }
                        milestoneMask[0] = 1
                    }
                    
                    
                    
                    
                } else if (Int(yaw) >= 174 && Int(yaw) <= 180) {
                    
                    currentWall = 2
                    
                    
                    if milestoneMask[1] != 1 {
                        sem.wait()
                        synthesizer.speak(u4)
                        
                        if rotationStateComplete == false {
                            rotationStateComplete = true
                        }
                        
                        if shouldTalk == false {
                            shouldTalk = true
                        }
                        milestoneMask[1] = 1
                    }
                    
                    
                } else if (Int(yaw) >= 264 && Int(yaw) <= 270) {
                    
                    currentWall = 3
                    
                    if milestoneMask[2] != 1 {
                        sem.wait()
                        synthesizer.speak(u4)
                        
                        
                        milestoneMask[2] = 1
                        sem.wait()
                        synthesizer.speak(u3)
                        if enrollmentStateComplete == false {
                            enrollmentStateComplete = true
                        }
                        
                        if snaphotMask[currentWall] != 1 {
                            //post message to arkit
                            NotificationCenter.default.post(name: Notification.Name("captureFrame"), object: true)
                            // mask it
                            snaphotMask[currentWall] = 1
                        }
                        
                    }
                    
                }
                
                
                
                
            } else {
                
                
                
                if shouldTalk {
                    sem.wait()
                    synthesizer.speak(u1)
                    shouldTalk.toggle()
                    
                }
                
                if snaphotMask[currentWall] != 1 {
                    //post message to arkit
                    NotificationCenter.default.post(name: Notification.Name("captureFrame"), object: true)
                    // mask it
                    snaphotMask[currentWall] = 1
                }
                
                
                
            }
            
        }
        
        if self.samples.count >= self.MAX_SAMPLES {
            self.samples.removeFirst()
        }
        
    }
    
    
    
    
    
    
    
    
}


