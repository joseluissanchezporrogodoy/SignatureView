import SwiftUI
import CoreGraphics
import UIKit

private let placeholderText = "Introduce firma"
private let maxHeight: CGFloat = 300
private let lineWidth: CGFloat = 1

/// A `SignatureView` is a SwiftUI view where users can draw their signature.
/// - Parameters:
///   - onSave: A closure that gets called when the signature is saved as a `UIImage`.
///   - onCancel: A closure that gets called when the signature is cancelled.
public struct SignatureView: View {
    public let onSave: (UIImage) -> Void
    public let onCancel: () -> Void

    @State private var saveSignature = false
    @State private var color = Color.black
    
    @State private var drawing = DrawingPath()
    @State private var image = UIImage()
    @State private var isImageSet = false
    @State private var text = ""
    
    public init(onSave: @escaping (UIImage) -> Void,
                onCancel: @escaping () -> Void) {
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack {
            SignatureDrawView(drawing: $drawing, color: $color)
            HStack {
                Button("Hecho", action: extractImageAndHandle)
                Spacer()
                Button("Rehacer", action: clear)
                Spacer()
                Button("Cancelar", action: onCancel)
            }
        }.padding()
    }
    
    /// Extracts the drawn signature from the view as a `UIImage` and passes it to the `onSave` closure.
    private func extractImageAndHandle() {
        let image: UIImage
        let path = drawing.path.cgPath // Convertimos el Path a CGPath
        let maxX = drawing.points.map { $0.x }.max() ?? 0 // Calculamos el máximo en el eje X
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: maxX, height: maxHeight))
        
        let uiImage = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(color.uiColor.cgColor)
            ctx.cgContext.setLineWidth(lineWidth)
            ctx.cgContext.beginPath()
            ctx.cgContext.addPath(path)
            ctx.cgContext.drawPath(using: .stroke)
        }
        
        image = uiImage
        
        // Guardamos la firma en un archivo si es necesario
        if saveSignature {
            if let data = image.pngData(),
               let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let filename = docsDir.appendingPathComponent("Signature-\(Date()).png")
                try? data.write(to: filename)
            }
        }
        onSave(image)
    }
    
    /// Clears the drawing and resets the view.
    private func clear() {
        drawing = DrawingPath()
        image = UIImage()
        isImageSet = false
        text = ""
    }
}

/// `FramePreferenceKey` is used to track the size of the drawing area.
struct FramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/// A `SignatureDrawView` handles the actual drawing process by capturing points from a `DragGesture`.
/// - Parameters:
///   - drawing: A binding to a `DrawingPath` where the points are stored.
///   - color: The color of the drawing stroke.
struct SignatureDrawView: View {
    @Binding var drawing: DrawingPath
    @Binding var color: Color

    @State private var drawingBounds: CGRect = .zero
    @State private var lastPoint: CGPoint = .zero

    var body: some View {
        ZStack {
            Color.white
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: FramePreferenceKey.self,
                                           value: geometry.frame(in: .local))
                })
                .onPreferenceChange(FramePreferenceKey.self) { bounds in
                    drawingBounds = bounds
                }
            if drawing.isEmpty {
                Text(placeholderText)
                    .foregroundColor(.gray)
            } else {
                DrawShape(drawingPath: drawing)
                    .stroke(lineWidth: 2)
                    .foregroundColor(color)
            }
        }
        .frame(height: 300)
        .gesture(DragGesture()
            .onChanged { value in
                if drawingBounds.contains(value.location) {
                    let distance = hypot(value.location.x - lastPoint.x, value.location.y - lastPoint.y)

                    // Solo añadir punto si la distancia es significativa
                    if distance > 1.5 {
                        drawing.addPoint(value.location)
                        lastPoint = value.location
                    }
                }
            }
            .onEnded { _ in
                drawing.addBreak() // Añadir un break cuando se termina el gesto (se levanta el dedo)
                lastPoint = .zero
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 7)
            .stroke(Color(red: 110 / 255, green: 182 / 255, blue: 225 / 255, opacity: 1)))
    }
}

/// `DrawingPath` stores the points and breaks of the signature.
struct DrawingPath {
    private(set) var points = [CGPoint]()
    private var breaks = [Int]()

    var isEmpty: Bool {
        points.isEmpty
    }

    /// Adds a new point to the drawing.
    /// - Parameter point: The point to be added.
    mutating func addPoint(_ point: CGPoint) {
        points.append(point)
    }

    /// Adds a break in the drawing, marking the end of a stroke.
    mutating func addBreak() {
        breaks.append(points.count)
    }

    /// Creates a SwiftUI `Path` from the list of points.
    var path: Path {
        var path = Path()
        guard points.count > 1 else { return path }

        // Inicia la ruta en el primer punto
        path.move(to: points[0])

        for i in 1..<points.count {
            if breaks.contains(i) {
                path.move(to: points[i]) // Romper la línea si se encuentra un "break"
            } else {
                // Usar curva de Bézier cuadrática para suavizar
                let currentPoint = points[i]
                let previousPoint = points[i - 1]
                let midPoint = CGPoint(
                    x: (currentPoint.x + previousPoint.x) / 2,
                    y: (currentPoint.y + previousPoint.y) / 2
                )
                path.addQuadCurve(to: midPoint, control: previousPoint)
            }
        }
        return path
    }

    /// Converts the SwiftUI `Path` to a `CGPath` to be used with CoreGraphics.
    func cgPath() -> CGPath {
        let cgPath = path.cgPath
        return cgPath
    }
}

/// `DrawShape` is responsible for drawing the smooth path in the view.
struct DrawShape: Shape {
    let drawingPath: DrawingPath

    func path(in rect: CGRect) -> Path {
        return drawingPath.path
    }
}

#Preview {
    SignatureView { image in
        _ = Image(uiImage: image)
    } onCancel: {
        
    }
}

extension Color {
    /// Converts a SwiftUI `Color` to a `UIColor`.
    var uiColor: UIColor {
        if #available(iOS 14, *) {
            return UIColor(self)
        } else {
            let components = self.components
            return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
        }
    }

    /// Extracts the RGBA components from a SwiftUI `Color`.
    private var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000ff) / 255
        }
        return (r, g, b, a)
    }
}

