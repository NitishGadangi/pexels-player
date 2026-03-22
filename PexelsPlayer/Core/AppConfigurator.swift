import UIKit
import UIComponents

final class AppConfigurator {

    func configure() {
        configureNavBar()
        configureTabBar()
    }

    private func configureNavBar() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: AppTheme.primaryText]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: AppTheme.primaryText]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = AppTheme.primaryText
    }

    private func configureTabBar() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = AppTheme.tabBar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().unselectedItemTintColor = AppTheme.secondary
    }
}
