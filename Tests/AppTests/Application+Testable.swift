import Vapor
import App
import FluentPostgreSQL


extension Application {
    
    static func testable(envArgs: [String]? = nil) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        
        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }
        
        try App.configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        try App.boot(app)
        return app
    }
    
    
    static func reset() throws {
        let revertEnvironmentArgs = ["vapor", "revert", "--all", "-y"]
        try Application.testable(envArgs: revertEnvironmentArgs)
            .asyncRun()
            .wait()
    }
    
    
    func sendRequest(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: HTTPBody = .init()) throws -> Response {
        
        let responder = try self.make(Responder.self)
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers, body: body)
        let wrappedRequest = Request(http: request, using: self)
        
        let response = try responder.respond(to: wrappedRequest).wait()
        return response
    }
    
    
    func sendRequest<T: Encodable>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), data: T) throws {
        
        let body = try HTTPBody(data: JSONEncoder().encode(data))
        _ = try sendRequest(to: path, method: method, headers: headers, body: body)
    }
    
    
    
    func getResponse<T: Decodable>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), body: HTTPBody = .init(), decodeTo type: T.Type) throws -> T {
        let response = try self.sendRequest(to: path, method: method, headers: headers, body: body)
        return try JSONDecoder().decode(type, from: response.http.body.data!)
    }
    
    
    func getResponse<T: Decodable, U: Encodable>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), data: U, decodeTo type: T.Type) throws -> T {
        let body = try HTTPBody(data: JSONEncoder().encode(data))
        let response = try self.sendRequest(to: path, method: method, headers: headers, body: body)
        return try JSONDecoder().decode(type, from: response.http.body.data!)
    }
    
}
