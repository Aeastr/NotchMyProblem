//
//  ContentView.swift
//  NotchMyProblemDemo
//
//  Created by Aether on 03/03/2025.
//

import SwiftUI
import NotchMyProblem
import SwiftUI
import NotchMyProblem

struct ContentView: View {
    @Environment(\.dismiss) var dismiss
    @State private var scale: Double = 0.8
    @State private var heightFactor: Double = 0.7
    @State private var radius: Double = 24.0
    @State private var isOverrideApplied = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.orange, Color.red],
                          startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                Text("Demo")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                
                Spacer().frame(height: 40)
                
                // Controls
                VStack(spacing: 20) {
                    HStack {
                        Text("Scale:")
                        Slider(value: $scale, in: 0.5...1.5)
                        Text(String(format: "%.2f", scale))
                            .frame(width: 40)
                    }
                    
                    HStack {
                        Text("Height:")
                        Slider(value: $heightFactor, in: 0.5...1.5)
                        Text(String(format: "%.2f", heightFactor))
                            .frame(width: 40)
                    }
                    
                    HStack {
                        Text("Radius:")
                        Slider(value: $radius, in: 10...40)
                        Text(String(format: "%.1f", radius))
                            .frame(width: 40)
                    }
                    
                    Button(isOverrideApplied ? "Remove Override" : "Apply Override") {
                        if isOverrideApplied {
                            NotchMyProblem.shared.overrides = []
                            isOverrideApplied = false
                        } else {
                            
                            isOverrideApplied = true
                        }
                    }
                    .buttonStyle(DemoButtonStyle())
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                dimensions
            }
            .padding()
            
            // Buttons positioned around the notch/island
            TopologyButtonsView(
                leadingButton: {
                    Button(action: { }) {
                        Image(systemName: "arrow.left")
                            .modifier(ButtonStyleModifier())
                    }
                },
                trailingButton: {
                    Button(action: { }) {
                        Text("Done")
                            .modifier(ButtonStyleModifier())
                    }
                }
            )
            .notchOverrides(isOverrideApplied ? [
                DeviceOverride(modelIdentifier: (UIDevice.modelIdentifier),
                             scale: scale,
                             heightFactor: heightFactor,
                             radius: radius)
            ] : nil)
        }
    }
    
    var dimensions: some View{
        VStack {
            Text("Raw Dimensions")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            Text("Manual access to notch/island data")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer().frame(height: 60)
            
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    if let rawRect = NotchMyProblem.exclusionRect {
                        Text("Raw Exclusion Rect:")
                            .font(.headline)
                        Text("Width: \(String(format: "%.2f", rawRect.width))")
                        Text("Height: \(String(format: "%.2f", rawRect.height))")
                        Text("X: \(String(format: "%.2f", rawRect.origin.x))")
                        Text("Y: \(String(format: "%.2f", rawRect.origin.y))")
                    } else {
                        Text("No exclusion rect available")
                            .font(.headline)
                    }
                }
                
                Divider()
                
                Group {
                    if let adjustedRect = NotchMyProblem.shared.adjustedExclusionRect {
                        Text("Adjusted Exclusion Rect:")
                            .font(.headline)
                        Text("Width: \(String(format: "%.2f", adjustedRect.width))")
                        Text("Height: \(String(format: "%.2f", adjustedRect.height))")
                        Text("X: \(String(format: "%.2f", adjustedRect.origin.x))")
                        Text("Y: \(String(format: "%.2f", adjustedRect.origin.y))")
                    } else {
                        Text("No adjusted rect available")
                            .font(.headline)
                    }
                }
                
                Divider()
                
                Text("Device Info:")
                    .font(.headline)
                Text("Model: \(UIDevice.current.model)")
                Text("Identifier: \(UIDevice.modelIdentifier)")
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            
            Spacer()
        }
    }
}

// Helper styles
struct ButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .labelStyle(.iconOnly)
            .frame(width: 65, height: 30)
            .font(.footnote.weight(.semibold))
            .background(.thinMaterial)
            .foregroundStyle(Color.primary)
            .clipShape(Capsule())
    }
}

struct DemoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

extension UIDevice {
    
    /// The device's model identifier (e.g., "iPhone14,4")
    @MainActor
    static let modelIdentifier: String = {
        // Handle simulator case
        if let simulatorModelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModelIdentifier
        }
        
        // Get actual device identifier
        var sysinfo = utsname()
        uname(&sysinfo)
        let machineData = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))
        let identifier = String(bytes: machineData, encoding: .ascii)?
            .trimmingCharacters(in: .controlCharacters) ?? "unknown"
        
        return identifier
    }()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro Max"))
                .previewDisplayName("iPhone 16 Pro Max (Dynamic Island)")
            
            ContentView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro"))
                .previewDisplayName("iPhone 13 Pro Max (Notch)")
            
            ContentView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
                .previewDisplayName("iPhone 12 Pro (Larger Notch)")

            ContentView()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
                .previewDisplayName("iPhone SE (No Notch)")
        }
    }
}
