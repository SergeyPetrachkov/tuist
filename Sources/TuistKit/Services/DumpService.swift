import Foundation
import TSCBasic
import TuistLoader
import TuistPlugin
import TuistSupport

final class DumpService {
    private let manifestLoader: ManifestLoading
    private let pluginService: PluginServicing

    init(
        manifestLoader: ManifestLoading = ManifestLoader(),
        pluginService: PluginServicing = PluginService()
    ) {
        self.manifestLoader = manifestLoader
        self.pluginService = pluginService
    }

    func run(path: String?) throws {
        let projectPath: AbsolutePath
        if let path = path {
            projectPath = AbsolutePath(path, relativeTo: AbsolutePath.current)
        } else {
            projectPath = AbsolutePath.current
        }

        let plugins = try pluginService.loadPlugins(at: projectPath)
        let project = try manifestLoader.loadProject(at: projectPath, plugins: plugins)
        let json: JSON = try project.toJSON()
        logger.notice("\(json.toString(prettyPrint: true))")
    }
}
