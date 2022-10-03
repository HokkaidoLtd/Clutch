//
//  LSApplicationProxy.swift
//  Clutch
//
//  Created by Anton Titkov on 19/10/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

import Foundation

extension LSBundleProxy {
	var bundleExecutableURL: URL {
		bundleURL.appendingPathComponent(bundleExecutable)
	}
}

extension LSApplicationProxy {
	var frameworksURL: URL? {
		let url = bundleURL.appendingPathComponent("Frameworks")
		if FileManager.default.isDirectory(url: url) {
			return url
		}
		return nil
	}
	
	var frameworks: [URL] {
		guard
			let url = frameworksURL,
			let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
		else {
			return []
		}
		
		return contents
	}
	
	convenience init?(withAppIdentifier appId: String) {
		self.init(forIdentifier: appId)
		
		if !isInstalled {
			return nil
		}
	}
}
