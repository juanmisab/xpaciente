//
//  Paciente+CoreDataProperties.swift
//  xpaciente
//
//  Created by jm on 4/20/25.
//
//

import Foundation
import CoreData


extension Paciente {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Paciente> {
        return NSFetchRequest<Paciente>(entityName: "Paciente")
    }

    @NSManaged public var bool: Bool
    @NSManaged public var edad: Int16
    @NSManaged public var nombre: String?
    @NSManaged public var sexo: String?

}

extension Paciente : Identifiable {

}
