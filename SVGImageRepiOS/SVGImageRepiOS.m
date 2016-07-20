//
//  SVGImageRepiOS.m
//  SVGImageRepiOS
//
//  Created by Charles Betts on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGImageRepiOS.h"
#import "SVGRenderContext.h"

extern CGSize GetSVGImageSizeFromData(NSData *data)
{
	svg_t *svg_test;
	svg_status_t status;
	svg_create(&svg_test);
	status = svg_parse_buffer(svg_test, [data bytes], [data length]);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(svg_test);
		return CGSizeZero;
	}
	
	svg_length_t w, h;
	svg_get_size(svg_test, &w, &h);
	svg_destroy(svg_test);
	return CGSizeMake([SVGRenderContext lengthToPoints:&w], [SVGRenderContext lengthToPoints:&h]);
}

extern CGImageRef CreateSVGImageFromData(NSData* data)
{
	return CreateSVGImageFromDataWithScaleAutoScale(data, 1.0, YES);
}

extern CGImageRef CreateSVGImageFromDataWithScale(NSData *data, CGFloat scale)
{
	return CreateSVGImageFromDataWithScaleAutoScale(data, scale, YES);
}

extern CGImageRef CreateSVGImageFromDataWithScaleAutoScale(NSData *data, CGFloat scale, BOOL autoscale)
{
	svg_t *svg_test;
	svg_status_t status;
	svg_create(&svg_test);
	status = svg_parse_buffer(svg_test, [data bytes], [data length]);
	if (status != SVG_STATUS_SUCCESS) {
		return NULL;
	}
	
	CGImageRef returntype = NULL;
	
	SVGRenderContext *svg_render_context = [[SVGRenderContext alloc] init];
	
	svg_status_t rendered = 0;
	
	@autoreleasepool {
		[svg_render_context prepareRender:scale];
		rendered = svg_render(svg_test, &cocoa_svg_engine,(__bridge void *)(svg_render_context));
		[svg_render_context finishRender];
	}
	
	if (rendered == SVG_STATUS_SUCCESS) {
		CGSize renderSize = [svg_render_context size];
		unsigned rowBytes = 4 * renderSize.width;
		CGColorSpaceRef defaultSpace = CGColorSpaceCreateDeviceRGB();
		
		CGContextRef bitmapContext = CGBitmapContextCreateWithData(NULL, renderSize.width, renderSize.height, 8, rowBytes, defaultSpace, kCGImageAlphaPremultipliedLast, NULL, NULL);
		CGColorSpaceRelease(defaultSpace);
		CGContextClearRect(bitmapContext, CGRectMake(0, 0, renderSize.width, renderSize.height));
		CGContextDrawLayerInRect(bitmapContext, CGRectMake(0, 0, renderSize.width, renderSize.height), svg_render_context.renderLayer);
		returntype = CGBitmapContextCreateImage(bitmapContext);
		CGContextRelease(bitmapContext);
	}
	
	svg_destroy(svg_test);
	
	return returntype;
}
