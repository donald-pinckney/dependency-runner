let aVersions: [EcosystemOp] = (0...3).flatMap { major in (0...3).flatMap { minor in (0...3).map { bug in .publish(package: "a", version: Version(major: major, minor: minor, bug: bug), dependencies: []) } } }

func testResolve(constraint c: ConstraintExpr) -> EcosystemProgram {
    EcosystemProgram(declaredContexts: ["ctx"], ops: aVersions + [.solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: c)])])
}

// Same behavior across all 5 package managers
let program_TestC_Exactly = testResolve(constraint: .exactly("1.2.3"))
let program_TestC_Geq = testResolve(constraint: .geq("1.2.3"))
let program_TestC_Gt = testResolve(constraint: .gt("1.2.3"))
let program_TestC_Leq = testResolve(constraint: .leq("1.2.3"))
let program_TestC_Lt = testResolve(constraint: .lt("1.2.3"))
let program_TestC_Tilde = testResolve(constraint: .tilde("1.2.2"))
let program_TestC_WildcardMajor = testResolve(constraint: .wildcardMajor)
let program_TestC_WildcardMinor = testResolve(constraint: .wildcardMinor(1))
let program_TestC_WildcardBug = testResolve(constraint: .wildcardBug(1, 2))

// Does not exist in pip, works the same in all other package managers
let program_TestC_Caret = testResolve(constraint: .caret("1.2.2"))

// Only supported by pip
let program_TestC_NotExactly = testResolve(constraint: .not(.exactly("3.3.3")))
let program_TestC_NotWildcardBug = testResolve(constraint: .not(.wildcardBug(3, 3)))
let program_TestC_NotWildcardMinor = testResolve(constraint: .not(.wildcardMinor(3)))

// Supported by pip, but causes a bug!
// See: https://github.com/pypa/pip/issues/10011
let program_TestC_NotWildcardMajor = testResolve(constraint: .not(.wildcardMajor))

// Nothing works
let program_TestC_And = testResolve(constraint: .and(.geq("1.2.3"), .leq("2.2.2")))
let program_TestC_Or = testResolve(constraint: .or(.geq("2.2.2"), .leq("1.2.3")))
