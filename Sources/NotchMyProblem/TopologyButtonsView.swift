//
//  TopologyButtonsView.swift
//  NotchMyProblem
//
//  Created by Aether on 03/03/2025.
//

import SwiftUI

/// A view that positions buttons around the physical topology of the device's top area,
/// adapting to notches, Dynamic Islands, and other screen cutouts automatically.
@available(iOS 13.0, *)
public struct TopologyButtonsView<LeadingButton: View, TrailingButton: View>: View {
    // The button that appears on the left/leading side
    let leadingButton: LeadingButton
    
    // The button that appears on the right/trailing side
    let trailingButton: TrailingButton
    
    // Environment access to any custom overrides
    @Environment(\.notchOverrides) private var environmentOverrides
    
    /// Creates a new TopologyButtonsView with custom leading and trailing buttons
    /// - Parameters:
    ///   - leadingButton: The button to display on the left side
    ///   - trailingButton: The button to display on the right side
    public init(
        @ViewBuilder leadingButton: () -> LeadingButton,
        @ViewBuilder trailingButton: () -> TrailingButton
    ) {
        self.leadingButton = leadingButton()
        self.trailingButton = trailingButton()
    }
    
    public var body: some View {
        GeometryReader { geometry in
            // Detect device topology based on safe area height
            let statusBarHeight = geometry.safeAreaInsets.top
            let hasTopCutout = statusBarHeight > 40
            
            HStack(spacing: 0) {
                // Leading button with appropriate alignment
                leadingButton
                    .frame(maxWidth: .infinity, alignment: hasTopCutout ? .center : .leading)
                    
                    .padding(7)
                
                // Space for the device's top cutout if present
                if hasTopCutout, let exclusionWidth = getAdjustedExclusionRect()?.width, exclusionWidth > 0 {
                    Color.clear
                        .frame(width: exclusionWidth)
                }
                
                // Trailing button with appropriate alignment
                trailingButton
                    .frame(maxWidth: .infinity, alignment: hasTopCutout ? .center : .trailing)
                    .padding(7)
            }
            // Adjust height based on device topology
            .frame(height: hasTopCutout ? statusBarHeight + 4 : 40)
            .padding(.top, hasTopCutout ? 0 : 5)
            .edgesIgnoringSafeArea(.all)
            .padding(.horizontal, 15)
        }
    }
    
    /// Gets the adjusted exclusion rect, applying any environment overrides
    private func getAdjustedExclusionRect() -> CGRect? {
        if let overrides = environmentOverrides {
            // Use environment-specific overrides if available
            let rect = NotchMyProblem.shared.adjustedExclusionRect(using: overrides)
            return rect
        } else {
            // Otherwise use the instance's configured overrides
            let rect = NotchMyProblem.shared.adjustedExclusionRect
            return rect
        }
    }
}

#Preview {
        // Default TopologyButtonsView
        TopologyButtonsView(
            leadingButton: {
                Button(action: {
                    print("Default: Back tapped")
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                }
            },
            trailingButton: {
                Button(action: {
                    print("Default: Save tapped")
                }) {
                    Text("Save")
                        .font(.headline)
                }
            }
        )
        .previewDisplayName("Default")
    
}

#Preview {
    

    // TopologyButtonsView with view-specific override
    TopologyButtonsView(
        leadingButton: {
            Button(action: {
                print("Override: Back tapped")
            }) {
                Image(systemName: "arrow.left")
                    .font(.headline)
            }
        },
        trailingButton: {
            Button(action: {
                print("Override: Save tapped")
            }) {
                Text("Save")
                    .font(.headline)
            }
        }
    )
    .notchOverride(.series(prefix: "iPhone14", scale: 0.6, heightFactor: 0.6))
    .previewDisplayName("With View Override")
}

#Preview{
    // Another variant with different styling
    TopologyButtonsView(
        leadingButton: {
            Button(action: {
                print("Styled: Cancel tapped")
            }) {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        },
        trailingButton: {
            Button(action: {
                print("Styled: Confirm tapped")
            }) {
                Text("Confirm")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
    )
    .previewDisplayName("Custom Styled")
}
