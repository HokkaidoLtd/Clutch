//
//  ApplicationManager.swift
//  Clutch
//
//  Created by NinjaLikesCheez on 19/10/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

import Foundation

struct AppManager {
	public let apps: [LSApplicationProxy]

	enum Error: Swift.Error {
		case invalidIndex(String)
		case noAppsFound
	}

	init() {
		self.apps = LSApplicationWorkspace.default()
			.applications(of: Type.User)
			.sorted(by: { $0.localizedName.lowercased() < $1.localizedName.lowercased() })
	}

//	public func lookup(term: String) throws -> LSApplicationProxy {
//		if let app = LSApplicationProxy(withAppIdentifier: term) {
//			return app
//		}
//
//		throw Error.invalidIndex("Failed to lookup term: \(term)")
//	}

	public func lookup(terms: [String]) throws -> [LSApplicationProxy] {
		var results = [LSApplicationProxy]()
		for term in terms {
			if let index = Int(term) {
				results.append(try app(forIndex: index))
			} else {
				results.append(contentsOf: app(forTerm: String(term)))
			}
		}

		if results.count == 0 {
			throw Error.noAppsFound
		}

		return results
	}

	private func app(forIndex index: Int) throws -> LSApplicationProxy {
		guard apps.indices.contains(index) else {
			throw Error.invalidIndex("Expected index between 0 and \(apps.count - 1). Got \(index)")
		}

		return apps[index]
	}

	private func app(forTerm token: String) -> [LSApplicationProxy] {
		let predicate = NSPredicate(format: "SELF.applicationIdentifier CONTAINS[c] %@", token)
		return (apps as NSArray).filtered(using: predicate) as? [LSApplicationProxy] ?? []
	}
}
