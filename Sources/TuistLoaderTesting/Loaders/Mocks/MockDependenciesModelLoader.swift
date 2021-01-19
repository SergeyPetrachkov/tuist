import TSCBasic
import TuistGraph
import TuistSupport

@testable import TuistLoader

public class MockDependenciesModelLoader: DependenciesModelLoading {
    public init() {}

    var invokedLoadDependencies = false
    var invokedLoadDependenciesCount = 0
    var invokedLoadDependenciesParametersPath = [AbsolutePath]()
    var invokedLoadDependenciesParametersPlugins = [Plugins]()
    var loadDependenciesStub: ((AbsolutePath) throws -> Dependencies)?

    public func loadDependencies(at path: AbsolutePath, plugins: Plugins) throws -> Dependencies {
        invokedLoadDependencies = true
        invokedLoadDependenciesCount += 1
        invokedLoadDependenciesParametersPath.append(path)
        invokedLoadDependenciesParametersPlugins.append(plugins)

        if let stub = loadDependenciesStub {
            return try stub(path)
        } else {
            return Dependencies(carthageDependencies: [])
        }
    }
}
