import Foundation
import FluentPostgreSQL


final class AcronymCategoryPivot: PostgreSQLUUIDPivot {
    var id: UUID?
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    typealias Left = Acronym
    typealias Right = Category
    
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID
    
    init(_ acronymID: Acronym.ID, _ categoryID: Category.ID) {
        self.acronymID = acronymID
        self.categoryID = categoryID
    }
}

extension AcronymCategoryPivot: Migration {
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection, closure: { builder in
            try addProperties(to: builder)
            // Add a reference between the acronymID property on AcronymCategoryPivot and the id property on Acronym.
            // This sets up the foreign key constraint.
            try builder.addReference(from: \.acronymID, to: \Acronym.id)
            // Add a reference between the categoryID property on AcronymCategoryPivot and the id property on Category.
            // This sets up the foreign key constraint.
            try builder.addReference(from: \.categoryID, to: \Category.id)
        })
    }
}

