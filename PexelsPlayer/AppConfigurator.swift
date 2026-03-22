//
//  AppConfigurator.swift
//  PexelsPlayer
//
//  Created by Nitish Gadangi on 3/22/26.
//

import UIKit
import UIComponents

final class AppConfigurator {
    func configure() {
        configureAppearance()
    }

    private func configureAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: AppTheme.primaryText]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: AppTheme.primaryText]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = AppTheme.primaryText

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = AppTheme.tabBar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().unselectedItemTintColor = AppTheme.secondary
    }
}
