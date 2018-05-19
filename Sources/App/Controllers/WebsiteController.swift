import Vapor
import Leaf
import Fluent

struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        router.get(use: indexHandler)
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        router.get("users", User.parameter, use: userHandler)
        router.get("users", use: allUsersHandler)
        router.get("categories", use: allCategoriesHandler)
        router.get("categories", Category.parameter, use: categoryHandler)
        router.get("acronyms", "create", use: createAcronymHandler)
        router.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPostHandler)
        router.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        router.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
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
            let categories: Future<[Category]>
        }
        
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self, { acronym in
                
                return try acronym.user
                    .get(on: req)
                    .flatMap(to: View.self, { user in
                        let categories = try acronym.categories.query(on: req).all()
                        let context = AcronymContext(title: acronym.short, acronym: acronym, user: user, categories: categories)
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
    
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        
        struct AllCategoriesContext: Encodable {
            let title = "All Categories"
            let categories: Future<[Category]> // Leaf knows how to handle futures. This helps tidy up your code when you don’t need access to the resolved futures in your request handler.
        }
        
        let categories = Category.query(on: req).all()
        let context = AllCategoriesContext(categories: categories)
        return try req.view().render("allCategories", context)
    }
    
    
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        
        struct CategoryContext: Encodable {
            let title: String
            let category: Category
            let acronyms: [Acronym]
        }
        
        return try req.parameters.next(Category.self)
            .flatMap(to: View.self, { category in
                
                return try category.acronyms
                    .query(on: req)
                    .all()
                    .flatMap(to: View.self, { (acronyms) in
                        
                        let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
                        return try req.view().render("category", context)
                    })
            })
    }
    
    
    func createAcronymHandler(_ req: Request) throws -> Future<View> {
        
        struct CreateAcronymContext: Encodable {
            let title = "Create An Acronym"
            let users: Future<[User]>
        }
        
        let context = CreateAcronymContext(users: User.query(on: req).all())
        return try req.view().render("createAcronym", context)
    }
    
    
    struct CreateAcronymData: Content {
        let userID: User.ID
        let short: String
        let long: String
        let categories: [String]?
    }
    
    func createAcronymPostHandler(_ req: Request, data: CreateAcronymData) throws -> Future<Response> {
        
        let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
        
        return acronym.save(on: req)
            .flatMap(to: Response.self, { acronym in
                guard let id = acronym.id else {
                    throw Abort(.internalServerError)
                }
                
                var categorySaves: [Future<Void>] = []
                for category in data.categories ?? [] {
                    try categorySaves.append(
                        Category.addCategory(category, to: acronym, on: req)
                    )
                }
                let redirect = req.redirect(to: "/acronyms/\(id)")
                return categorySaves.flatten(on: req)
                    .transform(to: redirect)
            })
    }
    
    
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        
        struct EditAcronymContext: Encodable {
            let title = "Edit Acronym"
            let acronym: Acronym
            let users: Future<[User]>
            let editing = true
            let categories: Future<[Category]>
        }
        
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self, { acronym in
                
                let users = User.query(on: req).all()
                let categories = try acronym.categories.query(on: req).all()
                let context = EditAcronymContext(acronym: acronym, users: users, categories: categories)
                return try req.view().render("createAcronym", context)
            })
    }
    
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(CreateAcronymData.self), { (oldAcronym, data) in
                            
                            var acronym = oldAcronym
                            acronym.short = data.short
                            acronym.long = data.long
                            acronym.userID = data.userID
                            
                            return acronym.save(on: req)
                                .flatMap(to: Response.self, { savedAcronym in
                                    guard let id = savedAcronym.id else {
                                        throw Abort(.internalServerError)
                                    }
                                    
                                    return try acronym.categories.query(on: req).all()
                                        .flatMap(to: Response.self, { existingCategories in
                                            
                                            let existingStringArray = existingCategories.map { $0.name }
                                            let existingSet = Set<String>(existingStringArray)
                                            let newSet = Set<String>(data.categories ?? [])
                                            
                                            let categoriesToAdd = newSet.subtracting(existingSet)
                                            let categoriesToRemove = existingSet.subtracting(newSet)
                                            
                                            var categoryResults: [Future<Void>] = []
                                            
                                            for newCategory in categoriesToAdd {
                                                categoryResults.append(
                                                    try Category.addCategory(newCategory, to: acronym, on: req)
                                                )
                                            }
                                            
                                            for categoryNameToRemove in categoriesToRemove {
                                                let categoryToRemove = existingCategories.first { $0.name == categoryNameToRemove }
                                                if let category = categoryToRemove {
                                                    categoryResults.append(
                                                        try AcronymCategoryPivot.query(on: req)
                                                            .filter(\.acronymID == acronym.requireID())
                                                            .filter(\.categoryID == category.requireID())
                                                            .delete()
                                                    )
                                                }
                                            }
                                            
                                            return categoryResults.flatten(on: req)
                                                .transform(to: req.redirect(to: "/acronyms/\(id)"))
                                            
                                        })
                                })
                            
        })
    }
    
    
    
    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Acronym.self).delete(on: req)
            .transform(to: req.redirect(to: "/"))
    }
}





