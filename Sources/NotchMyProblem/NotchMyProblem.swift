//
//  Classes.swift
//  NotchMyProblem
//
//  Created by Aether on 03/03/2025.
//

import SwiftUI
import os
import UIKit

/// Extension to safely access the exclusion area (notch/Dynamic Island)
extension UIScreen {
    /// Returns the frame of the Dynamic Island or notch.
    var exclusionArea: CGRect? {
        // Early return for devices known not to have a notch/island
        // Check if the device is an iPhone and if it has a notch based on model
        let modelId = UIDevice.modelIdentifier
        let isNotchedDevice = modelId.hasPrefix("iPhone") &&
                             !["iPhone8", "iPhone9", "iPhone10,4", "iPhone10,5"].contains { modelId.hasPrefix($0) }
        
        if !isNotchedDevice {
            return nil
        }
        
        let areaExclusionSelector = {
            let selectorName = ["Area", "exclusion", "_"].reversed().joined()
            return NSSelectorFromString(selectorName)
        }()
        
        // Check if the method exists before trying to call it
        guard self.responds(to: areaExclusionSelector) else {
            return nil
        }
        
        // Safely get the exclusion area object
        let areaExclusionMethod = {
            let implementation = self.method(for: areaExclusionSelector)
            let methodType = (@convention(c) (AnyObject, Selector) -> AnyObject?).self
            return unsafeBitCast(implementation, to: methodType)
        }()
        
        let object = areaExclusionMethod(self, areaExclusionSelector)
        
        // Check if the object exists and responds to the rect selector
        let rectSelector = NSSelectorFromString("rect")
        guard let object, object.responds(to: rectSelector) else {
            return nil
        }
        
        let rectMethod = {
            let implementation = object.method(for: rectSelector)
            let methodType = (@convention(c) (AnyObject, Selector) -> CGRect).self
            return unsafeBitCast(implementation, to: methodType)
        }()
        
        let rect = rectMethod(object, rectSelector)
        
        // Validate the rect before returning it
        if rect.width <= 0 || rect.height <= 0 || rect.isInfinite || rect.isNull {
            return nil
        }
        
        return rect
    }
}


/// Logging helper that works across iOS versions
@available(iOS 13.0, *)
struct NMPLogger {
    private let subsystem = "com.notchmyproblem"
    private let category: String
    
    #if os(iOS)
    @available(iOS 14.0, *)
    private var logger: Logger {
        Logger(subsystem: subsystem, category: category)
    }
    
    private var osLog: OSLog {
        OSLog(subsystem: subsystem, category: category)
    }
    #endif
    
    init(category: String) {
        self.category = category
    }
    
    func debug(_ message: String) {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            logger.debug("\(message)")
        } else {
            os_log("%{public}@", log: osLog, type: .debug, message)
        }
        #endif
    }
    
    func info(_ message: String) {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            logger.info("\(message)")
        } else {
            os_log("%{public}@", log: osLog, type: .info, message)
        }
        #endif
    }
    
    func notice(_ message: String) {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            logger.notice("\(message)")
        } else {
            os_log("%{public}@", log: osLog, type: .default, message)
        }
        #endif
    }
    
    func error(_ message: String) {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            logger.error("\(message)")
        } else {
            os_log("%{public}@", log: osLog, type: .error, message)
        }
        #endif
    }
}

/// Configuration for a device-specific notch/island adjustment
public struct DeviceOverride: Equatable, Hashable, Sendable {
    /// The device model identifier or prefix to match
    public let modelIdentifier: String
    
    /// Scale factor to apply to the width (1.0 = original width)
    public let scale: CGFloat
    
    /// Factor to apply to the height (1.0 = original height)
    public let heightFactor: CGFloat
    
    /// Corner radius (if needed for visualization)
    public let radius: CGFloat
    
    /// Whether this is an exact match or a prefix match
    public let isExactMatch: Bool
    
    /// Creates a new device override with the specified parameters
    /// - Parameters:
    ///   - modelIdentifier: The device model to match (e.g., "iPhone14,3")
    ///   - scale: Width scale factor (default: 1.0)
    ///   - heightFactor: Height scale factor (default: 1.0)
    ///   - radius: Corner radius (default: 0)
    ///   - isExactMatch: Whether to match the exact model or use as prefix (default: true)
    public init(
        modelIdentifier: String,
        scale: CGFloat = 1.0,
        heightFactor: CGFloat = 1.0,
        radius: CGFloat = 0,
        isExactMatch: Bool = true
    ) {
        self.modelIdentifier = modelIdentifier
        self.scale = scale
        self.heightFactor = heightFactor
        self.radius = radius
        self.isExactMatch = isExactMatch
    }
    
    /// Creates a series override that matches any device whose model ID starts with the prefix
    /// - Parameters:
    ///   - seriesPrefix: The device series prefix (e.g., "iPhone14")
    ///   - scale: Width scale factor
    ///   - heightFactor: Height scale factor
    ///   - radius: Corner radius
    public static func series(
        prefix: String,
        scale: CGFloat,
        heightFactor: CGFloat,
        radius: CGFloat = 0
    ) -> DeviceOverride {
        DeviceOverride(
            modelIdentifier: prefix,
            scale: scale,
            heightFactor: heightFactor,
            radius: radius,
            isExactMatch: false
        )
    }
}

/// Manages the detection and adjustment of the iPhone's top notch/Dynamic Island area
@available(iOS 13.0, *)
@MainActor
public final class NotchMyProblem: Sendable, ObservableObject {
    
    // MARK: - Logging
    
    /// Logger for NotchMyProblem class
    private static let logger = NMPLogger(category: "NotchMyProblem")
    
    // MARK: - Singleton
    
    /// Shared instance for app-wide access
    public static let shared = NotchMyProblem()
    
    // MARK: - Properties
    
    /// Current device model identifier
    let modelId = UIDevice.modelIdentifier
    
    // MARK: - Notch Detection
    
    /// The raw notch/Dynamic Island area retrieved via private API
    /// Uses a safer approach to access private APIs
    public static let exclusionRect: CGRect? = {
        if let rect = UIScreen.main.exclusionArea {
            logger.info("Found notch for \(UIDevice.modelIdentifier): \(rect)")
            return rect
        }
        
        logger.notice("No notch found, returning .zero")
        return nil
    }()
    
    // MARK: - Device-specific Adjustments
    
    /// Global overrides that apply to all instances
    public static var globalOverrides: [DeviceOverride] = [
        .series(prefix: "iPhone13", scale: 0.95, heightFactor: 1.0, radius: 27), // iPhone 12 series
        .series(prefix: "iPhone14", scale: 0.75, heightFactor: 0.75, radius: 24)  // iPhone 13/14 series
    ]
    
    /// Instance-specific overrides that only apply to this instance
    @Published public var overrides: [DeviceOverride] = []
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // This class is isolated to the main actor since it interacts with UIKit
    }
    
    // MARK: - Public API
    
    /// Returns the notch/island area with device-specific adjustments applied
    /// Use this for proper UI positioning around the top cutout
    public var adjustedExclusionRect: CGRect? {
        adjustedExclusionRect(using: overrides)
    }
    
    /// Returns the notch/island area with the specified overrides applied
    /// - Parameter customOverrides: Custom overrides to use for this specific calculation
    /// - Returns: The adjusted exclusion rect
    public func adjustedExclusionRect(using customOverrides: [DeviceOverride]? = nil) -> CGRect? {
        let baseRect = NotchMyProblem.exclusionRect
        
        guard let baseRect else { return nil }
        
        // Determine which overrides to use (in order of precedence)
        let effectiveOverrides = customOverrides ?? overrides
        
        // Try instance overrides first (exact matches)
        for override in effectiveOverrides where override.isExactMatch && override.modelIdentifier == modelId {
            let adjusted = applyOverride(to: baseRect, with: override)
            NotchMyProblem.logger.debug("Applied instance exact override for \(self.modelId): \(adjusted)")
            return adjusted
        }
        
        // Then try instance overrides (prefix matches)
        for override in effectiveOverrides where !override.isExactMatch && modelId.hasPrefix(override.modelIdentifier) {
            let adjusted = applyOverride(to: baseRect, with: override)
            NotchMyProblem.logger.debug("Applied instance series override \(override.modelIdentifier) for \(self.modelId): \(adjusted)")
            return adjusted
        }
        
        // Then try global overrides (exact matches)
        for override in NotchMyProblem.globalOverrides where override.isExactMatch && override.modelIdentifier == modelId {
            let adjusted = applyOverride(to: baseRect, with: override)
            NotchMyProblem.logger.debug("Applied global exact override for \(self.modelId): \(adjusted)")
            return adjusted
        }
        
        // Finally try global overrides (prefix matches)
        for override in NotchMyProblem.globalOverrides where !override.isExactMatch && modelId.hasPrefix(override.modelIdentifier) {
            let adjusted = applyOverride(to: baseRect, with: override)
            NotchMyProblem.logger.debug("Applied global series override \(override.modelIdentifier) for \(self.modelId): \(adjusted)")
            return adjusted
        }
        
        // When in doubt, use what we found
        NotchMyProblem.logger.debug("No overrides applied for \(self.modelId)")
        return baseRect
    }
    
    // MARK: - Private Helpers
    
    /// Applies the specified override parameters to adjust the notch rect
    private func applyOverride(to rect: CGRect, with override: DeviceOverride) -> CGRect {
        // Scale the width
        let scaledWidth = rect.width * override.scale
        
        // Adjust the height
        let scaledHeight = rect.height * override.heightFactor
        
        // Keep it centered
        let originX = rect.origin.x + (rect.width - scaledWidth) / 2
        
        // Build the adjusted rect
        return CGRect(x: originX, y: rect.origin.y, width: scaledWidth, height: scaledHeight)
    }
}

/// Device identification utilities
extension UIDevice {
    /// Logger for UIDevice extension
    private static let logger = NMPLogger(category: "UIDeviceExtension")
    
    /// The device's model identifier (e.g., "iPhone14,4")
    @MainActor
    static let modelIdentifier: String = {
        // Handle simulator case
        if let simulatorModelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            logger.debug("Running in simulator with model: \(simulatorModelIdentifier)")
            return simulatorModelIdentifier
        }
        
        // Get actual device identifier
        var sysinfo = utsname()
        uname(&sysinfo)
        let machineData = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))
        let identifier = String(bytes: machineData, encoding: .ascii)?
            .trimmingCharacters(in: .controlCharacters) ?? "unknown"
        
        logger.debug("Device model identified as: \(identifier)")
        return identifier
    }()
}

/// SwiftUI view extension for applying custom notch overrides
@available(iOS 13.0, *)
public extension View {
    /// Applies custom notch/island overrides to this view hierarchy
    /// - Parameter overrides: The device overrides to apply
    /// - Returns: A view with the specified notch overrides
    func notchOverrides(_ overrides: [DeviceOverride]) -> some View {
        modifier(NotchOverrideModifier(overrides: overrides))
    }
    func notchOverrides(_ overrides: [DeviceOverride]?) -> some View {
        modifier(NotchOverrideModifier(overrides: overrides.map { $0 } ?? []))
    }
    
    /// Applies a single custom notch/island override to this view hierarchy
    /// - Parameter override: The device override to apply
    /// - Returns: A view with the specified notch override
    func notchOverride(_ override: DeviceOverride) -> some View {
        notchOverrides([override])
    }
    
    /// Conditionally applies a custom notch/island override to this view hierarchy
    /// - Parameter override: Optional device override to apply (nil means no override)
    /// - Returns: A view with the specified notch override if provided
    func notchOverride(_ override: DeviceOverride?) -> some View {
        modifier(NotchOverrideModifier(overrides: override.map { [$0] } ?? []))
    }
}

/// Environment key for notch overrides
@available(iOS 13.0, *)
private struct NotchOverridesKey: EnvironmentKey {
    static let defaultValue: [DeviceOverride]? = nil
}

/// Environment extension for notch overrides
@available(iOS 13.0, *)
public extension EnvironmentValues {
    /// Custom notch overrides for the current environment
    var notchOverrides: [DeviceOverride]? {
        get { self[NotchOverridesKey.self] }
        set { self[NotchOverridesKey.self] = newValue }
    }
}

/// View modifier for applying notch overrides
@available(iOS 13.0, *)
private struct NotchOverrideModifier: ViewModifier {
    @ObservedObject private var notchManager = NotchMyProblem.shared
    let overrides: [DeviceOverride]
    
    func body(content: Content) -> some View {
        content.environment(\.notchOverrides, overrides)
    }
}
