//
//  CompositionRoot.swift
//  PexelsPlayer
//
//  Created by Nitish Gadangi on 3/22/26.
//

import UIKit
import NetworkLib
import LoggingLib
import SharedRouterInterface
import SharedRouter
import Home
import VideoFeed
import SavedItems

final class CompositionRoot {
    private var router: SharedRouter?

    func buildRootViewController() -> UIViewController {
        let networkService = URLSessionNetworkService()
        networkService.configure(with: NetworkConfiguration(
            timeoutInterval: 30,
            logRequests: true,
            logResponses: true
        ))

        let lazyRouter = LazyRouter()

        let homeCoordinator = HomeCoordinator(
            networkService: networkService,
            lazyRouter: lazyRouter
        )

        let videoFeedCoordinator = VideoFeedCoordinator(lazyRouter: lazyRouter)
        let savedItemsCoordinator = SavedItemsCoordinator()

        let homeVC = homeCoordinator.build()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let savedVC = savedItemsCoordinator.build()
        let savedNav = UINavigationController(rootViewController: savedVC)
        savedNav.tabBarItem = UITabBarItem(
            title: "Saved",
            image: UIImage(systemName: "bookmark"),
            selectedImage: UIImage(systemName: "bookmark.fill")
        )

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeNav, savedNav]

        let sharedRouter = SharedRouter(
            navigationController: homeNav,
            homeBuilder: homeCoordinator,
            videoFeedBuilder: videoFeedCoordinator,
            savedItemsBuilder: savedItemsCoordinator
        )
        lazyRouter.router = sharedRouter
        self.router = sharedRouter

        return tabBarController
    }
}
