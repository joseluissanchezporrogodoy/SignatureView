//
//  ContentView.swift
//  Demo
//
//  Created by jose luis sanchez-porro godoy on 22/9/24.
//

import SwiftUI
import SignatureView

struct ContentView: View {
    @State private var showSheet = false
    @State private var signatureImage: UIImage? = nil
    
    var body: some View {
        VStack {
            if let signatureImage = signatureImage {
                Image(uiImage: signatureImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .padding()
            } else {
                Text("Not signed yet")
                    .font(.headline)
                    .padding()
            }

            Button(action: {
                showSheet.toggle()
            }) {
                Label("Sign", systemImage: "pencil")
                    .font(.title)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showSheet) {
            SheetView { signImage in
                // Cuando se devuelva la imagen de la firma
                self.signatureImage = signImage
                showSheet = false // Cierra el sheet después de firmar
            } onCancel: {
                showSheet = false // Cierra el sheet si se cancela
            }
        }
    }
}

struct SheetView: View {
    var onSign: (UIImage) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        SignatureView { signImage in
            // Llama al callback de onSign cuando se firma
            onSign(signImage)
        } onCancel: {
            // Llama al callback de onCancel cuando se cancela
            onCancel()
        }
    }
}

#Preview {
    ContentView()
}

