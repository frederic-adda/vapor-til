import Vapor
import FluentPostgreSQL

struct Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    var userID: User.ID
}


extension Acronym: PostgreSQLModel {}
extension Acronym: Migration {}
extension Acronym: Content {}
extension Acronym: Parameter {}
