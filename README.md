<div align="center">
  <img width="270" height="270" src="/assets/icon.png" alt="Logo">
  <h1><b>NotchMyProblem</b></h1>
  <p>Swift package that handles the annoying task of positioning UI elements around the iPhone's notch and Dynamic Island<br>
</div>

<div align="center">
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version">
  </a>
  <a href="https://www.apple.com/ios/">
    <img src="https://img.shields.io/badge/iOS-13%2B-blue.svg" alt="iOS">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
  </a>
</div>

## **Overview**

NotchMyProblem is a lightweight Swift package that makes it easy to position buttons and other UI elements around the notch or Dynamic Island on modern iPhones. It automatically detects the device's top cutout and provides tools to create beautiful, adaptive layouts without the hassle of manual positioning.

## **Installation**

1. In Xcode go to **File > Add Packages…**  
2. Enter the repository URL: `https://github.com/Aeastr/NotchMyProblem`  
3. Click **Add Package**

Alternatively, add it to your `Package.swift` dependencies:

```swift
// Package.swift
dependencies: [
  .package(url: "https://github.com/Aeastr/NotchMyProblem.git", from: "2.0.0")
]
```

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

### CutoutAccessoryView

The simplest way to use NotchMyProblem is with the included `CutoutAccessoryView`.

```swift
import SwiftUI
import NotchMyProblem

struct MyView: View {
    var body: some View {
        ZStack {
            // Your main content here

            // Buttons positioned around the notch/island
            CutoutAccessoryView(
                padding: .auto,
                leadingContent: {
                    Button(action: { print("Left tapped") }) {
                        Image(systemName: "gear")
                    }
                },
                trailingContent: {
                    Button(action: { print("Right tapped") }) {
                        Text("Save")
                    }
                }
            )
        }
    }
}
```

---

## **Padding**

Modern iPhones have Notches, Dynamic Islands, and heavily rounded corners. If you place buttons or other UI elements too close to these cutouts you risk:

- Elements appearing cramped or uncomfortably close to the cutout  
- Parts of your UI being clipped by the curved screen edges  
- Inconsistent spacing across different device models  

By adding padding that *scales* with the actual cutout dimensions, NotchMyProblem ensures that your content:

1. Always sits at a safe distance from the notch/island  
2. Never collides with the device’s rounded corners  
3. Maintains a consistent, polished look on every supported iPhone  

### Controlling Padding

1. **Cutout padding** – extra space _around_ the display cut out
2. **Content padding** – extra space on either side of your HStack content  
3. **Vertical padding** – extra space above and below your content  

Use the `padding` parameter when initializing `CutoutAccessoryView`:

```swift
CutoutAccessoryView(
  padding: .auto, 
  leadingContent: { /* … */ },
  trailingContent:{ /* … */ }
)
```

### Available Modes

- **`.auto`**  
  Uses intelligent curves that adapt to cutout size. **Smaller cutouts get more padding, larger cutouts get less padding** - the opposite of simple percentage-based approaches. This ensures optimal spacing across all device types:
  - Dynamic Island (narrow): Gets generous padding for breathing room
  - iPhone notch (wide): Gets minimal padding since the cutout already creates natural spacing
  - Uses inverse relationship: `padding = base - (cutoutWidth × slope)` with min/max bounds

- **`.none`**  
  No extra padding; your views will hug the safe-area edges exactly.

- **`.custom(cutout: , content: , vertical:)`**  
  Supply closures to compute each padding dynamically:

  ```swift
  CutoutAccessoryView(
    padding: .custom(
      cutout:  { cutoutW  in cutoutW / 12 },    // 1/12 of cutout width
      content: { cutoutW  in cutoutW / 6  },    // 1/6 of cutout width
      vertical:{ cutoutH  in cutoutH * 0.2 }     // 20% of cutout height
    ),
    leadingContent: { /* … */ },
    trailingContent:{ /* … */ }
  )
  ```

---

## **Overrides**

![iPhone 16e close up of notch area showing 2 buttons, cancel and export pushing up agasint the dispaly border, misaligned with the notch space](assets/notchError.png)

Some devices report incorrect notch dimensions through the API. Overrides correct the reported values to match actual device dimensions, ensuring consistent UI across all devices.

NotchMyProblem has overrides by **default** already, devices like the iPhone 16e require this to correctly proportion elements, you do not need to figure these out for yourself, but you can create your own adjustments, or configure other devices 

### 1. Global Overrides (App-wide)

```swift
// In your App’s initialization (e.g. in @main or AppDelegate)
NotchMyProblem.globalOverrides = [
    .series(prefix: "iPhone13", scale: 0.95, heightFactor: 1.0, radius: 27),
    DeviceOverride(modelIdentifier: "iPhone14,3", scale: 0.8, heightFactor: 0.7)
]
```

### 2. Instance Overrides

```swift
// At runtime, for specific cases
NotchMyProblem.shared.overrides = [
    DeviceOverride(modelIdentifier: "iPhone14,3", scale: 0.8, heightFactor: 0.7)
]
```

### 3. View-Specific Overrides (SwiftUI)

```swift
CutoutAccessoryView(/* … */)
  .notchOverride(.series(prefix: "iPhone14", scale: 0.6, heightFactor: 0.6))
```

#### Override Precedence

1. View-specific overrides  
2. Instance-specific exact model  
3. Instance-specific series prefix  
4. Global exact model  
5. Global series prefix  

---

## **Manual Access**

```swift
let rawRect    = NotchMyProblem.exclusionRect                   // raw API result
let adjusted   = NotchMyProblem.shared.adjustedExclusionRect    // with global/instance overrides
let customRect = NotchMyProblem.shared.adjustedExclusionRect(using: myOverrides)
```

---

## **Logging**

Filter Console with subsystem `com.notchmyproblem` to see debug/info/error logs.

---

# Acknowledgments

- [TopNotch](https://github.com/samhenrigold/TopNotch)  
- Uses private APIs safely—use at your own risk

---

## Where to find me:  
- here, obviously.  
- [Twitter](https://x.com/AetherAurelia)  
- [Threads](https://www.threads.net/@aetheraurelia)  
- [Bluesky](https://bsky.app/profile/aethers.world)  
- [LinkedIn](https://www.linkedin.com/in/willjones24)

<p align="center">Built with 🍏📱🏝️ by Aether</p>
