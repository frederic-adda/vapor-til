import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    

    router.get("hello") { req -> String in
        return "Hello World"
    }
    
    router.post("api", "acronyms") { req -> Future<Acronym> in
        return try req.content.decode(Acronym.self)
            .flatMap(to: Acronym.self, { acronym in
                return acronym.save(on: req)
            })
    }
}
