import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        router.get(use: indexHandler)
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        router.get("users", User.parameter, use: userHandler)
        router.get("users", use: allUsersHandler)
    }
    
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        
        struct IndexContext: Encodable {
            var title: String
            var acronyms: [Acronym]?
        }
        
        return Acronym.query(on: req)
            .all()
            .flatMap(to: View.self, { acronyms in
                let acronymsData = acronyms.isEmpty ? nil : acronyms // This is easier for Leaf to manage than an empty array.
                let context = IndexContext(title: "Homepage", acronyms: acronymsData)
                return try req.view().render("index", context)
            })
    }
    
    
    func acronymHandler(_ req: Request) throws -> Future<View> {
       
        struct AcronymContext: Encodable {
            let title: String
            let acronym: Acronym
            let user: User
        }
        
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self, { acronym in
                
                return try acronym.user
                .get(on: req)
                    .flatMap(to: View.self, { user in
                        
                        let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
                        return try req.view().render("acronym", context)
                    })
            })
    }
    
    
    func userHandler(_ req: Request) throws -> Future<View> {
        
        struct UserContext: Encodable {
            let title: String
            let user: User
            let acronyms: [Acronym]
        }
        
        return try req.parameters.next(User.self)
            .flatMap(to: View.self, { user in
                
                return try user.acronyms
                    .query(on: req)
                    .all()
                    .flatMap(to: View.self, { acronyms in
                        let context = UserContext(title: user.name, user: user, acronyms: acronyms)
                        return try req.view().render("user", context)
                    })
            })
    }
    
    
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        
        struct AllUsersContext: Encodable {
            let title: String
            let users: [User]
        }
        
        return User.query(on: req)
            .all()
            .flatMap(to: View.self, { users in
                let context = AllUsersContext(title: "All Users", users: users)
                return try req.view().render("allUsers", context)
            })
    }
    
}





