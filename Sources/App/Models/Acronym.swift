import Vapor
import FluentPostgreSQL

struct Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    var userID: User.ID
}


extension Acronym: PostgreSQLModel {}
extension Acronym: Content {}
extension Acronym: Parameter {}


extension Acronym {
    
    var user: Parent<Acronym, User> {
        return parent(\.userID)
    }
}


extension Acronym: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection, closure: { builder in
            try addProperties(to: builder)
            // Add a reference between the userID property on Acronym and the id property on User.
            // This sets up the foreign key constraint between the two tables.
            try builder.addReference(from: \.userID, to: \User.id) 
        })
    }
}
