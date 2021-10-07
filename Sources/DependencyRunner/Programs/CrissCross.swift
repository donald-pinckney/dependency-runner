let program_CrissCross = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "1.0.1", dependencies: []),
    .publish(package: "b", version: "1.0.2", dependencies: []),
    .publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.2"), depType: .prod)]),
    .publish(package: "a", version: "1.0.2", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.1"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod)])
])
