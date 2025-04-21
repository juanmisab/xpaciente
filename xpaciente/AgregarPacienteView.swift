//
//  AgregarPacienteView.swift
//  xpaciente
//
//  Created by jm on 4/20/25.
//

import SwiftUI
import CoreData
import PhotosUI
import CoreML

struct AgregarPacienteView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var nombre = ""
    @State private var edadText = ""
    @State private var sexo = ""
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var fotoData: Data?
    @State private var classificationResult = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Datos del paciente")) {
                    TextField("Nombre", text: $nombre)
                    TextField("Edad", text: $edadText)
                        .keyboardType(.numberPad)
                    TextField("Sexo", text: $sexo)
                }
                
                Section(header: Text("Foto del paciente")) {
                    if let uiImage = inputImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    } else {
                        Button("Seleccionar foto") {
                            showImagePicker = true
                        }
                    }
                }

                Section(header: Text("Clasificación")) {
                    Text(classificationResult.isEmpty ? "Sin clasificar" : classificationResult)
                        .foregroundColor(.blue)
                }

                Section {
                    Button(action: savePaciente) {
                        Label("Guardar paciente", systemImage: "tray.and.arrow.down")
                    }
                    .disabled(nombre.isEmpty || edadText.isEmpty || sexo.isEmpty || inputImage == nil)
                }
            }
            .navigationTitle("Agregar Paciente")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $inputImage, imageData: $fotoData)
            }
            // Observe fotoData (Equatable) to trigger classification
            .onChange(of: fotoData) { _ in
                if let img = inputImage {
                    classifyImage(img)
                }
            }
        }
    }

    // MARK: - Core ML Classification

    private func classifyImage(_ uiImage: UIImage) {
        guard let buffer = uiImage.toCVPixelBuffer(width: 224, height: 224) else {
            classificationResult = "Error al procesar imagen"
            return
        }
        do {
            let model = try HeridasClassifier(configuration: .init())
            let prediction = try model.prediction(image: buffer)

            if let label = prediction.featureValue(for: "classLabel")?.stringValue {
                classificationResult = label
            } else if let probs = prediction.featureValue(for: "classLabelProbs")?.dictionaryValue as? [String: Double],
                      let best = probs.max(by: { $0.value < $1.value })?.key {
                classificationResult = best
            } else {
                classificationResult = "Sin resultado"
            }

        } catch {
            classificationResult = "Error clasificando"
            print("ML Error:", error.localizedDescription)
        }
    }

    // MARK: - Save to Core Data

    private func savePaciente() {
        guard let edad = Int16(edadText) else { return }
        let nuevo = Paciente(context: context)
        nuevo.nombre      = nombre
        nuevo.edad        = edad
        nuevo.sexo        = sexo
        nuevo.resultadoML = classificationResult
        nuevo.foto        = fotoData

        do {
            try context.save()
            dismiss()
        } catch {
            print("Error guardando paciente:", error.localizedDescription)
        }
    }
}

// MARK: - Preview

struct AgregarPacienteView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        AgregarPacienteView()
            .environment(\.managedObjectContext, context)
    }
}

// MARK: - UIImage → CVPixelBuffer Extension

extension UIImage {
    func toCVPixelBuffer(width: Int = 224, height: Int = 224) -> CVPixelBuffer? {
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        guard let resized = UIGraphicsGetImageFromCurrentImageContext(),
              let cgImage = resized.cgImage else { return nil }

        let attrs: CFDictionary = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32ARGB, attrs,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        guard let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}

// MARK: - ImagePicker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var imageData: Data?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // no-op
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    if let uiImage = object as? UIImage {
                        self?.parent.image = uiImage
                        self?.parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
    }
}
