import Foundation

public struct SPMDanger {
    private static let dangerDepsPrefix = "DangerDeps"
    private let fileManager: FileManager
    public static let buildFolder = ".build/debug"
    public let depsLibName: String

    public init?(packagePath: String = "Package.swift", fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let packageContent = (try? String(contentsOfFile: packagePath)) ?? ""

        let regexPattern = "\\.library\\(name:[\\ ]?\"(\(SPMDanger.dangerDepsPrefix)[A-Za-z]*)"
        let regex = try? NSRegularExpression(pattern: regexPattern,
                                             options: .allowCommentsAndWhitespace)
        let firstMatch = regex?.firstMatch(in: packageContent,
                                           options: [],
                                           range: NSRange(location: 0, length: packageContent.count))

        if let depsLibNameRange = firstMatch?.range(at: 1),
            let range = Range(depsLibNameRange, in: packageContent) {
            depsLibName = String(packageContent[range])
        } else {
            return nil
        }
    }

    public func buildDependencies(executor: ShellOutExecuting = ShellOutExecutor(),
                                  fileManager _: FileManager = .default) {
        _ = try? executor.shellOut(command: "swift build --product \(depsLibName)")
    }

    public var swiftcLibImport: String {
        return "-l\(depsLibName)"
    }

    public var xcodeImportFlags: [String] {
        let libsImport = ["-l \(depsLibName)"]

        // The danger lib is not always generated, this mainly happens on the danger repo,
        // where the DangerDeps library and Danger.swiftmodule are enough
        if fileManager.fileExists(atPath: SPMDanger.buildFolder + "/libDanger.dylib") ||
            fileManager.fileExists(atPath: SPMDanger.buildFolder + "/libDanger.so") {
            return libsImport + ["-l Danger"]
        } else {
            return libsImport
        }
    }
}
