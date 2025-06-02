//
//  File.swift
//  
//
//  Created by CodeBuilder on 22/09/2024.
//

import Foundation
import PySwiftKit
import PySwiftObject
import PySerializing
import PyUnpack
import PySwiftWrapper

@PyClass(bases: [.buffer])
class PixelContainer: PySerialize, PyTypeBufferProtocol {
	let data: UnsafeMutablePointer<UInt8>
	//let width: Int
	//let height: Int
	let capacity: Int
	
	init(capacity: Int) {
		//let size = width * height * numberOfComponents
		let data = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
		data.initialize(repeating: 0, count: capacity)
		
		self.data = data
//		self.width = width
//		self.height = height
		self.capacity = capacity
	}
	deinit {
        data.deallocate()
	}
	
    static func buffer_procs() -> UnsafeMutablePointer<PyBufferProcs> {
        .init(&PyBuffer)
    }
    
	static var PyBuffer: PyBufferProcs = .init(
		bf_getbuffer: { s, buffer, rw in
			let cls: PixelContainer = UnPackPyPointer(from: s)
//			return PyBuffer_FillInfo(
//				buffer,
//				s,
//				cls.data,
//				cls.capacity,
//				0,
//				rw
//			)
            var itemsize = 1
            var size = cls.capacity
           // cls.data.fill_info(buffer: buffer!, size: &size, itemsize: &itemsize)
            
            return 0
		},
		bf_releasebuffer: nil
	)
	
	var pyPointer: PyPointer { Self.asPyPointer(self) }
}
