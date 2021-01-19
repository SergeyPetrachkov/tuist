import Foundation
import ProjectDescription
import TSCBasic
import TuistGraph
import TuistSupport

/// Entity responsible for providing dependencies model
public protocol DependenciesModelLoading {
    /// Load array of Carthage Dependency models at the specified path.
    /// - Parameters:
    ///     - path: The absolute path for the dependency models to load.
    ///     - plugins: The plugins to use while loading this manifest.
    /// - Returns: The Dependencies loaded from the specified path.
    /// - Throws: Error encountered during the loading process (e.g. Missing Dependencies file).
    func loadDependencies(at path: AbsolutePath, plugins: Plugins) throws -> TuistGraph.Dependencies
}

public class DependenciesModelLoader: DependenciesModelLoading {
    private let manifestLoader: ManifestLoading

    public init(manifestLoader: ManifestLoading = ManifestLoader()) {
        self.manifestLoader = manifestLoader
    }

    public func loadDependencies(at path: AbsolutePath, plugins: Plugins) throws -> TuistGraph.Dependencies {
        let manifest = try manifestLoader.loadDependencies(at: path, plugins: plugins)
        return try TuistGraph.Dependencies.from(manifest: manifest)
    }
}
