<div align="center">
  <img width="300" height="300" src="/assets/icon.png" alt="Logo">
  <h1><b>NotchMyProblem</b></h1>
  <p>Swift package that handles the annoying task of positioning UI elements around the iPhone's notch and Dynamic Island<br>
  <i>Compatible with iOS 13.0 and later</i></p>
</div>

## **Overview**

NotchMyProblem is a lightweight Swift package that makes it easy to position buttons and other UI elements around the notch or Dynamic Island on modern iPhones. It automatically detects the device's top cutout and provides tools to create beautiful, adaptive layouts without the hassle of manual positioning.

## **Installation**

1. Go to File > Add Packages...
2. Enter the repository URL: `https://github.com/Aeastr/NotchMyProblem`
3. Click "Add Package"

Alternatively, add it to your `Package.swift` dependencies:

---

## **Key Components**

| ![iPhone with notch showing buttons positioned on either side](assets/withNotch.png) | ![iPhone with Dynamic Island showing buttons positioned on either side](assets/withIsland.png) | ![iPhone without notch showing buttons in normal positions](assets/none.png) |
|:-----------------------------:|:-----------------------------:|:-----------------------------:|
| **Notch Devices**             | **Dynamic Island Devices**    | **Standard Devices**          |
| Automatically positions buttons around the notch | Adapts to the Dynamic Island's dimensions | Falls back to standard positioning |
| Works with iPhone X → iPhone 14 Series, iPhone 16e | Supports iPhone 14 Pro and newer | Compatible with older iPhones |
| Applies device-specific adjustments | Uses precise measurements | Maintains consistent UI across all devices |

NotchMyProblem automatically detects the device type and adjusts the UI accordingly, ensuring your buttons are perfectly positioned regardless of the device model.

---

## **Basic Usage**

### TopologyButtonsView

The simplest way to use NotchMyProblem is with the included `TopologyButtonsView`:

```swift
import SwiftUI
import NotchMyProblem

struct MyView: View {
    var body: some View {
        ZStack {
            // Your main content here
            
            // Buttons positioned around the notch/island
            TopologyButtonsView(
                leadingButton: {
                    Button(action: { print("Left button tapped") }) {
                        Image(systemName: "gear")
                    }
                },
                trailingButton: {
                    Button(action: { print("Right button tapped") }) {
                        Text("Save")
                    }
                }
            )
        }
    }
}
```

This will automatically:
- Position buttons on either side of the notch/Dynamic Island on compatible devices
- Fall back to standard left/right positioning on devices without a notch
- Adjust the spacing based on the specific device model

---

## **Advanced Usage**

<div align="leading">
  <img width="200" height="200" src="assets/notchError.png" alt="iPhone with notch showing incorrect spacing">
  <h3><b>Custom Overrides for API Inaccuracies</b></h3>
  <p>Some devices report incorrect notch dimensions through the API. Overrides correct the reported values to match actual device dimensions, ensuring consistent UI across all devices.</p>
</div>

NotchMyProblem provides several ways to customize how the notch/island area is handled:

#### 1. Global Overrides (App-wide)

```swift
// In your App's initialization
NotchMyProblem.globalOverrides = [
    .series(prefix: "iPhone13", scale: 0.95, heightFactor: 1.0, radius: 27),
    DeviceOverride(modelIdentifier: "iPhone14,3", scale: 0.8, heightFactor: 0.7)
]
```

#### 2. Instance Overrides

```swift
// For specific use cases
NotchMyProblem.shared.overrides = [
    DeviceOverride(modelIdentifier: "iPhone14,3", scale: 0.8, heightFactor: 0.7)
]
```

#### 3. View-Specific Overrides (using SwiftUI modifiers)

```swift
TopologyButtonsView(
    leadingButton: { /* ... */ },
    trailingButton: { /* ... */ }
)
.notchOverride(.series(prefix: "iPhone14", scale: 0.6, heightFactor: 0.6))
```

### Override Precedence

Overrides are applied in the following order (highest priority first):
1. View-specific overrides (via `.notchOverride()` modifier)
2. Instance-specific exact model matches
3. Instance-specific series matches
4. Global exact model matches
5. Global series matches

---

## **Creating Device Overrides**

### For Specific Device Models

```swift
// For a specific device model
let override = DeviceOverride(
    modelIdentifier: "iPhone14,3", // Exact model
    scale: 0.8,                    // Width scale (0.8 = 80% of original width)
    heightFactor: 0.7,             // Height scale (0.7 = 70% of original height)
    radius: 24                     // Corner radius (for visualization)
)
```

### For Device Series

```swift
// For all devices in a series
let seriesOverride = DeviceOverride.series(
    prefix: "iPhone14",  // All iPhone 14 models
    scale: 0.75,         // Width scale
    heightFactor: 0.75,  // Height scale
    radius: 24           // Corner radius
)
```

---

## **Manual Access**

If you need direct access to the notch/island dimensions:

```swift
// Get the raw exclusion rect (unmodified)
let rawRect = NotchMyProblem.exclusionRect

// Get the adjusted rect with any applicable overrides
let adjustedRect = NotchMyProblem.shared.adjustedExclusionRect

// Get a custom-adjusted rect with specific overrides
let customRect = NotchMyProblem.shared.adjustedExclusionRect(using: myOverrides)
```

---

## **How It Works**

NotchMyProblem uses a safe approach to access the device's notch/Dynamic Island information:

1. It retrieves the exclusion area using Objective-C runtime features
2. It safely checks for the existence of methods before calling them
3. It applies device-specific adjustments based on the model identifier
4. It provides fallbacks if the information cannot be retrieved

The package is designed to be robust against API changes and includes comprehensive logging to help diagnose any issues.

---

## **Compatibility**

- Requires iOS 13.0 or later
- Supports all notched iPhones (X, XS, XR, 11, 12, 13 series)
- Supports Dynamic Island devices (iPhone 14 Pro and newer)
- Safely falls back on devices without notches

---

## **Logging**

NotchMyProblem includes built-in logging that works across iOS versions:
- Uses `Logger` on iOS 14+
- Falls back to `os_log` on iOS 13
- Provides helpful debug information

To see logs, filter Console app output with subsystem: `com.notchmyproblem`

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE.md) for details.


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Before you begin, take a moment to review the [Contributing Guide](CONTRIBUTING.md) for details on issue reporting, coding standards, and the PR process.

## Support

If you like this project, please consider giving it a ⭐️

---

# Acknowledgments

- This package uses private API information in a safe, non-invasive way, however use at your own risk considering app store rules
- Check out [TopNotch](https://github.com/samhenrigold/TopNotch) which helped inspire this solution and provided valuable insights into working with the notch/Dynamic Island

---

<p align="center">Built with 🍏📱🏝️ by Aether</p>
