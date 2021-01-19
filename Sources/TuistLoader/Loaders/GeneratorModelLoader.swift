import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistGraph
import TuistSupport

public class GeneratorModelLoader {
    private let manifestLoader: ManifestLoading
    private let manifestLinter: ManifestLinting
    private let rootDirectoryLocator: RootDirectoryLocating

    public convenience init(manifestLoader: ManifestLoading,
                            manifestLinter: ManifestLinting)
    {
        self.init(manifestLoader: manifestLoader,
                  manifestLinter: manifestLinter,
                  rootDirectoryLocator: RootDirectoryLocator())
    }

    init(manifestLoader: ManifestLoading,
         manifestLinter: ManifestLinting,
         rootDirectoryLocator: RootDirectoryLocating)
    {
        self.manifestLoader = manifestLoader
        self.manifestLinter = manifestLinter
        self.rootDirectoryLocator = rootDirectoryLocator
    }
}

extension GeneratorModelLoader: GeneratorModelLoading {
    /// Load a Project model at the specified path
    ///
    /// - Parameters:
    ///   - path: The absolute path for the project model to load.
    ///   - plugins: The plugins to use while loading the project.
    /// - Returns: The Project loaded from the specified path
    /// - Throws: Error encountered during the loading process (e.g. Missing project)
    public func loadProject(at path: AbsolutePath, plugins: Plugins) throws -> TuistGraph.Project {
        let manifest = try manifestLoader.loadProject(at: path, plugins: plugins)
        try manifestLinter.lint(project: manifest).printAndThrowIfNeeded()
        return try convert(manifest: manifest, path: path)
    }

    public func loadWorkspace(at path: AbsolutePath, plugins: Plugins) throws -> TuistGraph.Workspace {
        let manifest = try manifestLoader.loadWorkspace(at: path, plugins: plugins)
        return try convert(manifest: manifest, path: path)
    }

    public func loadConfig(at path: AbsolutePath) throws -> TuistGraph.Config {
        // If the Config.swift file exists in the root Tuist/ directory, we load it from there
        if let rootDirectoryPath = rootDirectoryLocator.locate(from: path) {
            let configPath = rootDirectoryPath.appending(RelativePath("\(Constants.tuistDirectoryName)/\(Manifest.config.fileName(path))"))

            if FileHandler.shared.exists(configPath) {
                let manifest = try manifestLoader.loadConfig(at: configPath.parentDirectory)
                return try convert(manifest: manifest, path: configPath)
            }
        }

        // We first try to load the deprecated file. If it doesn't exist, we load the new file name.
        let fileNames = [Manifest.config]
            .flatMap { [$0.deprecatedFileName, $0.fileName(path)] }
            .compactMap { $0 }

        for fileName in fileNames {
            guard let configPath = FileHandler.shared.locateDirectoryTraversingParents(from: path, path: fileName) else {
                continue
            }
            let manifest = try manifestLoader.loadConfig(at: configPath.parentDirectory)
            return try convert(manifest: manifest, path: configPath)
        }

        return TuistGraph.Config.default
    }

    public func loadPlugin(at path: AbsolutePath) throws -> TuistGraph.Plugin {
        let plugin = try manifestLoader.loadPlugin(at: path)
        return try convert(manifest: plugin)
    }
}

extension GeneratorModelLoader: ManifestModelConverting {
    public func convert(manifest: ProjectDescription.Project, path: AbsolutePath) throws -> TuistGraph.Project {
        let generatorPaths = GeneratorPaths(manifestDirectory: path)
        return try TuistGraph.Project.from(manifest: manifest, generatorPaths: generatorPaths)
    }

    public func convert(manifest: ProjectDescription.Workspace, path: AbsolutePath) throws -> TuistGraph.Workspace {
        let generatorPaths = GeneratorPaths(manifestDirectory: path)
        let workspace = try TuistGraph.Workspace.from(manifest: manifest,
                                                      path: path,
                                                      generatorPaths: generatorPaths,
                                                      manifestLoader: manifestLoader)
        return workspace
    }

    public func convert(manifest: ProjectDescription.Config, path: AbsolutePath) throws -> TuistGraph.Config {
        try TuistGraph.Config.from(manifest: manifest, at: path)
    }

    public func convert(manifest: ProjectDescription.Plugin) throws -> TuistGraph.Plugin {
        try TuistGraph.Plugin.from(manifest: manifest)
    }
}
