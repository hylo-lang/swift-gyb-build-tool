import PackagePlugin

/// Maps the output filename's extension onto the Python line directive format to use.
let lineDirectiveForOutputExtension: [ Substring: String] = [
  ".swift": #"#sourceLocation(file: "%(file)s", line: %(line)d)"#,
  ".hylo": "#file \"%(file)s\"\n#line %(line)d",
]

@main
struct GybBuildPlugin: BuildToolPlugin {

  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    guard let target = target as? SwiftSourceModuleTarget else { return [] }
    let sourcePaths = try target.sourceFiles(withSuffix: ".gyb").map(\.path)

    let r = try sourcePaths.map { gybFile in
      let outputBaseName = gybFile.lastComponent.dropLast(4)
      let dotPositionOrEnd = outputBaseName.lastIndex(of: ".") ?? outputBaseName.endIndex
      let lineDirectiveFormat = lineDirectiveForOutputExtension[outputBaseName[dotPositionOrEnd...]] ?? ""
      let outputFile = context.pluginWorkDirectory.appending(String(outputBaseName))

      return Command.buildCommand(
        displayName: "Generating \(outputBaseName) from \(gybFile.lastComponent)",
        executable: try context.tool(named: "gyb-swift").path,
        arguments: target.compilationConditions.flatMap { ["-D", "\($0)=1"] } + [
          "--line-directive", lineDirectiveFormat,
          "-o", outputFile,
          gybFile,
        ],
        inputFiles: [gybFile],
        outputFiles: [outputFile])
    }

    return r
  }

}
