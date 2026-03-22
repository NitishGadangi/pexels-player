//
//  DeeplinkManager.swift
//  PexelsPlayer
//
//  Created by Nitish Gadangi on 3/22/26.
//

import Foundation
import SharedRouterInterface

final class DeeplinkManager {
    private weak var router: SharedRouterProtocol?

    init(router: SharedRouterProtocol) {
        self.router = router
    }

    func handle(url: URL) -> Bool {
        guard url.scheme == "pexelsplayer" else { return false }

        switch url.host {
        case "video":
            if let indexStr = url.pathComponents.last, let index = Int(indexStr) {
                router?.navigate(to: .videoFeed(startIndex: index), style: .push)
                return true
            }
        default:
            break
        }
        return false
    }
}
