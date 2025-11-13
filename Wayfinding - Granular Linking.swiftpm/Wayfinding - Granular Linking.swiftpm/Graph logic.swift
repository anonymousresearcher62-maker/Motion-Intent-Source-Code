import SwiftUI

struct WallNode {
    var direction: String
    var wallId: Int
    var description: String
    
    
    var im: UIImage?
    init(id: Int, direction: String) {
        wallId = id
        description = ""
        self.direction = direction
    }
}

// collection of graphs on floor
class FloorGraph {
    
    
    // node storage; each "node" is a subraph.
    // we index each based on the names of the room
    typealias RoomName = String
    typealias Direction = String
    
    var nodeStorage = [RoomName:RoomGraph]()
    var roomNames = [RoomName]()
    
    struct RoomEdge {
        let source: (RoomName, Direction)
        let destination: (RoomName, Direction)
    }
    
    // adjacency list corresponds a room's name 
    // to a list of edges representing the adjoining walls
    var adjacency = [RoomName:[RoomEdge]]()

     func addNode(withRoomName roomName: String, andNode node: RoomGraph) {
        self.nodeStorage[roomName] = node
        print(self.nodeStorage)
         if !roomNames.contains(roomName) {
             roomNames.append(roomName)
         }
    }
    
     func addRelationship(forRoom roomName: RoomName, atDirection sourceDir: Direction, toRoom destRoom: RoomName, withTargetDirection destDir: Direction) {
        
        
         guard let _ = adjacency[roomName]  else {
             adjacency[roomName] = [RoomEdge]()
             
             let newEdge = RoomEdge(source: (roomName, sourceDir), destination: (destRoom, destDir))
             adjacency[roomName]!.append(newEdge)
             return
         }
         
         let newEdge = RoomEdge(source: (roomName, sourceDir), destination: (destRoom, destDir))
         adjacency[roomName]!.append(newEdge)
        
    }
    
    
    func getGraphNL() -> String {
        // stub
        var nl = ""
        print(adjacency)
        
        for roomN in roomNames {
            print("constructing node \(roomN)")
            nl += "Division \(roomN) has "
            
            if let neigh = adjacency[roomN] {
                
                
                
                nl += "\(neigh.count) neighboring divisions: "
                for n in neigh {
                    nl += "Neighbor Division \(n.destination.0). \(n.destination.0)'s \(n.destination.1) connects to \(roomN)'s \(n.source.1)."
                }
                nl += "\n"
                nl += "Division \(roomN) Internal Details: "
                nl += nodeStorage[roomN]!.getGraphNL()
                
            }
            nl += "Objects in Division \(roomN):\n"
            nl += "\(nodeStorage[roomN]!.objectTags)\n"
            nl += "\n---\n"
        }
        
        return nl
    }
    
    
}

class RoomGraph {
    
    struct Edge {
        let source: Int
        let destination: Int
        let relationship: String //similar to weight
    }
    
    typealias Neighbors = [Edge]
    
    // adjacency list where we have a few abstractions
    // Node storage retrieves the node info
    // Adjacency list stores neighbor info to the node (node id)
    // Neighbors are just a list of edges indicating source, destination, and relationship (i.e., right or left)
    var nodeStorage = [Int:WallNode]()
    var adjacencyList = [Int:Neighbors]()
    var roomName = ""
    var objectTags: String = "None"
    // map directions to node identifiers for easy use later
    var directonMap = [String:Int]()
    
    func addNode(_ node: WallNode) {
        nodeStorage[node.wallId] = node
    }
    
    func addEdge(fromSource sourceId: Int, toDest destinationId: Int, usingRealtionship rel: String) {
        // assume that every relationship is "to the right". Therefore, there will be an opposite connection to that of the last node.
        var newEdge = Edge(source: sourceId, destination: destinationId, relationship: rel)
        if let _ = adjacencyList[sourceId] {
            adjacencyList[sourceId]!.append(newEdge)
        } else {
            adjacencyList[sourceId] = Neighbors()
            adjacencyList[sourceId]!.append(newEdge)
        }
    }
    
    func addRelationship(wall sourceId: Int, nextTo destinationId: Int) {
        addEdge(fromSource: sourceId, toDest: destinationId, usingRealtionship: "right")
        addEdge(fromSource: destinationId, toDest: sourceId, usingRealtionship: "left")
    }
    
    func printGraph() {
        for num in 0..<nodeStorage.count {
            let neighbors = self.adjacencyList[num]
            print("Wall \(num) has \(neighbors!.count) neighbors: \(adjacencyList[num]![0].destination) and \(adjacencyList[num]![1].destination)")
            print(" - Wall \(adjacencyList[num]![0].destination) is to the \(adjacencyList[num]![0].relationship)")
            print(" - Wall \(adjacencyList[num]![1].destination) is to the \(adjacencyList[num]![1].relationship)")
        }
        print()
    }
    
    func getGraphNL() -> String {
        var gnl = ""
        for num in 0..<nodeStorage.count {
            let neighbors = self.adjacencyList[num]
            gnl += "Wall \(num) has \(neighbors!.count) neighboring walls: Wall \(adjacencyList[num]![0].destination) (to its \(adjacencyList[num]![0].relationship)) and Wall \(adjacencyList[num]![1].destination) (to its \(adjacencyList[num]![1].relationship))\n"
            
            gnl += "Wall \(num) faces \(nodeStorage[num]!.direction). "
            gnl += "Wall \(num)'s scene description: \(nodeStorage[num]!.description)\n"
            
            // the commented out strings are repetative details!
            let adj1 = nodeStorage[adjacencyList[num]![0].destination]!
            // gnl += "Wall \(adjacencyList[num]![0].destination) is to the \(adjacencyList[num]![0].relationship) of Wall \(num). "
            //gnl += "Wall \(num) faces \(adj1.direction). "
            //gnl += "Wall \(num)'s scene: \(adj1.description)\n"
            
            let adj2 = nodeStorage[adjacencyList[num]![1].destination]!
            //gnl += "Wall \(adjacencyList[num]![1].destination) is to the \(adjacencyList[num]![1].relationship) of Wall \(num). "
            //gnl += "Wall \(num) faces \(adj2.direction). "
           // gnl += "Wall \(num)'s scene: \(adj2.description)\n"
            
        }
        
        
        
        return gnl
    }
    
    func getNode(forDirection direction: String) -> WallNode? {
        for id in 0..<nodeStorage.count {
            if nodeStorage[id]!.direction == direction {
                return nodeStorage[id]
            }
        }
        return nil
    }
    
}

