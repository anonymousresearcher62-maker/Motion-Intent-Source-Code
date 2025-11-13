import SwiftUI

struct NavigateView: View {
    
    @EnvironmentObject var wrappedFloorPlan: FloorPlanGraphWrapper
    @State var beginMotion = false
    @State var isRoomDetected = false
    
    
    @State var detectedRoom = ""
    @State var roomName = ""
    var primaryView = ARNavViewContainer()
    
    var body: some View {
        VStack {
            ZStack {
                primaryView
                    .ignoresSafeArea(.all)
                if beginMotion {
                    MotionNavView(loadedGraph: roomName, floorgraph: wrappedFloorPlan.floorPlan, locationHandler: primaryView.delegate.locationHandler)
                }
                if !beginMotion {
                    VStack {
                        Text("Quadrant: \(detectedRoom)")
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial, in:
                                RoundedRectangle(cornerRadius: 14)
                            )
                            .padding([.leading, .trailing])
                            .opacity((detectedRoom.isEmpty) ? 0.0 : 1.0)
                        Spacer()
                        createDetectRoom()
                        createBeginMotion()
                        
                    }
                }
            }
        }
        
    }
    
    
    func createDetectRoom() -> some View {
        
        
        
        HStack {
            Button {
                detectedRoom = "One"
                roomName = "One"
            } label: {
                
                Text("1")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .foregroundColor(.red)
                            .frame(width: .infinity)
                        //.padding([.leading, .trailing])
                    )
            }
            .padding([.bottom])
            Button {
                detectedRoom = "Two"
                roomName = "Two"
                
            } label: {
                
                Text("2")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .foregroundColor(.red)
                            .frame(width: .infinity)
                        //.padding([.leading, .trailing])
                    )
            }
            .padding([.bottom])
            
        }.padding()
        
    }
    
    func createBeginMotion() -> some View {
        Button {
            // action stub 
            // room detection task
            beginMotion.toggle()
        } label: {
            
            Text("Begin Motion Intent")
                .font(.title)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .foregroundColor(.black)
                        .frame(width: .infinity)
                        .padding([.leading, .trailing])
                )
        }
        .padding([.bottom])
        
    }
}

struct MotionNavView: View {
    
    @State var loadedGraph: String = ""
    var floorgraph: FloorGraph
    @State var locationHandler: Location?
    @State var stateManager: MotionStateManager?
    @ObservedObject var headphoneManager = HeadphoneManager()
    
    @State var speech = SpeechRecognizer()
    @State var recordedTouchDown = false
    
    @State var assistantResponse = ""
    
    // based on permanent states
    @State var priorState = ""
    @State var newState = ""
    
    
    var body: some View {
        VStack {
            
            ScrollView {
                VStack {
                    Text("Assistant Response")
                        .font(.headline)
                        .padding()
                    Text(assistantResponse)
                        .padding()
                        
                }
                .background(RoundedRectangle(cornerRadius: 14).foregroundStyle(.black))
                .padding()
            }
            
                Button {
                    if self.recordedTouchDown {
                        //print("stopping recording")
                        self.recordedTouchDown.toggle() // finish transcription
                        self.speech.stopTranscribing()
                        // Send to llm
                        self.stateManager!.sendAdvancedRequest(self.speech.transcript)
                    }
                } label: {
                    Image(systemName: "microphone.fill")
                        .foregroundStyle(.white)
                        .font(.title)
                        .padding()
                        .background(Circle().foregroundStyle(.red))
                }
                .padding()
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.2).onEnded { _ in 
                    self.recordedTouchDown = true
                    //print("recording") // kick off recording and transcription
                    self.speech.resetTranscript()
                    self.speech.startTranscribing()
                })
                
        }
        .navigationTitle("Quad: \(loadedGraph)")
        .onAppear() {
            Task {
                self.stateManager = MotionStateManager(withDeviceMotionManager: locationHandler!, andHeadphoneManager: headphoneManager, usingGraph: floorgraph, insideRoom: loadedGraph, self.$assistantResponse)
            }
            
        }
        .onDisappear() {
            self.stateManager!.stopActivities()
            self.stateManager = nil
        }
    }
}
