import SwiftUI

struct FloorPlanView: View {
    
    @EnvironmentObject var wrappedFloorPlan: FloorPlanGraphWrapper
    
    var body: some View {
        List(wrappedFloorPlan.floorGraphs, id: \.roomName) { graph in
            NavigationLink {
                LinkerView(roomName: graph.roomName, roomsAuxilliary: wrappedFloorPlan.floorGraphs.filter({$0.roomName != graph.roomName}), wrappedFloorPlan: wrappedFloorPlan)
            } label: {
                Text(graph.roomName)
                    .font(.title3)
                    .padding()
            }
        }
        .navigationTitle("Link Rooms")
        
    }
}



struct LinkerView: View {
    
    typealias RoomName = String
    typealias Direction  = String
    
    @State var roomName: String = ""
    @State var roomsAuxilliary = [RoomGraph]()
    @State var wrappedFloorPlan: FloorPlanGraphWrapper
    
    
    @State var connections = [(RoomName, Direction, RoomName, Direction)]()
    
    @State var roomDirs = [(UUID, RoomName, Direction)]()
    
    // it would be better to have one stack for both to make it less
    // of a cognitive overload to make sure everything is in order.
    @State var thisRoomStack = [(RoomName, Direction)]()
    @State var adjacentRoomStack = [(RoomName, Direction)]()
    
    @State var thisRoomsDirections = [Direction]()
    
    var body: some View {
        Form {
            
            Section {
                List(thisRoomsDirections, id: \.self) { dir in
                    HStack {
                        Image(uiImage: wrappedFloorPlan.floorPlan.nodeStorage[roomName]!.nodeStorage[wrappedFloorPlan.floorPlan.nodeStorage[roomName]!.directonMap[dir]!]!.im!)
                            .resizable()
                            .frame(width: 65, height: 65)
                            .clipShape(RoundedRectangle(cornerRadius: 10.0))
                            
                        Button("\(dir)") {
                            thisRoomStack.append((roomName, dir))
                        }
                        //.disabled(thisRoomStack.contains(where: {$0.1 == dir}))
                    }
                }
                
            } header: {
                Text("Connectable Directions")
            }
            
            ForEach(roomsAuxilliary, id: \.roomName) { room in
                Section {
                    
                    List(roomDirs.filter{$0.1 == room.roomName}, id: \.0) { (roomA) in
                        HStack {
                            Image(uiImage: wrappedFloorPlan.floorPlan.nodeStorage[roomA.1]!.nodeStorage[wrappedFloorPlan.floorPlan.nodeStorage[roomA.1]!.directonMap[roomA.2]!]!.im!)
                                .resizable()
                                .frame(width: 65, height: 65)
                                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                                
                            Button("\(roomA.2)") {
                                adjacentRoomStack.append((roomA.1, roomA.2))
                                print(adjacentRoomStack)
                            }
                            .disabled(adjacentRoomStack.contains(where: {($0.0 == roomA.1) && ($0.1 == roomA.2)}))
                        }
                    }
                } header: {
                    Text("\(room.roomName) Linkable Directions")
                }
                
            }
        }
        .navigationTitle(roomName)
        .toolbar {
            ToolbarItemGroup {
                Button("Clear") {
                    connections = [(RoomName, Direction, RoomName, Direction)]()
                    adjacentRoomStack = [(RoomName, Direction)]() 
                    thisRoomStack = [(RoomName, Direction)]()
                }
               
                
                Button("Save") {
                    
                    // save new adjacencies into floorplan graph
                    let len = thisRoomStack.count
                    for item in 0..<len {
                        let src = thisRoomStack[item]
                        let dst = adjacentRoomStack[item]
                        self.wrappedFloorPlan.floorPlan.addRelationship(forRoom: src.0, atDirection: src.1, toRoom: dst.0, withTargetDirection: dst.1)
                    }
                    
                    print(self.wrappedFloorPlan.floorPlan.adjacency)
                }
                
            }
            
            
                
            
        }
        .onAppear {
            
            for node in wrappedFloorPlan.floorPlan.nodeStorage[roomName]!.nodeStorage {
                thisRoomsDirections.append(node.value.direction)
            }
            
            
            for graph in roomsAuxilliary {
                for node in graph.nodeStorage {
                    roomDirs.append((UUID(), graph.roomName, node.value.direction))
                }
            }
            
            
        }
        
    }
    
}
