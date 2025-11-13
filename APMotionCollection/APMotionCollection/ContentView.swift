//
//  ContentView.swift
//  APMotionCollection
//
//  Created by Anonymous on 6/24/25.
//

import SwiftUI
import CoreMotion
import Charts

struct ChartView: View {
    
    @ObservedObject var motionManager: HeadphoneManager
    @State var selectedToggle = 0
    
    
    //MARK: Begin Rotation Toggle Variables
    
    @State var rotateRateXToggle = true
    @State var rotateRateYToggle = false
    @State var rotateRateZToggle = false
    
    
    
    //MARK: Begin Attitude Toggle Variables
    
    @State var attitudeRollToggle = true
    @State var attitudePitchToggle = false
    @State var attitudeYawToggle = false
    
    
    
    //MARK: Begin Acceleration Toggle Variables
    
    @State var accelerationXToggle = true
    @State var accelerationYToggle = false
    @State var accelerationZToggle = false
    
    var body: some View {
       
        Group {
            
            VStack {
                DataChart(withDataFilter: DataFilter.init(rawValue: selectedToggle)!)
                Button("Clear") {
                    motionManager.resetBuffer()
                }
                .padding()
                
            }
            
        }
        .toolbar {
            ToolbarItem {
                Picker("Data Stream", selection: $selectedToggle) {
                    Text("Rotation Rate").tag(0)
                    Text("Attitude").tag(1)
                    Text("Acceleration").tag(2)
                }
                .pickerStyle(.segmented)
            }
        }
            /*
                // rotation rate (gyroscope) - CMRotationRate (only x and y needed)
                // attitude - CMAttitude (only yaw is necessary)
                // acceleration (total + gravity) - CMAcceleration (only x and y needed)
            */
        
    }
    
    @ViewBuilder
    func DataChart(withDataFilter df: DataFilter) -> some View {
        
        
        if df == .Rotation {
            
            VStack {
                
                HStack {
                    Toggle(isOn: $rotateRateXToggle) {
                        Text("X")
                    }
                    .padding()
                    
                    Toggle(isOn: $rotateRateYToggle) {
                        Text("Y")
                    }
                    .padding()
                    
                    Toggle(isOn: $rotateRateZToggle) {
                        Text("Z")
                    }
                    .padding()
                }
                .padding()
                
                Spacer()
                Chart(self.motionManager.samples) { entry in
                    if rotateRateXToggle {
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Rotation X", entry.motion.rotationRate.x)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Value", "X"))
                    }
                    
                    if rotateRateYToggle {
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Rotation Y", entry.motion.rotationRate.y)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Value", "Y"))
                    }
                    
                    if rotateRateZToggle {
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Rotation Z", entry.motion.rotationRate.z)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Value", "Z"))
                    }
                }
                .padding()
                
                Spacer()
                
            }
        } else if df == .Attitude {
            
            VStack {
                
                HStack {
                    Toggle(isOn: $attitudeRollToggle) {
                        Text("Roll")
                    }
                    .padding()
                    
                    Toggle(isOn: $attitudePitchToggle) {
                        Text("Pitch")
                    }
                    .padding()
                    
                    Toggle(isOn: $attitudeYawToggle) {
                        Text("Yaw")
                    }
                    .padding()
                }
                .padding()
                
                Spacer()
                
                
                Chart(self.motionManager.samples) { entry in
                    if attitudeRollToggle {
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Roll", entry.motion.attitude.roll)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Value", "Roll"))
                    }
                    
                    if attitudePitchToggle {
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Pitch", entry.motion.attitude.pitch)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Value", "pitch"))
                    }
                    
                    if attitudeYawToggle {
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Yaw", entry.motion.attitude.yaw)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Value", "yaw"))
                    }
                }
                .padding()
                
                
                Spacer()
            }
            
            
        } else {
            
            VStack {
                
                HStack {
                    Toggle(isOn: $accelerationXToggle) {
                        Text("X")
                    }
                    .padding()
                    
                    Toggle(isOn:  $accelerationYToggle) {
                        Text("Y")
                    }
                    .padding()
                    
                    Toggle(isOn:  $accelerationZToggle) {
                        Text("Z")
                    }
                    .padding()
                }
                .padding()
                
                Spacer()
                
                
                Chart(self.motionManager.samples) { entry in
                    if accelerationXToggle {
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Acceleration X", entry.motion.userAcceleration.x)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Value", "X"))
                    }
                        
                    if accelerationYToggle {
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Acceleration Y", entry.motion.userAcceleration.y)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Value", "Y"))
                    }
                        
                    if accelerationZToggle {
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Acceleration Z", entry.motion.userAcceleration.z)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Value", "Z"))
                        
                    }
                }
                .padding()
                
            Spacer()
            }
            
            
        }
        
        
    }
    
}

struct MotionInferView: View {
    
    @ObservedObject var motionManager: HeadphoneManager
    
    var body: some View {
        
        Spacer()
        Text(stateToText())
            .font(.largeTitle)
            .fontWeight(.bold)
            .fontDesign(.rounded)
        Spacer()
        
    }
    
    
    func stateToText() -> String {
        
        var state = "None"
        
        switch self.motionManager.inference {
            case .LookingForward:
                state = "Forward"
            case .LookingLeft:
                state = "Left"
            case .LookingRight:
                state = "Right"
        }
        
        return state
        
    }
}


struct ContentView: View {
    
    @StateObject var motionManager = HeadphoneManager()
    @State var showCharts = false
    @State var showCollection = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: (motionManager.isConnected) ? "headphones" : "headphones.slash")
                        .font(.system(size: 25))
                    Text((motionManager.isConnected) ? "Airpods connected!" : "Airpods NOT connected!")
                        .font(.system(size: 25))
                }
                
                Text("This application collects data and motion updates from connected AirPods for the purposes of research in \"motion intent\". There are two views available: viewing charts of motion; collection of active motion. You can adjust the parameters such as sliding window stride and length before streaming.")
                    .padding()
                
                
                Button("Charts") {
                    showCharts.toggle()
                }
                
                
                Button("Inference") {
                    showCollection.toggle()
                }
                
            }
            .padding()
            .navigationDestination(isPresented: $showCharts) {
                ChartView(motionManager: motionManager)
            }
            .navigationDestination(isPresented: $showCollection) {
                MotionInferView(motionManager: motionManager)
            }
            
        }
    }
}

#Preview {
    ContentView()
        .colorScheme(.light)
        .frame(width: 1000, height: 1000)
        
}
