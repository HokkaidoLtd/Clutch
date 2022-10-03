//
//  ARM64Dumper.swift
//  Clutch
//
//  Created by NinjaLikesCheez on 29/09/2021.
//  Copyright © 2021 Kim-Jong Cracks. All rights reserved.
//

import Foundation
import CryptoKit

struct ARM64Dumper: Dumper {
	struct WorkingDirectoryPaths {
		let workingDirectory: URL
		let workingExecutable: URL
		let workingSCInfo: URL
	}
	
	let executable: Executable
	
	init(_ executable: Executable) {
		self.executable = executable
	}
	
	func dump(to destination: URL = URL(fileURLWithPath: "/private/var/mobile/Documents/Dumped")) throws {
		try preflight()
		let arch = executable.arch
		
		let outputPath = destination.appendingPathComponent(executable.executableURL.lastPathComponent)
		try create(folder: destination)
		
		Logger.info("Dumping \(Executable.readable(arch: arch).1) from \(executable.executableURL.lastPathComponent)")
		
		let commands = executable.commands
		let codeDirectory = executable.codeSignatureDirectory
		
		let pid = executable.spawn(disableASLR: true, suspend: true)
		defer { kill(pid, 9) }
		
		let slide = getSlide(for: pid) ?? commands.text.command.vmaddr
		var port: mach_port_t = 0   // mach port used for moving virtual memory
		let err = task_for_pid(mach_task_self_, pid, &port)
		
		if err != KERN_SUCCESS {
			Logger.error("tfp0 failed, either the process is dead, you're using a crap jailbreak, or you've not codesigned Clutch correctly.")
			throw DumperError.failed("tfp0 failed, either the process is dead, you're using a crap jailbreak, or you've not codesigned Clutch correctly.")
		}
		
		Logger.debug("Got port for pid: \(port)")
		
		// TODO: since this dumps the whole binary, we need to adjust to only dump the __TEXT encrypted contents
		var buffer = Data()
		try dump(
			to: &buffer,
			size: UInt32(executable.data.count - 1), //commands.crypt.command.cryptoff + commands.crypt.command.cryptsize,
			pages: codeDirectory.directory.nCodeSlots,
			port: port,
			slide: slide
		)

		Logger.info("Patching cryptid")
		let cryptIDOffset = commands.crypt.offset + (MemoryLayout.size(ofValue: commands.crypt.command.cmd) * 4) // points to cryptid
		buffer[cryptIDOffset] = 0

		Logger.info("Writing binary to: \(outputPath.path), size: \(buffer.count)")
		Logger.debug("original binary size: \(executable.data.count)")
		do {
			try buffer.write(to: outputPath)
		} catch {
			throw DumperError.filesystemError("Failed to write buffer: \(error)")
		}
	}
	
	private func getSlide(for pid: pid_t) -> mach_vm_address_t? {
		guard executable.arch.isPIEEnabled else { return nil }
		
		Logger.info("Getting slide for pid: \(pid)")
		
		return ASLRDisabler.slide(forPID: pid)
	}
	
	private func dump(to buffer: inout Data, size: UInt32, pages: UInt32, port: mach_port_t, slide: mach_vm_address_t) throws {
		Logger.debug("Beginning dump")
		Logger.debug("buffer: \(buffer), size: \(size), pages: \(pages), port: \(port), slide: \(slide)")
		
		var pagesProcessed = 0
		var pageBuffer = Array<UInt8>(repeating: 0, count: 0x1000) // TODO: use 16kb page buffer here
		var bytesRead: mach_vm_size_t = 0
		// TODO: checksum?
//		var checksum = malloc(Int(pages) * 20);
		var size = size
		
		Logger.debug("slide start: \(slide.hexString)")
		
		while size > 0 {
			let kernelReturn = pageBuffer.withUnsafeMutableBufferPointer { bufferPointer -> kern_return_t in
				let address = slide + UInt64(pagesProcessed * 0x1000)

				let readSize = size >= 0x1000 ? mach_vm_size_t(0x1000) : mach_vm_size_t(size)
				
				return mach_vm_read_overwrite(
					port,
					mach_vm_address_t(address),
					readSize,
					mach_vm_address_t(bufferPointer.baseAddress),
					&bytesRead
				)
			}

			if kernelReturn != KERN_SUCCESS {
				Logger.error("Failed to dump a page :( error: \(kernelReturn)")
				throw DumperError.dumpingFailed("Failed to dump a page :( kr: \(kernelReturn)")
			}
			
			buffer.append(contentsOf: pageBuffer)
			//			Logger.debug("buffer size: \(buffer.count) - total size: \(executable.data.count), left: \(size)")

			size -= UInt32(bytesRead)
			pagesProcessed += 1
		}
	}
}

// MARK: File system helpers
extension ARM64Dumper {
	private func create(folder: URL) throws {
		do {
			try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
		} catch {
			throw DumperError.filesystemError("Failed to create path: \(error)")
		}
	}
}
