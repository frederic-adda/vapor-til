import Foundation
import Vapor
import FluentPostgreSQL


struct User: Codable {
    var id: UUID?
    var name: String
    var username: String
    
    init(name: String, username: String) {
        self.name = name
        self.username = username
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Migration {}
extension User: Content {}
extension User: Parameter {}


extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.userID) // user reference on the children
    }
}
