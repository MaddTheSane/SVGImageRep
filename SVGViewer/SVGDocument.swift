//
//  SVGDocument.swift
//  SVGImageRep
//
//  Created by C.W. Betts on 8/17/16.
//
//

import Cocoa

class SVGView : NSView {
	var renderContext: SVGRenderContext? {
		didSet {
			self.needsDisplay = true
		}
	}
	
	override var opaque: Bool {
		return true
	}
	
	override func drawRect(dirtyRect: NSRect) {
		if let tempRef = NSGraphicsContext.currentContext()?.CGContext, svg = renderContext {
			let svgSize = svg.size
			CGContextSetGrayFillColor(tempRef, 1.0, 1.0);
			CGContextFillRect(tempRef, CGRect(origin: .zero, size: svgSize))
			CGContextDrawLayerInRect(tempRef, CGRect(origin: .zero, size: svgSize), svg.renderLayer);
		}
	}
}

class SVGDocument: NSDocument {
	@NSCopying private var documentData: NSData!

	@IBOutlet weak var svgView: SVGView!
	@IBOutlet weak var minXConstraint: NSLayoutConstraint!
	@IBOutlet weak var minYConstraint: NSLayoutConstraint!
	
	var scale = 0.0
	
	@IBAction func reload(sender: AnyObject?) {
		var svg: COpaquePointer = nil
		svg_create(&svg)
		defer {
			svg_destroy(svg)
		}
		var status = SVG_STATUS_SUCCESS
		if let fileURL = fileURL {
			status = svg_parse(svg, fileURL.fileSystemRepresentation)
		} else {
			status = svg_parse_buffer(svg, UnsafePointer<Int8>(documentData.bytes), documentData.length);

		}
		if status != SVG_STATUS_SUCCESS {
			return
		}
		
		let scaledRect: NSRect = {
			var tmpRect = NSRect.zero
			var height = svg_length_t()
			var width = svg_length_t()
			svg_get_size(svg, &width, &height)
			tmpRect.size = NSSize(width: SVGRenderContext.lengthToPoints(&width) * scale, height: SVGRenderContext.lengthToPoints(&height) * scale)
			return tmpRect
		}()
		let svg_render_context = SVGRenderContext()
		
		autoreleasepool { 
			svg_render_context.prepareRender(scale)
			//Because Swift can be too strict about consts
			var tmpEngine = cocoa_svg_engine
			status = svg_render(svg, &tmpEngine, UnsafeMutablePointer<Void>(Unmanaged.passUnretained(svg_render_context).toOpaque()))
			svg_render_context.finishRender()
		}
		
		if status != SVG_STATUS_SUCCESS {
			return;
		}
		
		minXConstraint.constant = scaledRect.size.width;
		minYConstraint.constant = scaledRect.size.height;
		svgView.frame = scaledRect
		svgView.renderContext = svg_render_context
	}
	
	override var windowNibName: String? {
		return "SVGDocument"
	}
	
	override func windowControllerDidLoadNib(windowController: NSWindowController) {
		super.windowControllerDidLoadNib(windowController)
		reload(nil)
	}
	
	override func readFromURL(url: NSURL, ofType typeName: String) throws {
		var svg: COpaquePointer = nil
		svg_create(&svg);
		defer {
			svg_destroy(svg);
		}
		
		let status = svg_parse(svg, url.fileSystemRepresentation);
		if status != SVG_STATUS_SUCCESS {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
		}
		documentData = NSData(contentsOfURL: url)
	}
	
	override func readFromData(data: NSData, ofType typeName: String) throws {
		var svg: COpaquePointer = nil
		svg_create(&svg);
		defer {
			svg_destroy(svg);
		}

		let status = svg_parse_buffer(svg, UnsafePointer<Int8>(data.bytes), data.length);
		if status != SVG_STATUS_SUCCESS {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
		}
		documentData = data;
	}
	
	
	
	@IBAction func scale_0_1(sender: AnyObject!) {
		scale = 0.1
		reload(nil)
	}
	@IBAction func scale_0_25(sender: AnyObject!) {
		scale = 0.25
		reload(nil)
	}
	@IBAction func scale_0_5(sender: AnyObject!) {
		scale = 0.5
		reload(nil)
	}
	@IBAction func scale_0_75(sender: AnyObject!) {
		scale = 0.75
		reload(nil)
	}
	@IBAction func scale_1_0(sender: AnyObject!) {
		scale = 1
		reload(nil)
	}
	@IBAction func scale_1_5(sender: AnyObject!) {
		scale = 1.5
		reload(nil)
	}
	@IBAction func scale_2_0(sender: AnyObject!) {
		scale = 2
		reload(nil)
	}
	@IBAction func scale_3_0(sender: AnyObject!) {
		scale = 3
		reload(nil)
	}
	@IBAction func scale_4_0(sender: AnyObject!) {
		scale = 4
		reload(nil)
	}
	@IBAction func scale_5_0(sender: AnyObject!) {
		scale = 5
		reload(nil)
	}
}
