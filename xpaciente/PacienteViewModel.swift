import SwiftUI
import Foundation
import CoreData

class PacienteViewModel: ObservableObject {
    @Published var pacientes: [xpaciente.Paciente] = []

    let context = PersistenceController.shared.container.viewContext

    init() {
        cargarPacientes()
    }

    func cargarPacientes() {
        let request: NSFetchRequest<xpaciente.Paciente> = xpaciente.Paciente.fetchRequest()
        do {
            pacientes = try context.fetch(request)
        } catch {
            print("Error al cargar pacientes: \(error)")
        }
    }

    func agregarPaciente(nombre: String, edad: Int16, sexo: String, bool: Bool) {
        let nuevoPaciente = xpaciente.Paciente(context: context)
        nuevoPaciente.nombre = nombre
        nuevoPaciente.edad = edad
        nuevoPaciente.sexo = sexo
        nuevoPaciente.bool = bool

        do {
            try context.save()
            cargarPacientes()
        } catch {
            print("Error al guardar paciente: \(error)")
        }
    }
}
