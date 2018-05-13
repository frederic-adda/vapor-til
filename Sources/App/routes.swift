import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let acronymsController = AcronymsController()
    try router.register(collection: acronymsController)
    
    router.get("hello") { req -> String in
        return "Hello World"
    }
}
