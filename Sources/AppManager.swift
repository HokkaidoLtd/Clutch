//
//  ApplicationManager.swift
//  Clutch
//
//  Created by NinjaLikesCheez on 19/10/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

import Foundation
import PrivateMobileCoreServices

struct AppManager {
	let apps: [LSApplicationProxy]

	enum Error: Swift.Error {
		case invalidIndex(String)
		case noAppsFound
	}

	init() {
		self.apps = LSApplicationWorkspace.default()
			.applications(of: Type.User)
			.sorted(by: { $0.localizedName.lowercased() < $1.localizedName.lowercased() })
	}

	func lookup(terms: [String]) throws -> [LSApplicationProxy] {
		let results = try terms
			.flatMap { term in
				return if let index = Int(term) {
					[try app(for: index)]
				} else {
					app(for: term)
				}
			}

		guard !results.isEmpty else {
			throw Error.noAppsFound
		}

		return results
	}

	private func app(for index: Int) throws -> LSApplicationProxy {
		guard apps.indices.contains(index) else {
			throw Error.invalidIndex("Expected index between 0 and \(apps.count - 1). Got \(index)")
		}

		return apps[index]
	}

	private func app(for token: String) -> [LSApplicationProxy] {
		apps.filter {
			$0.applicationIdentifier.lowercased().contains(token.lowercased())
		}
	}
}
