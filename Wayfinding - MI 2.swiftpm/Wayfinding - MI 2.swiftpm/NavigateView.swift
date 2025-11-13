import SwiftUI

struct NavigateView: View {
    
    @EnvironmentObject var wrappedFloorPlan: FloorPlanGraphWrapper
    @State var beginMotion = false
    @State var isRoomDetected = false
    
    @ObservedObject var tinyVit = TinyViTWrapper()
    
    @State var isConfiguring = true
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
                        Text(detectedRoom)
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
                        createOverride()
                        createDetectRoom()
                            .disabled((self.tinyVit.model == nil) ? true : false)
                            .opacity((self.tinyVit.model == nil) ? 0.3 : 1.0)
                        if isRoomDetected {
                            createBeginMotion()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await self.tinyVit.loadModel()
            }
        }
        
    }
    
    func createOverride() -> some View {
        Button {
            isConfiguring.toggle()
        } label: {
            
            Text("Override Room")
                .font(.title)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .foregroundColor(.purple)
                        .frame(width: .infinity)
                        .padding([.leading, .trailing])
                )
        }
        .padding([.bottom])
        .alert("Override Room Detection", isPresented: $isConfiguring) {
            TextField("Room Name", text: $roomName)
                
            
            
            
            Button {
                isConfiguring = false
                isRoomDetected = (roomName != "") ? true : false
                detectedRoom = "Detected Room: \(roomName)"
            } label: {
                Text("Done")
            }
            
            
        } message: {
            Text("Override ViT detected room.")
        }
    }
    
    func createDetectRoom() -> some View {
        Button {
            // action stub 
            // room detection task
            //NotificationCenter.default.post(name: Notification.Name("navFrame"), object: true)
            Task {
                
                
                let curim = primaryView.delegate.getIm()
                let curDirection = primaryView.delegate.locationHandler.currentDirection
                
                let roomid = await tinyVit.identifyRoom(withFrame: curim!, forDirection: curDirection, usingGraph: wrappedFloorPlan.floorPlan)
                roomName = roomid
                withAnimation {
                    detectedRoom = "Guessed Room: \(roomid)"
                    isRoomDetected = true
                }
                
                
            }
            
            
        } label: {
            
            Text("Detect Room")
                .font(.title)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .foregroundColor(.red)
                        .frame(width: .infinity)
                        .padding([.leading, .trailing])
                )
        }
        .padding([.bottom])
        
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
    @StateObject var headphoneManager = HeadphoneManager()
    
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
            .opacity((assistantResponse != "") ? 1.0 : 0.0)
                Button {
                    if self.recordedTouchDown {
                        print("stopping recording")
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
                    print("recording") // kick off recording and transcription
                    self.speech.resetTranscript()
                    self.speech.startTranscribing()
                })
                
        }
        .navigationTitle("Graph: \(loadedGraph)")
        .onAppear() {
            Task {
                self.stateManager = MotionStateManager(withDeviceMotionManager: locationHandler!, andHeadphoneManager: headphoneManager, usingGraph: floorgraph, insideRoom: loadedGraph, self.$assistantResponse)
            }
            
        }
        .onDisappear() {
            self.stateManager!.stopActivities()
            self.stateManager = nil
            
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Refresh") {
                    self.headphoneManager.restartActivity()
                }
            }
        }
    }
}
