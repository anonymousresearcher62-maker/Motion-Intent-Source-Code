import SwiftUI

struct UIImageW: Identifiable {
    var id = UUID()
    var im: UIImage
}

class ImageCarousel: ObservableObject {
    @Published var ims = [UIImageW]()
    var directions = [String]()
}




class NodeWrapper: Identifiable {
    var node: WallNode
    var id = UUID()
    var im: UIImage
    
    init(_ node: WallNode, _ im: UIImage) {
        self.node = node
        self.im = im
    }
}




class ListCellWrapper: ObservableObject {
    @Published var nodes = [NodeWrapper]()
}

class FloorPlanGraphWrapper: ObservableObject {
    @Published var floorGraphs = [RoomGraph]()
    @Published var floorPlan = FloorGraph()
}


struct NodeView: View {
    
    var node: NodeWrapper
    
    var body: some View {
        VStack {
            Image(uiImage: node.im)
                .resizable()
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                
            
            Form {
                Section {
                    Text("Direction: \(node.node.direction)")
                    
                }
                Section {
                    VStack {
                        Text("Scene Description")
                            .font(.title2)
                        Divider()
                        Text(node.node.description)
                            .multilineTextAlignment(.leading)
                            .padding()
                    }
                }
            }
        }
    }
}


struct GraphCreationView: View {
    
    @State var isGraphSaved = false
    @State var roomName = "Untitled Room"
    @EnvironmentObject var images: ListCellWrapper
    @EnvironmentObject var ims: ImageCarousel
    @EnvironmentObject var floorGraphs: FloorPlanGraphWrapper
    
    @State var sceneTag = "None"
    
    var body: some View {
        
        
        Form {
            
            Section {
                List($images.nodes) { $node in
                    
                    
                    
                    NavigationLink(destination: NodeView(node: node)) {
                        
                        HStack {
                            Image(uiImage: node.im)
                                .resizable()
                                .frame(width: 65, height: 65)
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            VStack {
                                HStack {
                                    Text("Node ID: \(node.node.wallId)")
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                }
                                HStack {
                                    VStack {
                                        HStack {
                                            Text("Scene Description")
                                                .fontWeight(.bold)
                                            Spacer()
                                        }
                                        ZStack {
                                            HStack {
                                                ProgressView()
                                                Text("Thinking")
                                                Spacer()
                                            }
                                            .opacity((node.node.description == "") ? 1.0 : 0.0)
                                            HStack {
                                                Text(node.node.description)
                                                    .lineLimit(2)
                                                Spacer()
                                            }
                                        }
                                        
                                    }
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                        
                    }
                    
                    
                }
            } header : {
                Text("Nodes")
            }
            
            Section {
                TextField("Scene Tags", text: $sceneTag) {
                    
                }
            } header: {
                Text("Object Tags")
            }
            
            
            
        }
        .navigationTitle($roomName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                if !isGraphSaved {
                    Button("Save Graph") {
                        var roomgraph = RoomGraph()
                        for rNode in images.nodes {
                            rNode.node.im = rNode.im
                            roomgraph.addNode(rNode.node)
                        }
                        for i in 0..<4 {
                            roomgraph.addRelationship(wall: i, nextTo: (i+1)%4)
                            roomgraph.directonMap[roomgraph.nodeStorage[i]!.direction] = i
                        }
                        roomgraph.roomName = roomName
                        roomgraph.objectTags = self.sceneTag
                        floorGraphs.floorGraphs.append(roomgraph)
                        isGraphSaved = true
                        
                        floorGraphs.floorPlan.addNode(withRoomName: roomName, andNode: roomgraph)
                        
                    }
                } else {
                    Text("Saved!")
                }
                
            }
        }
    }
    
    
}

struct EnrollmentView: View {
    let llm = LLMAPIMode()
    @State var showBegin = true
    var primaryView = ARViewContainer()
    @ObservedObject var deviceMotionManager = DeviceMotion()
    @StateObject var imageCarousel = ImageCarousel()
    @StateObject var nodeWrapCarrier = ListCellWrapper()
    
    @State var currentCount = 5
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State var moveToGraph = false
    @State var taskExecuted = false
    
    var body: some View {
        if !moveToGraph {
            ZStack {
                primaryView
                    .ignoresSafeArea(.all)
                if self.deviceMotionManager.enrollmentStateComplete {
                    enrollmentCompletion()
                    
                }
                VStack {
                    Spacer()
                    createBeginEnrollment()
                    createImageCarousel()
                }
                
            }
            .navigationBarBackButtonHidden(!showBegin)
            .environmentObject(imageCarousel)
            .environmentObject(nodeWrapCarrier)
            .onAppear() {
                taskExecuted = false
            }
            
        } else {
            GraphCreationView()
                .environmentObject(imageCarousel)
                .environmentObject(nodeWrapCarrier)
                .onAppear {
                    if !taskExecuted {
                        for id in 0..<imageCarousel.ims.count  {
                            let nodeDirection = imageCarousel.directions[id]
                            
                            let newNode = WallNode(id: id, direction: nodeDirection)
                            
                            let nodeWrap = NodeWrapper(newNode, imageCarousel.ims[id].im)
                            self.nodeWrapCarrier.nodes.append(nodeWrap)
                            
                        }
                        
                        
                        Task {
                            for im in 0..<self.imageCarousel.ims.count {
                                let object = self.nodeWrapCarrier.nodes[im]
                                let imToSend = self.nodeWrapCarrier.nodes[im].im.resize(to: CGSize(width: 128, height: 128))
                                object.node.description = await llm.makeAsyncRequest(forImage: imToSend, withPrompt: "What's in this image? Please be detailed.")
                                self.nodeWrapCarrier.nodes[im] = object
                                
                            }
                        }
                    }
                    taskExecuted = true
                }
        }
        // a bug here where the enrollment procedure continues despite the view's 
        // disappearance
    }
    
    
    func enrollmentCompletion() -> some View {
        VStack {
            Text("Enrollment Completed")
                .font(.title)
                .padding()
            // 10-second return timer back to home. Destroy all things owned by this view.
            //
            
            HStack {
                Text("Moving to Graph Creation in \(currentCount) Second(s).")
                    .frame(width: 250)
                    .font(.title2)
                    .onReceive(timer) { input in
                        currentCount -= 1
                        if currentCount == 0 {
                            // go to graph creation
                            moveToGraph.toggle()
                        }
                    }
            }
        }
        
    }
    
    func createImageCarousel() -> some View {
        VStack {
            Text("Image Preview")
                .font(.title3)
            
            ScrollView(.horizontal) {
                HStack {
                    
                    ForEach(imageCarousel.ims) { im in
                        
                        Image(uiImage: im.im)
                            .resizable()
                            .frame(width: 150, height: 150)
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 25.0))
                        
                        
                    }
                    
                }
                .padding()
                .scaledToFit()
                .scaleEffect(0.8)
            }
        }
        .opacity((imageCarousel.ims.isEmpty) ? 0.0 : 1.0)
        
    }
    
    func createBeginEnrollment() -> some View {
        Button {
            // action stub 
            withAnimation {
                showBegin.toggle()
            }
            self.deviceMotionManager.beginStream()
        } label: {
            
            Text("Begin")
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
        .padding()
        .opacity((showBegin) ? 1.0 : 0.0)
    }
}








struct ContentView: View {
    
    @ObservedObject var fpGraph = FloorPlanGraphWrapper()
    @State var showEnroll = false
    @State var showFP = false
    @State var showNav = false
    
    var body: some View {
        
        if showEnroll {
            NavigationStack {
                EnrollmentView()
                    .environmentObject(fpGraph)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Home") {
                                showEnroll = false
                            }
                        }
                    }
            }
        } else {
            
            NavigationStack {
                ZStack {
                    Rectangle()
                        .ignoresSafeArea()
                    VStack {
                        Button {
                            // action stub 
                            showEnroll.toggle()
                        } label: {
                            
                            Text("Add Room Graph")
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
                        
                        
                        
                        Button {
                            // action stub 
                            showFP.toggle()
                        } label: {
                            
                            Text("Room Link Graph")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/)
                                        .foregroundColor(.blue)
                                        .frame(width: .infinity)
                                        .padding([.leading, .trailing])
                                )
                        }
                        
                        
                        
                        
                        Button {
                            // action stub 
                            showNav.toggle()
                        } label: {
                            
                            Text("Navigate")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/)
                                        .foregroundColor(.black)
                                        .frame(width: .infinity)
                                        .padding([.leading, .trailing])
                                )
                        }
                        
                    }
                }
                /*.navigationDestination(isPresented: $showEnroll) {
                    EnrollmentView()
                        .environmentObject(fpGraph)
                }*/
                .navigationDestination(isPresented: $showFP) {
                    FloorPlanView()
                        .environmentObject(fpGraph)
                }
                .navigationDestination(isPresented: $showNav) {
                    NavigateView()
                        .environmentObject(fpGraph)
                }
                .toolbar {
                    ToolbarItem {
                        Button("Download Models") {
                            Task {
                                await TinyViTWrapper.downloadModel(fromURL: "http://192.168.1.75:8000/TinyVit.mlmodelc.zip")
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    
}
