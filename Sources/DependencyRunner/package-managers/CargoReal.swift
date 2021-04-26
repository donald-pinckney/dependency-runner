import ShellOut
import Foundation

class CargoRealImpl {
    let dirManager = GenDirManager(baseName: "cargo-real")
    var templateManager = TemplateManager(templateName: "cargo-real")
    
    fileprivate init() {
        self.templateManager.delegate = self
    }
}

extension CargoRealImpl : PackageManager {
    var uniqueName: String { "cargo-real" }
        
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) {
        let sourceDir = dirManager.generateUniqueSourceDirectory(forPackage: package, version: version)
                
        templateManager.instantiatePackageTemplate(intoDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
                
        try! shellOut(to: "cargo", arguments: ["publish", "--token", "cioZQpaR2LhJ79zPxX22aMj0B5zhC7CSCrr", "--no-verify", "--allow-dirty"], at: sourceDir)
    }
    
    func yank(package: Package, version: Version) {
        fatalError("Unimplemented")
    }
    
    func makeSolveContext() -> SolveContext {
        let contextDir = dirManager.newContextDirectory()
        
        let context = CargoSolveContext(contextDir: contextDir, templateManager: self.templateManager)
        return context.solve
    }
    
    func startup() {}
    func shutdown() {}
}


extension CargoRealImpl : TemplateManagerDelegate {
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String] {
        [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.description,
            "$DEPENDENCIES_TOML_FRAGMENT" : dependencies.map { $0.cargoRealFormat() }.joined(separator: "\n"),
//            "$DEPENDENCY_IMPORTS" : dependencies.map() { "use \($0.packageToDependOn);" }.joined(separator: "\n"),
//            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn)::dep_tree(indent + 1);" }.joined(separator: "\n    ")
        ]
    }
}

extension DependencyExpr {
    func cargoRealFormat() -> String {
        "\(self.packageToDependOn) = { version = \"\(self.constraint.cargoFormat())\" }"
    }
}

func CargoReal() -> PackageManager {
    WaitForUpdateManager(wrapping: CargoRealImpl(), sleepTime: 60)
}