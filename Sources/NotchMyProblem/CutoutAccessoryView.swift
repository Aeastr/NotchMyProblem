//
//  CutoutAccessoryView.swift
//  NotchMyProblem
//
//  Created by Aether on 03/03/2025.
//

import SwiftUI

/// Padding configuration for `CutoutAccessoryView`.
///
/// - `.auto`: Uses default heuristics for cutout, content, and vertical padding.
///     - The cutout area gets `cutoutWidth / 8` horizontal padding.
///     - The overall content gets `cutoutWidth / 4` horizontal padding.
///     - The vertical padding is `cutoutHeight * 0.05`.
///
/// - `.none`: No extra padding is applied to the cutout, content, or vertically.
///
/// - `.custom`: Supply closures to calculate the horizontal padding for the cutout area,
///   the overall content, and the vertical padding. Each closure receives the relevant
///   cutout dimension (in points) and should return the desired padding (in points).
///
///     Example:
///     ```swift
///     CutoutAccessoryView(
///         padding: .custom(
///             cutout: { cutoutWidth in cutoutWidth / 10 },   // Horizontal padding for the cutout area
///             content: { cutoutWidth in cutoutWidth / 2 },   // Horizontal padding for the overall content
///             vertical: { cutoutHeight in cutoutHeight * 0.1 } // Vertical padding (default is 5% of cutout height)
///         ),
///         leadingContent: { ... },
///         trailingContent: { ... }
///     )
///     ```
///
///     - `cutout`: Closure to determine the horizontal padding for the cutout's surroundings (the space reserved for the notch/island).
///     - `content`: Closure to determine the horizontal padding for the overall content (the HStack containing your views).
///     - `vertical`: Closure to determine the vertical padding for the content (default is `{ $0 * 0.05 }`).
public enum CutoutAccessoryPadding {
    case auto
    case none
    case custom(
        cutout: (CGFloat) -> CGFloat,
        content: (CGFloat) -> CGFloat,
        vertical: (CGFloat) -> CGFloat = { $0 * 0.05 }
    )
}




/// A view that positions content around the physical topology of the device's top area,
/// adapting to notches, Dynamic Islands, and other screen cutouts automatically.
///
/// You can provide any views for the leading and trailing sides.
///
/// - Parameters:
///   - padding: The padding configuration for the cutout and content area. Default is `.auto`.
///   - leadingContent: The view to display on the left side.
///   - trailingContent: The view to display on the right side.
@available(iOS 13.0, *)
public struct CutoutAccessoryView<LeadingContent: View, TrailingContent: View>: View {
    // Environment access to any custom overrides
    @Environment(\.notchOverrides) private var environmentOverrides
    
    // The view that appears on the left/leading side
    let leadingContent: LeadingContent
    
    // The view that appears on the right/trailing side
    let trailingContent: TrailingContent
    
    // Padding configuration
    let padding: CutoutAccessoryPadding
    
    // Access class for device topology
    let notchMyProblem = NotchMyProblem.self
    
    /// Creates a new CutoutAccessoryView with custom leading and trailing content.
    /// - Parameters:
    ///   - padding: The padding configuration for the cutout and content area. Default is `.auto`.
    ///   - leadingContent: The view to display on the left side.
    ///   - trailingContent: The view to display on the right side.
    public init(
        padding: CutoutAccessoryPadding = .auto,
        @ViewBuilder leadingContent: () -> LeadingContent,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.padding = padding
        self.leadingContent = leadingContent()
        self.trailingContent = trailingContent()
    }
    
    public var body: some View {
        GeometryReader { geometry in
            // MARK: - Device Detection
            let statusBarHeight = geometry.safeAreaInsets.top
            let hasTopCutout = statusBarHeight > 40
            
            // MARK: - Cutout Dimensions
            let exclusionWidth = getAdjustedExclusionRect()?.width ?? (geometry.size.width - 180) // Fallback for non-cutout devices (iPad, iPhone SE)
            let exclusionHeight = notchMyProblem.exclusionRect?.height ?? 0
            
            // MARK: - Padding Calculations
            let (cutoutPadding, contentPadding, verticalPadding): (CGFloat, CGFloat, CGFloat) = {
                switch padding {
                case .auto:
                    let cutoutPadding = max(5, min(20, 45 - (exclusionWidth * 0.18)))
                    let contentPadding = max(2, min(40, 85 - (exclusionWidth * 0.35)))
                    let verticalPadding = exclusionHeight * 0.1
                    return (cutoutPadding, contentPadding, verticalPadding)
                case .none:
                    return (0, 0, 0)
                case .custom(let cutout, let content, let vertical):
                    return (cutout(exclusionWidth), content(exclusionWidth), vertical(exclusionHeight))
                }
            }()
            
            // MARK: - Top Positioning
            let topPadding: CGFloat = {
                let minY = notchMyProblem.exclusionRect?.minY ?? (hasTopCutout ? 0 : 5)
                
                if minY == 0 {
                    // Notched device - cutout touches bezel, need spacing
                    return hasTopCutout ? (exclusionHeight / 3) : 5
                } else {
                    // Island device - cutout floats, align to its Y position
                    return minY
                }
            }()

            // MARK: - Layout
            HStack(spacing: 0) {
                // Leading content
                leadingContent
                    .frame(maxWidth: .infinity, alignment: hasTopCutout ? .center : .leading)
                
                // Space for the device's top cutout
                if exclusionWidth > 0 {
                    Color.clear
                        .frame(width: exclusionWidth)
                        .padding(.horizontal, cutoutPadding)
                }
                
                // Trailing content
                trailingContent
                    .frame(maxWidth: .infinity, alignment: hasTopCutout ? .center : .trailing)
            }
            .padding(.vertical, verticalPadding)
            .frame(height: hasTopCutout ? notchMyProblem.exclusionRect?.height ?? statusBarHeight : 30)
            .padding(.top, topPadding)
            .padding(.horizontal, hasTopCutout ? contentPadding : 5)
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    /// Gets the adjusted exclusion rect, applying any environment overrides
    private func getAdjustedExclusionRect() -> CGRect? {
        if let overrides = environmentOverrides {
            // Use environment-specific overrides if available
            return notchMyProblem.shared.adjustedExclusionRect(using: overrides)
        } else {
            // Otherwise use the instance's configured overrides
            return notchMyProblem.shared.adjustedExclusionRect
        }
    }
}

// MARK: - Previews

#Preview("Default (.auto)") {
    ZStack {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Recommended for most cases. Uses intelligent adaptive padding that gives smaller cutouts (Dynamic Island) more breathing room and larger cutouts (notches) less padding. Automatically handles positioning differences between notched and island devices.")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
            }
            .navigationBarTitle("Default (.auto) Padding", displayMode: .inline)
        }
        CutoutAccessoryView(
            padding: .auto,
            leadingContent: {
                Button{
                    
                } label: {
                    Text("Leading")
                        .notchMyProblem_Example_Button()
                }
            },
            trailingContent: {
                Button{
                    
                } label: {
                    Text("Trailing")
                        .notchMyProblem_Example_Button(highlighted: true)
                }
            }
        )
    }
}

#Preview("No Padding (.none)") {
    ZStack {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("No extra padding is applied. Content may touch the notch, device corners, or top edge. Use for full-bleed designs or when you want to manage spacing yourself.")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
            }
            .navigationBarTitle("No Padding (.none)", displayMode: .inline)
        }
        CutoutAccessoryView(
            padding: .none,
            leadingContent: {
                Button{
                    
                } label: {
                    Text("Leading")
                        .notchMyProblem_Example_Button()
                }
            },
            trailingContent: {
                Button{
                    
                } label: {
                    Text("Trailing")
                        .notchMyProblem_Example_Button(highlighted: true)
                }
            }
        )
    }
}

#Preview("Custom Padding (.custom)") {
    ZStack {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom math for cutout, content, and vertical padding.")
                        .font(.subheadline)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The cutout area receives horizontal padding equal to 1/12 of the cutout’s width.")
                        Text("The overall content receives horizontal padding equal to 1/6 of the cutout’s width.")
                        Text("Vertical padding is set to 20% of the cutout’s height.")
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal)
            }
            .navigationBarTitle("Custom (.custom)", displayMode: .inline)
        }
        CutoutAccessoryView(
            padding: .custom(
                cutout: { $0 / 12 },
                content: { $0 / 6 },
                vertical: { $0 * 0.2 }
            ),
            leadingContent: {
                Button{
                    
                } label: {
                    Text("Leading")
                        .notchMyProblem_Example_Button()
                }
            },
            trailingContent: {
                Button{
                    
                } label: {
                    Text("Trailing")
                        .notchMyProblem_Example_Button(highlighted: true)
                }
            }
        )
    }
}

#Preview("With View Override (iPhone 14)") {
    ZStack {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("On some devices, the system-reported cutout information can be inaccurate.")
                        .font(.subheadline)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This preview demonstrates using a view-specific override to ensure correct cutout handling on iPhone 14 models.")
                        Text("(Overrides are provided by default and can be customized—see documentation.)")
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal)
            }
            .navigationBarTitle("Override (iPhone 14)", displayMode: .inline)
        }
        CutoutAccessoryView(
            leadingContent: {
                Button{
                    
                } label: {
                    Text("Leading")
                        .notchMyProblem_Example_Button()
                }
            },
            trailingContent: {
                Button{
                    
                } label: {
                    Text("Trailing")
                        .notchMyProblem_Example_Button(highlighted: true)
                }
            }
        )
        .notchOverride(.series(prefix: "iPhone14", scale: 0.6, heightFactor: 0.6))
    }
}

extension View{
    // pls ignore shody code i have to make this display on iOS 13 too 💔
    // i will make better examples later (like ones seen online)
    func notchMyProblem_Example_Button(highlighted: Bool = false) -> some View{
        self
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .font(.footnote.weight(.semibold))
            .foregroundColor(highlighted ? Color.white : Color.primary)
            .background(highlighted ? Color(red: 5/255, green: 160/255, blue: 190/255) :  Color.gray.opacity(0.3))
            .clipShape(Capsule())
    }
}
