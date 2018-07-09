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
	
	override var isOpaque: Bool {
		return true
	}
	
	override func draw(_ dirtyRect: NSRect) {
		if let tempRef = NSGraphicsContext.current?.cgContext, let svg = renderContext {
			let svgSize = svg.size
			tempRef.setFillColor(gray: 1.0, alpha: 1.0)
			tempRef.fill(CGRect(origin: .zero, size: svgSize))
			tempRef.draw(svg.renderLayer, in: CGRect(origin: .zero, size: svgSize))
		}
	}
}

class SVGDocument: NSDocument {
	private var documentData: Data!

	@IBOutlet weak var svgView: SVGView!
	@IBOutlet weak var minXConstraint: NSLayoutConstraint!
	@IBOutlet weak var minYConstraint: NSLayoutConstraint!
	
	private var scale = 1.0
	
	@IBAction func reload(_ sender: AnyObject?) {
		var svg: OpaquePointer? = nil
		svg_create(&svg)
		defer {
			svg_destroy(svg)
		}
		var status = SVG_STATUS_SUCCESS
		if let fileURL = fileURL {
			status = fileURL.withUnsafeFileSystemRepresentation({ (path) -> svg_status_t in
				return svg_parse(svg, path)
			})
		} else {
			status = documentData.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> svg_status_t in
				return svg_parse_buffer(svg, bytes, documentData.count)
			}
		}
		if status != SVG_STATUS_SUCCESS {
			return
		}
		
		let scaledRect: NSRect = {
			var tmpRect = NSRect.zero
			var height = svg_length_t()
			var width = svg_length_t()
			svg_get_size(svg, &width, &height)
			tmpRect.size = NSSize(width: SVGRenderContext.length(toPoints: &width) * scale, height: SVGRenderContext.length(toPoints: &height) * scale)
			return tmpRect
		}()
		let svg_render_context = SVGRenderContext()
		
		autoreleasepool {
			svg_render_context.prepareRender(scale)
			// Because Swift can be too strict about consts
			var tmpEngine = cocoa_svg_engine
			status = svg_render(svg, &tmpEngine, Unmanaged.passUnretained(svg_render_context).toOpaque())
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
	
	override var windowNibName: NSNib.Name? {
		return NSNib.Name("SVGDocument")
	}
	
	override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
		super.windowControllerDidLoadNib(windowController)
		reload(nil)
	}
	
	override func read(from url: URL, ofType typeName: String) throws {
		var svg: OpaquePointer? = nil
		var status = svg_create(&svg);
		if status == SVG_STATUS_NO_MEMORY {
			throw NSError(domain: NSOSStatusErrorDomain, code: kENOMEMErr, userInfo: nil)
		}
		defer {
			svg_destroy(svg);
		}
		
		status = url.withUnsafeFileSystemRepresentation { (fsr) -> svg_status_t in
			return svg_parse(svg, fsr)
		}
		switch status {
		case SVG_STATUS_SUCCESS:
			break;
			
		case SVG_STATUS_NO_MEMORY:
			throw NSError(domain: NSOSStatusErrorDomain, code: kENOMEMErr, userInfo: nil)
			
		case SVG_STATUS_FILE_NOT_FOUND:
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError, userInfo: nil)

		default:
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
		}
		documentData = try Data(contentsOf: url)
	}
	
	override func read(from data: Data, ofType typeName: String) throws {
		var svg: OpaquePointer? = nil
		var status = svg_create(&svg);
		if status == SVG_STATUS_NO_MEMORY {
			throw NSError(domain: NSOSStatusErrorDomain, code: kENOMEMErr, userInfo: nil)
		}
		defer {
			svg_destroy(svg);
		}

		status = data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> svg_status_t in
			return svg_parse_buffer(svg, bytes, data.count)
		}
		switch status {
		case SVG_STATUS_SUCCESS:
			break;
			
		case SVG_STATUS_NO_MEMORY:
			throw NSError(domain: NSOSStatusErrorDomain, code: kENOMEMErr, userInfo: nil)
			
		case SVG_STATUS_FILE_NOT_FOUND:
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError, userInfo: nil)
			
		default:
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
		}
		documentData = data;
	}
	
	
	
	@IBAction func scale_0_1(_ sender: AnyObject!) {
		scale = 0.1
		reload(nil)
	}
	@IBAction func scale_0_25(_ sender: AnyObject!) {
		scale = 0.25
		reload(nil)
	}
	@IBAction func scale_0_5(_ sender: AnyObject!) {
		scale = 0.5
		reload(nil)
	}
	@IBAction func scale_0_75(_ sender: AnyObject!) {
		scale = 0.75
		reload(nil)
	}
	@IBAction func scale_1_0(_ sender: AnyObject!) {
		scale = 1
		reload(nil)
	}
	@IBAction func scale_1_5(_ sender: AnyObject!) {
		scale = 1.5
		reload(nil)
	}
	@IBAction func scale_2_0(_ sender: AnyObject!) {
		scale = 2
		reload(nil)
	}
	@IBAction func scale_3_0(_ sender: AnyObject!) {
		scale = 3
		reload(nil)
	}
	@IBAction func scale_4_0(_ sender: AnyObject!) {
		scale = 4
		reload(nil)
	}
	@IBAction func scale_5_0(_ sender: AnyObject!) {
		scale = 5
		reload(nil)
	}
}
