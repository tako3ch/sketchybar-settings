import Foundation

enum BundledResources {
  private final class Token {}

  static var bundle: Bundle { Bundle(for: Token.self) }

  static func spotifyScriptURL() -> URL? {
    if let url = bundle.url(forResource: "spotify", withExtension: "sh", subdirectory: "plugins") {
      return url
    }
    return bundle.url(forResource: "spotify", withExtension: "sh")
  }
}

struct CommandResult: Equatable {
    let exitCode: Int32
    let output: String
}

protocol CommandRunning {
    func run(executablePath: String, arguments: [String]) -> CommandResult
}

struct LiveCommandRunner: CommandRunning {
    func run(executablePath: String, arguments: [String]) -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return CommandResult(exitCode: -1, output: error.localizedDescription)
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return CommandResult(exitCode: process.terminationStatus, output: output)
    }
}

protocol SketchyBarApplying {
    func apply(configuration: String, configPath: String) throws
    func restartSketchyBar() throws
    func query(widgetID: String) -> String?
}

struct SketchyBarApplier: SketchyBarApplying {
    enum ApplyError: LocalizedError {
        case writeFailed(String)
        case pluginSyncFailed(String)
        case restartFailed(String)

        var errorDescription: String? {
            switch self {
            case .writeFailed(let message):
                "rc 書き込みに失敗しました: \(message)"
            case .pluginSyncFailed(let message):
                "プラグイン同期に失敗しました: \(message)"
            case .restartFailed(let message):
                "SketchyBar 再起動に失敗しました: \(message)"
            }
        }
    }

    let runner: CommandRunning
    let brewPath: String
    let sketchybarPath: String

    init(
        runner: CommandRunning = LiveCommandRunner(),
        brewPath: String = "/opt/homebrew/bin/brew",
        sketchybarPath: String = "/opt/homebrew/bin/sketchybar"
    ) {
        self.runner = runner
        self.brewPath = brewPath
        self.sketchybarPath = sketchybarPath
    }

    func apply(configuration: String, configPath: String) throws {
        let url = URL(fileURLWithPath: configPath)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try configuration.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ApplyError.writeFailed(error.localizedDescription)
        }
    }

    func restartSketchyBar() throws {
        let result = runner.run(
            executablePath: brewPath,
            arguments: ["services", "restart", "sketchybar"]
        )
        guard result.exitCode == 0 else {
            throw ApplyError.restartFailed(result.output)
        }
    }

    func query(widgetID: String) -> String? {
        let result = runner.run(
            executablePath: sketchybarPath,
            arguments: ["--query", widgetID]
        )
        guard result.exitCode == 0, !result.output.contains("not found") else { return nil }
        return result.output
    }

    func syncBundledPlugins(to pluginsDir: String) throws {
        guard let sourceURL = BundledResources.spotifyScriptURL() else {
            return
        }

        let destinationURL = URL(fileURLWithPath: pluginsDir).appendingPathComponent("spotify.sh")
        do {
            try FileManager.default.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            try FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o755)],
                ofItemAtPath: destinationURL.path
            )
        } catch {
            throw ApplyError.pluginSyncFailed(error.localizedDescription)
        }
    }

    func apply(store: SettingsStore) throws {
        let configuration = try TemplateRenderer.render(store.renderInput)
        try apply(configuration: configuration, configPath: store.configPath)
        try syncBundledPlugins(to: store.pluginsDir)
        try restartSketchyBar()
    }
}

final class MockCommandRunner: CommandRunning {
    private(set) var commands: [(String, [String])] = []
    var results: [String: CommandResult] = [:]
    var defaultResult = CommandResult(exitCode: 0, output: "")

    func run(executablePath: String, arguments: [String]) -> CommandResult {
        commands.append((executablePath, arguments))
        let key = "\(executablePath) \(arguments.joined(separator: " "))"
        return results[key] ?? defaultResult
    }
}
