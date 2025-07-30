//
//  CutoutAccessoryView.swift
//  NotchMyProblem
//
//  Created by Aether on 03/03/2025.
//

import SwiftUI

/// A view that positions content around the physical topology of the device's top area,
/// adapting to notches, Dynamic Islands, and other screen cutouts automatically.
///
/// You can provide any views for the leading and trailing sides.
///   - leadingContent: The view to display on the left side
///   - trailingContent: The view to display on the right side
@available(iOS 13.0, *)
public struct CutoutAccessoryView<LeadingContent: View, TrailingContent: View>: View {
    // Environment access to any custom overrides
    @Environment(\.notchOverrides) private var environmentOverrides

    // The view that appears on the left/leading side
    let leadingContent: LeadingContent

    // The view that appears on the right/trailing side
    let trailingContent: TrailingContent

    // Access class
    let notchMyProblem = NotchMyProblem.self

    /// Creates a new CutoutAccessoryView with custom leading and trailing content.
    /// - Parameters:
    ///   - leadingContent: The view to display on the left side.
    ///   - trailingContent: The view to display on the right side.
    public init(
        @ViewBuilder leadingContent: () -> LeadingContent,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.leadingContent = leadingContent()
        self.trailingContent = trailingContent()
    }
    
    public var body: some View {
        GeometryReader { geometry in
            // Detect device topology based on safe area height
            let statusBarHeight = geometry.safeAreaInsets.top
            let hasTopCutout = statusBarHeight > 40
            
            HStack(spacing: 0) {
                leadingContent
                    .frame(maxWidth: .infinity, alignment: hasTopCutout ? .center : .leading)
                
                // Space for the device's top cutout if present
                if hasTopCutout, let exclusionWidth = getAdjustedExclusionRect()?.width, exclusionWidth > 0 {
                    Color.clear
                        .frame(width: exclusionWidth)
                }
                
                trailingContent
                    .frame(maxWidth: .infinity, alignment: hasTopCutout ? .center : .trailing)
//                    .padding(7)
            }
            // Adjust height based on device topology
            .frame(height: hasTopCutout ? notchMyProblem.exclusionRect?.height ?? statusBarHeight : 40)
            .padding(.top, notchMyProblem.exclusionRect?.minY ?? (hasTopCutout ? 0 : 5))
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    /// Gets the adjusted exclusion rect, applying any environment overrides
    private func getAdjustedExclusionRect() -> CGRect? {
        if let overrides = environmentOverrides {
            // Use environment-specific overrides if available
            let rect = notchMyProblem.shared.adjustedExclusionRect(using: overrides)
            return rect
        } else {
            // Otherwise use the instance's configured overrides
            let rect = notchMyProblem.shared.adjustedExclusionRect
            return rect
        }
    }
}

#Preview {
        // Default CutoutAccessoryView
        CutoutAccessoryView(
            leadingContent: {
                Color.red
            },
            trailingContent: {
                Color.red
            }
        )
        .previewDisplayName("Default")
    
}

#Preview {
    

    // CutoutAccessoryView with view-specific override
    CutoutAccessoryView(
        leadingContent: {
            Button(action: {
                print("Override: Back tapped")
            }) {
                Image(systemName: "arrow.left")
                    .font(.headline)
            }
        },
        trailingContent: {
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
    CutoutAccessoryView(
        leadingContent: {
            Button(action: {
                print("Styled: Cancel tapped")
            }) {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        },
        trailingContent: {
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
