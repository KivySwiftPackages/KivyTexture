// The Swift Programming Language
// https://docs.swift.org/swift-book

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

import CoreGraphics


import PySwiftKit

import PyCallable
import PyUnpack
import PySerializing
import PySwiftWrapper

fileprivate extension PyPointer {
    func callAsFunction<A>(_ a: A) throws -> PyPointer where A: PySerialize {
        let arg = a.pyPointer
        guard let result = PyObject_CallOneArg(self, arg) else {
            PyErr_Print()
            Py_DecRef(arg)
            throw PythonError.call
        }
        Py_DecRef(arg)
        
        return result
    }
}



private func load_kivy_texture() -> PyPointer {
	let code = """
from kivy.graphics.texture import Texture
from kivy.graphics.texture import texture_create
"""
	let dict = PyDict_New()!
	
	if let result = PyRun_String(code, Py_file_input, dict, dict) {
		result.decref()
	} else {
		PyErr_Print()
	}
	
	return dict
}
private let kv_tex_funcs = {
	let dict = load_kivy_texture()
	let funcs = try! [String:PyPointer](object: dict)
	return funcs
}()


extension UnsafeMutablePointer where Pointee == UInt8 {
	
	static func new(_ capacity: Int) -> Self {
		let ptr = Self.allocate(capacity: capacity)
		ptr.initialize(repeating: 0, count: capacity)
		return ptr
	}
}

func cgPixels(imageRef: CGImage) -> (UnsafeMutablePointer<UInt8>, Int) {

	let wh = imageRef
	let width = wh.width
	let height = wh.height
	let bytesPerRow = width * 4
	
	let size = bytesPerRow * height
	let colorSpace = CGColorSpaceCreateDeviceRGB()
	//var colorSpace: CGColorSpace = .init(name: CGColorSpace.sRGB)!
	
	//let pixels = PixelContainer(capacity: size)
	let pixels = UnsafeMutablePointer<UInt8>.new(size)
	let bounds = CGRect(x: 0, y: 0, width: width, height: height)
	
	let context = CGContext(
		data: pixels,
		width: width,
		height: height,
		bitsPerComponent: 8,
		bytesPerRow: bytesPerRow,
		space: colorSpace,
		bitmapInfo:
			CGImageAlphaInfo.premultipliedLast.rawValue
		
	)!

	context.setFillColor( .init(gray: 1, alpha: 1) )
	context.translateBy(x: 0, y: CGFloat(height))
	context.scaleBy(x: 1, y: -1)
	context.clip(to: bounds, mask: imageRef)
	
	
	context.fill(bounds)

	
	return (pixels, size)
}


public protocol KivyTextureProtocol {
	func texture() -> PyPointer
}


public struct KivyTexture: PySerialize {
	
	static private let _texture_create = kv_tex_funcs["texture_create"]!
	static let rgba = "rgba".pyPointer
	static let create_kv_args = [
		"color_fmt": "rgba"
	].pyPointer
	static let blit_string = "blit_buffer".pyPointer
	
	public let data: PyPointer
	
	public init(width: Int, height: Int) {
        data = Self.texture_create(width: width, height: height)
	}
	
    
    
	public init(cg: CGImage) {
		
		
        let tex = Self.texture_create(size: [cg.width, cg.height])
        
		var (pixels, size) = cgPixels(imageRef: cg)
        var item_size = 1
		var py_buffer = Py_buffer()
        
        _ = pixels.fill_info(buffer: &py_buffer, size: &size, itemsize: &item_size)

		let mem_view = PyMemoryView_FromBuffer(&py_buffer)

        PyObject_VectorcallMethod(Self.blit_string, [tex, mem_view, Py_None, Self.rgba], 4, nil)

		mem_view?.decref()
		PyBuffer_Release(&py_buffer)
		pixels.deallocate()
		
		data = tex
	}
	
	public init(pixels: PyPointer, width: Int, height: Int) {
		
        let tex = Self.texture_create(size: [width, height])
        PyObject_VectorcallMethod(Self.blit_string, [tex, pixels, Py_None, Self.rgba], 4, nil)
		
        data = tex
	}
	
	
    
    public var pyPointer: PyPointer { data }
}

func PyListNew(_ a: PyPointer, _ b: PyPointer) -> PyPointer {
    let new = PyList_New(2)!
    
    new.withMemoryRebound(to: PyListObject.self, capacity: 1) { pointer in
        let ob_item = pointer.pointee.ob_item!
        //normally PyList_SET_ITEM(ob, 0, a)
        ob_item[0] = a
        //normally PyList_SET_ITEM(ob, 1, b)
        ob_item[1] = b
    }
    return new
}

extension KivyTexture {
    
    static func texture_create(width: Int, height: Int, color_fmt: String? = nil) -> PyPointer {
        @PyCall
        func texture_create(size: [Int], color_fmt: PyPointer) -> PyPointer
        return texture_create(size: [width, height], color_fmt: Self.rgba)
    }
    
    @PyCall
    static func texture_create(size: [Int], color_fmt: String = "rgba") -> PyPointer
    
    public static func create(pixels: PyPointer, width: Int, height: Int) -> PyPointer {
        Self.init(pixels: pixels, width: width, height: height).data
    }
    
}

extension CGImage: KivyTextureProtocol {
	public func texture() -> PyPointer {
		return KivyTexture(cg: self).data
	}
}
#if os(iOS)
extension UIImage: KivyTextureProtocol {
	public func texture() -> PyPointer {
		if let cg = cgImage {
			return cg.texture()
		}
		return .None
	}
}
#endif
