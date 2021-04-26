import ShellOut
import Foundation
import CryptoSwift

struct Utils {
    static func mkdir_p(path: String) {
        try! shellOut(to: "mkdir", arguments: ["-p", path])
    }

    static private func cd(path: String) {
        FileManager().changeCurrentDirectoryPath(path)
    }

//    func cp(from: String, to: String) throws {
//        try shellOut(to: "cp", arguments: [from, to])
//    }
//
//    func cp_r(from: String, to: String) throws {
//        try shellOut(to: "cp", arguments: ["-R", from, to])
//    }
//
//    func cp_contents(from: String, to: String) throws {
//        try shellOut(to: "cp", arguments: ["-a", from + ".", to])
//    }
//
//    func mv(from: String, to: String) throws {
//        try shellOut(to: "mv", arguments: [from, to])
//    }


    static private func projectRootDir() -> URL {
        let myPath = URL(fileURLWithPath: #filePath)
        return myPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }


    static private var didSetWd = false

    static func cdToProjectRoot() {
        if !didSetWd {
            didSetWd = true
            cd(path: projectRootDir().path)
        }
    }

//    func absolutePathRelativeToProjectRoot(forPath: String) -> String {
//        var p: String
//        if forPath.starts(with: "/") {
//            p = forPath
//            p.removeFirst()
//        } else {
//            p = forPath
//        }
//        return projectRootDir().path + "/" + p
//    }
    
}


extension String {
    func quoted() -> String {
        "'\(self)'"
    }
}

var _debug = false

func logDebug(_ x: String) {
    if _debug {
        print(x)
    }
}

func sha256(data: Data) -> String {
    data.sha256().toHexString()
}

func sha256(file: String) throws -> String {
    sha256(data: try Data(contentsOf: URL(fileURLWithPath: file)))
}