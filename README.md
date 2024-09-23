
# SignatureView

`SignatureView` is a Swift Package that provides an easy-to-use digital signature view for iOS applications. It allows users to draw their signature and returns the result as a `UIImage` via a callback.

## Features

- Simple and intuitive signature view.
- Customizable stroke color.
- Captures the signature as a `UIImage`.
- SwiftUI compatible.

## Requirements

- iOS 16.0+
- Swift 5.0+

## Installation

### Swift Package Manager

You can install `SignatureView` using Swift Package Manager. Add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/your_username/SignatureView.git", from: "1.0.0")
]
```

Alternatively, you can add the package through Xcode:

1. Go to `File > Add Packages...`
2. Enter the GitHub URL: `https://github.com/your_username/SignatureView.git`
3. Choose the latest version.

## Usage

### Basic Setup

To use the `SignatureView`, simply import the package and add it to your SwiftUI view hierarchy.

```swift
import SignatureView

struct ContentView: View {
    @State private var signatureImage: UIImage?

    var body: some View {
        SignatureView(onSave: { image in
            // Handle the signature image here
            self.signatureImage = image
        }, onCancel: {
            // Handle the cancelation here
        })
    }
}
```

### Example

1. **On Save:** When the user completes the signature and presses the "Done" button, the drawn signature is returned as a `UIImage` via the `onSave` closure.
2. **On Cancel:** The `onCancel` closure is called when the user cancels the signature process.

### Customization

You can also customize the stroke color by modifying the `color` property within the `SignatureView`.

```swift
SignatureView(onSave: { image in
    // Save or process the image
}, onCancel: {
    // Handle cancellation
}, color: .blue)
```

## Demo

Check out the demo below for a live preview of how the `SignatureView` works.

![Demo GIF](SignatureView/Demo/SignatureView.gif)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

`SignatureView` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
