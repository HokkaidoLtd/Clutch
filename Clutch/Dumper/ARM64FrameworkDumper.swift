//
//  ARM64FrameworkDumper.swift
//  Clutch
//
//  Created by NinjaLikesCheez on 29/09/2021.
//  Copyright © 2021 Kim-Jong Cracks. All rights reserved.
//

import Foundation
import MachO.loader

// TODO: TEST THE FUCK OUTTA ALL OF THIS
struct ARM64FrameworkDumper: Dumper {
	let executable: Executable

	enum Error: Swift.Error {
		case failedToFindImageHeader
		case failedToAllocate
	}
	
	init(_ executable: Executable) {
		self.executable = executable
	}
	
	func dump(to destination: URL = URL(fileURLWithPath: "/private/var/mobile/Documents/Dumped")) throws {
		try preflight()
		try create(folder: destination)
		
		Logger.info("Dumping \(Executable.readable(arch: executable.arch).1) from \(executable.executableURL.lastPathComponent)")
		
		let imageCount = _dyld_image_count()
		var foundIndex = false
		var dyldIndex: UInt32 = 0
		
		Logger.debug("dyld image count: \(imageCount)")
		
		for idx in 0...imageCount {
			guard let namePointer = _dyld_get_image_name(idx) else { continue }
			
			let path = String(cString: namePointer)
			if path.hasSuffix(executable.executableURL.lastPathComponent) {
				Logger.debug("Found image path at index: \(idx)")
				dyldIndex = idx
				foundIndex = true;
				break
			}
		}
		
		guard foundIndex else {
			throw DumperError.failed("Failed to find an image for name: \(executable.executableURL.lastPathComponent)")
		}
		
		let slide: mach_vm_address_t = UInt64(_dyld_get_image_vmaddr_slide(dyldIndex))
		Logger.debug("got slide: \(slide.hexString)")
		
		let commands = executable.commands

		Logger.debug("code pages: \(executable.codeSignatureDirectory.directory.nCodeSlots)")
		
		// TODO: there is currently a bug where we miss multiple bytes in file :( Fix this plz
//		var buffer = Data(capacity: executable.data.count - 1)
//		try dump(
//			to: &buffer,
//			from: dyldIndex,
//			size: UInt32(executable.data.count - 1),
//			pages: executable.codeSignatureDirectory.directory.nCodeSlots
//		)
		var buffer = FrameworkDumper.dump(
			from: dyldIndex,
			totalSize: UInt32(executable.data.count - 1),//commands.crypt.command.cryptoff + commands.crypt.command.cryptsize,
			totalPages: executable.codeSignatureDirectory.directory.nCodeSlots,
			fromAddress: slide
		)
		
//		var binary = executable.data
//		let dataStart = executable.arch.offset
//		let dataEnd = dataStart + buffer.count + 1
//
//		Logger.debug("replacing range: \(dataStart.hexString)...\(dataEnd.hexString) with buffer of size: \(buffer.count)")
//		binary.replaceSubrange(dataStart...dataEnd, with: buffer)
		
		// Patch cryptid
		Logger.info("Patching cryptid")
		let cryptIDOffset = commands.crypt.offset + (MemoryLayout.size(ofValue: commands.crypt.command.cmd) * 4) // points to cryptid
//		binary[cryptIDStart] = 0
		buffer[cryptIDOffset] = 0
		
		let outputPath = destination.appendingPathComponent(executable.executableURL.lastPathComponent)
		
		Logger.info("Writing binary to: \(outputPath.path), size: \(buffer.count)")
		Logger.debug("original binary size: \(executable.data.count)")
		do {
//			try binary.write(to: outputPath)
			try buffer.write(to: outputPath)
		} catch {
			throw DumperError.filesystemError("Failed to write buffer: \(error)")
		}
	}

	private func dump(to buffer: inout Data, from index: UInt32, size: UInt32, pages: UInt32) throws {
		guard let header = _dyld_get_image_header(index) else {
			throw Error.failedToFindImageHeader
		}
		print("header: \(header.pointee) at offset: \(header)")

		var pagesProcessed = 0
		var size = size

		while size > 0 {
			let remaining = Int(size >= 0x1000 ? 0x1000 : size)
			let src = header + (pagesProcessed * 0x1000)
			guard let tempBuffer = malloc(remaining) else {
				throw Error.failedToAllocate
			}
			// TODO: src is potentially a bad ptr after some iterations?
			Logger.debug("ptr: \(tempBuffer), src: \(src), remaining: \(remaining)")
			memcpy(tempBuffer, src, remaining)

			let data = Data(bytes: tempBuffer, count: remaining)
			buffer.append(data)

			Logger.debug("buffer size: \(buffer.count)")
			print((buffer as NSData).description)

			free(tempBuffer)

			size -= UInt32(remaining)
			pagesProcessed += 1
		}

//		free(tempBuffer)
	}
}

struct FrameworkLoader {
	private let application: LSApplicationProxy
	private let frameworks: [URL]
	private let dylibs: [URL]
	
	init(_ application: LSApplicationProxy) {
		self.application = application
		self.frameworks = application.frameworks.filter({ $0.pathExtension == "framework" })
		self.dylibs = application.frameworks.filter({ $0.pathExtension == "dylib" })
	}
	
	func loadAll() {
		loadAllFrameworks()
		loadAllDylibs()
	}
	
	private func loadAllFrameworks() {
		Logger.info("Attempting to load all frameworks")
		var bundles = frameworks.compactMap { Bundle.init(url: $0) }
		
		var recursionGuard = 25
		while !bundles.isEmpty && recursionGuard > 0 {
			Logger.debug("bundles left to load: \(bundles.count)")
			_ = bundles.map { $0.load() }
			bundles.removeAll(where: { $0.isLoaded })
			recursionGuard -= 1
		}
	}
	
	private func loadAllDylibs() {
		Logger.info("Attempting to load all dylibs")
		dylibs.forEach { lib in
			lib.path.withCString { path in
				if dlopen(path, 9) == nil {
					Logger.error("Failed to dlopen a library: \(String(cString: dlerror()!))")
				} else {
					Logger.info("WINNING")
				}
			}
		}
		
	}
}
