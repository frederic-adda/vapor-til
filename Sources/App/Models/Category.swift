import Vapor
import FluentPostgreSQL


struct Category: Codable {
    var id: Int?
    var name: String
}


extension Category: PostgreSQLModel {}
extension Category: Content {}
extension Category: Migration {}
extension Category: Parameter {}


extension Category {
    var acronyms: Siblings<Category, Acronym, AcronymCategoryPivot> {
        return siblings()
    }
}
