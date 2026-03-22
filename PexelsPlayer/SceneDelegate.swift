import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var compositionRoot: CompositionRoot!
    private var deeplinkHandler: DeeplinkHandler!

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        compositionRoot = CompositionRoot()
        compositionRoot.appConfigurator.configure()
        let rootVC = compositionRoot.assembleAndStart()

        window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .dark
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()

        deeplinkHandler = compositionRoot.makeDeeplinkHandler()

        if let urlContext = connectionOptions.urlContexts.first {
            _ = deeplinkHandler.handle(url: urlContext.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        _ = deeplinkHandler?.handle(url: url)
    }
}
