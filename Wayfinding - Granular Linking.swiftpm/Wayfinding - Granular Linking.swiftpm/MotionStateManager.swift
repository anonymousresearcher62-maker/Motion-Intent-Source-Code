import SwiftUI
import Combine 
import AVFoundation

protocol MotionStateDelegate {
    func motionEventListener(_ pose: HeadPose)
    func locationChangeListener(_ direction: String)
}

class MotionStateManager: MotionStateDelegate {
    
    
    let voice = AVSpeechSynthesisVoice(language: "en-US")
    let synthesizer = AVSpeechSynthesizer()
    
    let audioSession = AVAudioSession.sharedInstance()
    
    
    private var locationManager: Location
    private var headphoneMotion: HeadphoneManager
    private var delegate: MotionStateDelegate?
    private let motionManager = DeviceMotionNav()
    
    var currentHeadPose: HeadPose?
    
    private var llm: LLMNavAPI?
    private var floorGraph: FloorGraph
    
    private var roomName: String
    @Binding var responseBinding: String
    
    private var misaligned = false
    
    init(withDeviceMotionManager location: Location, andHeadphoneManager headphoneMotion: HeadphoneManager, usingGraph floorgraph: FloorGraph, insideRoom rn: String, _ response: Binding<String> = .constant("")) {
        self.floorGraph = floorgraph
        self.locationManager = location
        self.headphoneMotion = headphoneMotion
        self._responseBinding = response
        self.roomName = rn
        delegate = self
        self.headphoneMotion.headPosePublisher = delegate
        self.locationManager.locationPublisher = delegate
        self.llm = LLMNavAPI(withGraph: floorgraph)
        self.synthesizer.usesApplicationAudioSession = true
    }
    
    func sendAdvancedRequest(_ query: String) {
        let headPose = self.headphoneMotion.inference // current pose
        let currentState = floorGraph.nodeStorage[roomName]!.getNode(forDirection: locationManager.currentDirection)
        Task {
            var response = await llm?.makeAsyncRequest(withPrompt: "I am currently in Room \(roomName) facing wall \(currentState!.wallId), \(currentState!.direction). I am looking \(headPose.rawValue). \(query)")
            if let response = response {
                self.responseBinding = response
                var utter = AVSpeechUtterance(string: response)
                self.synthesizer.speak(utter)
            }
        }
    }
    
    
    // Listen for changes in motion/ head pose and observe the 
    // alignment. 
    // This event listener is responsible for TEMPORARY state changes.
    // Our head indicates "where we desire to go". it effectively asks the question to the LLM:
    // "What am i facing to my right/left"? this is the interactionless part. 
    func motionEventListener(_ pose: HeadPose) {
        //print(pose)
        let headPose = pose
        let devicePose = motionManager.getDevicePose()
        currentHeadPose = pose
        //print("Head Motion event!")
        //print("Head Pose: \(headPose)")
        //print("Device Pose: \(devicePose)")
        //print("Misaligned: \(misaligned)")
        //print("---------")
        // if both poses match, we have a permanent state. the user can ask 
        // about current or future custom states. reset activities & change our graph action. 
        // if they deviate through motion of the head, then, its a temporary state. 
        if headPose != devicePose {
            self.misaligned = true
            // temporary state. issue interactionless query to LLLM.
            // this ONLY happens with head motion (the intent part)
            // take device pose to be current permanent state.
            let currentState = floorGraph.nodeStorage[roomName]!.getNode(forDirection: locationManager.currentDirection)
            Task {
                var prompt = "Hello." 
                if headPose == .LookingRight || headPose == .LookingLeft {
                    prompt = "I am currently in Division \(roomName) facing wall \(currentState!.wallId), which is \(currentState!.direction). I am looking to my \(headPose.rawValue). Tell me what division in this room is to my \(headPose.rawValue) using the objects in that division."
                }
                
                //analogous to looking "Backward" interactionless
                else if headPose == .LookingUp {
                    prompt = "I am currently in Room \(roomName) facing wall \(currentState!.wallId), which is \(currentState!.direction). Tell me what division in this room is behind me using the objects in that division."
                }
                //analogous to looking "Forward" interactionless
                else if headPose == .LookingDown {
                    prompt = "I am currently in Room \(roomName) facing wall \(currentState!.wallId), which is \(currentState!.direction). Tell me what division in this room is in front of me and summarize using the objects in that division."
                }
                //print(prompt)
                
                
                
                var response = await llm?.makeAsyncRequest(withPrompt: prompt)
                if let response = response {
                    self.responseBinding = response
                    // todo: add vocal feedback
                    var utter = AVSpeechUtterance(string: response)
                    self.synthesizer.speak(utter)
                }
            }
        } else {
            self.misaligned = false
        }
        // if both poses match, we have a permanent state. the user can ask 
        // about current or future custom states. 
    }
    
    // listen for changes in direction and observe
    // the head pose too. 
    // location changes are responsible for PERMANENT state. 
    // if we've moved, then we reset the state and position in the graph. Since
    // an updtae to our graph state change, one interactionless
    // mechanism to the LLM takes place (telling us we've moved x, facing x, and what we are seeing).
    // this only works before and after mismatch. in order to do simulatenously, i
    // probably have to emit when motion stops as well
    func locationChangeListener(_ direction: String) {
        //print("Event Listener")
        //print(direction)
        return
        let devicePose = motionManager.getDevicePose()
        
        
        if let headPose = currentHeadPose {
            /*
            print("Device motion event!")
            print("Head Pose: \(headPose)")
            print("Device Pose: \(devicePose)")
            print("Misaligned: \(misaligned)")
            print("---------")*/
            
            // check if they match then we have a new permanent state. we need to see if we've moved to require a reset for a permanent state. If so, we have a new interaction to the LLM telling us what we are now facing. 
            if misaligned && (headPose == devicePose) && (headPose != .LookingForward){
                // reset activities because the poses need to change back to normal!!
                
                guard let currentState = floorGraph.nodeStorage[roomName]!.getNode(forDirection: locationManager.currentDirection) else {
                    print("\(locationManager.currentDirection) not recognized.")
                    return
                }
                
                Task {
                    self.misaligned = false
                    var prompt = "I am currently in Room \(roomName) facing wall \(currentState.wallId), \(currentState.direction). What wall or quadrant am I looking at?"
                    print(prompt)
                    var response = await llm?.makeAsyncRequest(withPrompt: prompt)
                    if let response = response {
                        self.responseBinding = response
                        // todo: add vocal feedback
                        var utter = AVSpeechUtterance(string: response)
                        self.synthesizer.speak(utter)
                    }
                    self.restartActivities()
                }
                
                
            }
        }
        
        
    }
    
    func stopActivities() -> Void {
        self.motionManager.stopActivities()
        self.headphoneMotion.stopActivity()
    }
    
    func restartActivities() -> Void {
        self.motionManager.restartActivity()
        self.headphoneMotion.restartActivity()
    }
}
