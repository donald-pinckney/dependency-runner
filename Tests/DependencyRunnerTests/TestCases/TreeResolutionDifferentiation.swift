import XCTest
@testable import DependencyRunner

final class TreeResolutionDifferentiation: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    let program_testTreeResolutionPrerelease = EcosystemProgram(declaredContexts: ["ctx"], ops: [
        .publish(package: "b", version: "0.0.1", dependencies: []),
        .publish(package: "b", version: "0.0.2", dependencies: []),
        .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))]),
        .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    ])
    

    func testTreeResolutionPrerelease() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testTreeResolutionPrerelease)
        
        let npmStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.1", children: [
                    ResolvedPackage(package: "b", version: "0.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.2", children: [])
            ]))
        ]
        
        let pipStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.1", children: [
                    ResolvedPackage(package: "b", version: "0.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.1", children: [])
            ]))
        ]
        
        
        XCTAssertEqual(resultGroups[npmStyleResult], npmNames() + yarn1Names() + yarn2Names() + cargoNames())
        XCTAssertEqual(resultGroups[pipStyleResult], pipNames())
    }
    
    
    
    let program_testTreeResolution = EcosystemProgram(declaredContexts: ["ctx"], ops: [
        .publish(package: "b", version: "1.0.1", dependencies: []),
        .publish(package: "b", version: "1.0.2", dependencies: []),
        .publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.1"))]),
        .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    ])

    func testTreeResolution() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testTreeResolution)
        
        let npmStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.1", children: [
                    ResolvedPackage(package: "b", version: "1.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.2", children: [])
            ]))
        ]
        
        let pipStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.1", children: [
                    ResolvedPackage(package: "b", version: "1.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.1", children: [])
            ]))
        ]
        
        
        XCTAssertEqual(resultGroups[npmStyleResult], npmNames() + yarn1Names() + yarn2Names())
        XCTAssertEqual(resultGroups[pipStyleResult], pipNames() + cargoNames())
    }
    
    let program_testVersionCrissCrossPrerelease = EcosystemProgram(declaredContexts: ["ctx"], ops: [
        .publish(package: "b", version: "0.0.1", dependencies: []),
        .publish(package: "b", version: "0.0.2", dependencies: []),
        .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"))]),
        .publish(package: "a", version: "0.0.2", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))]),
        .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    ])
 

    func testVersionCrissCrossPrerelease() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testVersionCrissCrossPrerelease)
        
        let npmStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.2", children: [
                    ResolvedPackage(package: "b", version: "0.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.2", children: [])
            ]))
        ]
        
        let crossChoice1 = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.2", children: [
                    ResolvedPackage(package: "b", version: "0.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.1", children: [])
            ]))
        ]
        
        let crossChoice2 = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.1", children: [
                    ResolvedPackage(package: "b", version: "0.0.2", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.2", children: [])
            ]))
        ]
        
        XCTAssertEqual(resultGroups[npmStyleResult], npmNames() + yarn1Names() + yarn2Names() + cargoNames())
        XCTAssertEqual(resultGroups[crossChoice1, default: Set()].union(resultGroups[crossChoice2, default: Set()]), pipNames())

    }
    
    
    let program_testVersionCrissCross = EcosystemProgram(declaredContexts: ["ctx"], ops: [
        .publish(package: "b", version: "1.0.1", dependencies: []),
        .publish(package: "b", version: "1.0.2", dependencies: []),
        .publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.2"))]),
        .publish(package: "a", version: "1.0.2", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.1"))]),
        .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    ])
    
    func testVersionCrissCross() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testVersionCrissCross)
        
        let npmStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.2", children: [
                    ResolvedPackage(package: "b", version: "1.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.2", children: [])
            ]))
        ]
        
        let crossChoice1 = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.2", children: [
                    ResolvedPackage(package: "b", version: "1.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.1", children: [])
            ]))
        ]
        
        let crossChoice2 = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.1", children: [
                    ResolvedPackage(package: "b", version: "1.0.2", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.2", children: [])
            ]))
        ]
        
        XCTAssertEqual(resultGroups[npmStyleResult], npmNames() + yarn1Names() + yarn2Names())
                
        // NOTE: This is really interesting! Cargo will choose one of the two crossChoice(1/2)
        // based on the lexical ordering of the clobbered name of a vs. b.
        // But it seems that pip will always choose crossChoice1. Not too sure, need to investigate more
        XCTAssertEqual(resultGroups[crossChoice1, default: Set()].union(resultGroups[crossChoice2, default: Set()]), pipNames() + cargoNames())
    }
    


    static var allTests: [(String, (TreeResolutionDifferentiation) -> () -> ())] = [
        ("testTreeResolutionPrerelease", testTreeResolutionPrerelease),
        ("testTreeResolution", testTreeResolution),
        ("testVersionCrissCrossPrerelease", testVersionCrissCrossPrerelease),
        ("testVersionCrissCross", testVersionCrissCross),
    ]
}