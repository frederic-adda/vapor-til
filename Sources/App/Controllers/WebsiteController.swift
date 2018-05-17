import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        router.get(use: indexHandler)
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
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
    
    
    
    
}





