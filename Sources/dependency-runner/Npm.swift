import Files
import ShellOut

struct Npm : PackageManagerWithRegistry {
    let name = "npm"
    
    func initRegistry() {
        run(script: "init_registry.sh", arguments: [])
    }
    
    
    func versionSpecStr(_ vs: VersionSpecifier) -> String {
        switch vs {
        case .any:
            return ""
        case .exactly(let v):
            return "==\(v.semverName)"
        }
    }
    
    func formatDepenency(dep: (Package, VersionSpecifier)) -> String {
        "\(dep.0.name)\(self.versionSpecStr(dep.1))"
    }
    
    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions: [String : String] = [:
//            "$NAME_STRING" : package.name,
//            "$VERSION_STRING" : version.semverName,
//            "$DEPENDENCIES_COMMA_SEP" : dependencies.map(self.formatDepenency).map {$0.quoted()}.joined(separator: ", \n"),
//            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import " + $0.0.name }.joined(separator: "\n"),
//            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func mainTemplateSubstitutions(dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions: [String : String] = [:
//            "$DIST_DIR" : self.genBinPathDir,
//            "$DEPENDENCIES_LINE_SEP" : dependencies.map(self.formatDepenency).joined(separator: "\n"),
//            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import " + $0.0.name }.joined(separator: "\n"),
//            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func publish(package: Package, version: Version, pkgDir: String) {
//        print("Building: \(pkgDir)")
        try! shellOut(to: "npm publish --registry http://localhost:4873", at: pkgDir)
    }
    
    
    func solveCommand(forMainPath mainPath: String) -> SolveCommand {
        let solver = SolveCommand(directory: mainPath, command: """
            npm install --registry http://localhost:4873
        """)
        
        return solver
    }
}
