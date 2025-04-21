import SwiftUI
import CoreData

struct PacienteRow: View {
    let paciente: Paciente
 
    var body: some View {
        VStack(alignment: .leading) {
            Text("Nombre: \(paciente.nombre ?? "")").font(.headline)
            Text("Edad: \(paciente.edad)")
            Text("Sexo: \(paciente.sexo ?? "")")
        }
        .padding(.vertical, 4)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = PacienteViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.pacientes, id: \.objectID) { paciente in
                PacienteRow(paciente: paciente)
            }
            .navigationTitle("Pacientes")
            .toolbar {
                NavigationLink("Agregar", destination: Text("AgregarPacienteView (pendiente)"))
            }
        }
    }
}

#Preview {
    ContentView()
}
