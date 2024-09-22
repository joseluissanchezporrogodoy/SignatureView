// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import CoreGraphics
import UIKit

private let placeholderText = "Introduce firma"
private let maxHeight: CGFloat = 300
private let lineWidth: CGFloat = 1

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
            SignatureDrawView(drawing: $drawing,
                              color: $color)
            HStack {
                Button("Hecho", action: extractImageAndHandle)
                Spacer()
                Button("Rehacer", action: clear)
                Spacer()
                Button("Cancelar", action: onCancel)
            }
        }.padding()
    }
    
    private func extractImageAndHandle() {
        let image: UIImage
        let path = drawing.cgPath
        let maxX = drawing.points.map { $0.x }.max() ?? 0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: maxX, height: maxHeight))
        let uiImage = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(color.uiColor.cgColor)
            ctx.cgContext.setLineWidth(lineWidth)
            ctx.cgContext.beginPath()
            ctx.cgContext.addPath(path)
            ctx.cgContext.drawPath(using: .stroke)
        }
        image = uiImage
        
        if saveSignature {
            if let data = image.pngData(),
               let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let filename = docsDir.appendingPathComponent("Signature-\(Date()).png")
                try? data.write(to: filename)
            }
        }
        onSave(image)
    }
    
    private func clear() {
        drawing = DrawingPath()
        image = UIImage()
        isImageSet = false
        text = ""
    }
}


struct FramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}

struct SignatureDrawView: View {
  @Binding var drawing: DrawingPath
  @Binding var color: Color
  
  @State private var drawingBounds: CGRect = .zero
  @State private var lastPoint: CGPoint = .zero // Añadir una variable para almacenar el último punto
    
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
          Text("Firma aquí")
            .foregroundColor(.gray)
        } else {
          DrawShape(drawingPath: drawing)
            .stroke(lineWidth: 2)
            .foregroundColor(color)
        }
      }
      .frame(height: 300)
      .gesture(DragGesture()
        .onChanged( { value in
          if drawingBounds.contains(value.location) {
            let distance = hypot(value.location.x - lastPoint.x, value.location.y - lastPoint.y)
            
            // Solo añadimos el punto si la distancia es mayor que un umbral pequeño
              if distance > 1.5 { // Ajusta este valor según lo que necesites
              drawing.addPoint(value.location)
              lastPoint = value.location // Actualizamos el último punto
            }
          } else {
            drawing.addBreak()
          }
        }).onEnded( { value in
          drawing.addBreak()
          lastPoint = .zero // Restablecemos el último punto al finalizar
        }))
      .overlay(RoundedRectangle(cornerRadius: 7)
                .stroke(Color( red: 110/255, green: 182/255, blue: 225/255, opacity: 1)))
  }
}
struct DrawingPath {
    private(set) var points = [CGPoint]()
    private var breaks = [Int]()
    
    var isEmpty: Bool {
        points.isEmpty
    }
    
    mutating func addPoint(_ point: CGPoint) {
        points.append(point)
    }
    
    mutating func addBreak() {
        breaks.append(points.count)
    }
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        for i in 1..<points.count {
            if breaks.contains(i) {
                path.move(to: points[i])
            } else {
                path.addLine(to: points[i])
            }

        }
        return path
    }
    
    var path: Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        for i in 1..<points.count {
            if breaks.contains(i) {
                path.move(to: points[i])
            } else {
                path.addLine(to: points[i])
            }

        }
        return path
    }
}

struct DrawShape: Shape {
    let drawingPath: DrawingPath
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard let firstPoint = drawingPath.points.first else {
            return path
        }
        
        path.move(to: firstPoint)
        
        for i in 1..<drawingPath.points.count {
            let currentPoint = drawingPath.points[i]
            let previousPoint = drawingPath.points[i - 1]
            let midPoint = CGPoint(
                x: (currentPoint.x + previousPoint.x) / 2,
                y: (currentPoint.y + previousPoint.y) / 2
            )
            path.addQuadCurve(to: midPoint, control: previousPoint)
        }
        
        return path
    }
}



//
//struct SignatureViewTest: View {
//    @State private var image: UIImage? = nil
//    @State private var showPopover = false
//    @State private var showSignatureField = true
//    var body: some View {
//                VStack {
//                    Button("Botón") {
//                        showPopover.toggle()
//                    }.sheet(isPresented: $showPopover) {
//                        SignatureView(onSave: { image in
//                            self.image = image
//                            showPopover.toggle()
//                        }, onCancel: {
//                            showPopover.toggle()
//                        }).frame(width: 500, height: 300, alignment: .center)
//
//                    }
//
//                    if image != nil {
//                        Image(uiImage: image!)
//                    }
//        }
//    }
//}

//struct SignatureView_Previews: PreviewProvider {
//    static var previews: some View {
//        SignatureView { image in
//           _ =  Image(uiImage: image)
//        } onCancel: {
//            
//        }
//        .previewDevice("iPad Pro (9.7-inch)")
//        .previewLayout(.device)
//
//    }
//}

#Preview {
    SignatureView { image in
        _ =  Image(uiImage: image)
    } onCancel: {
        
    }
}

extension Color {
    var uiColor: UIColor {
        if #available(iOS 14, *) {
            return UIColor(self)
        } else {
            let components = self.components
            return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
        }
    }
    
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
