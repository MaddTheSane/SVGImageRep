//
//  SVGImageRepiOS.m
//  SVGImageRepiOS
//
//  Created by Charles Betts on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGImageRepiOS.h"
#import "SVGRenderContext.h"
static void DataProviderReleasseCallback(void *info, const void *data,
 size_t size)
{
	free(data);
}
extern CGImageRef CreateSVGImageFromData(NSData* data)
{
	svg_t *svg_test;
	svg_status_t status;
	svg_create(&svg_test);
	status = svg_parse_buffer(svg_test, [data bytes], [data length]);
	if (status != SVG_STATUS_SUCCESS) {
		return NULL;
	}
	
	CGImageRef returntype = NULL;
	
	SVGRenderContext *svg_render_context;
	svg_render_context = [[SVGRenderContext alloc] init];
	
	[svg_render_context prepareRender:1.0];
	svg_status_t rendered = svg_render(svg_test, &cocoa_svg_engine, svg_render_context);
	[svg_render_context finishRender];
	
	if (rendered == SVG_STATUS_SUCCESS) {
		NSSize renderSize = [svg_render_context size];
		unsigned rowBytes = 4 * renderSize.width;
		void *imageBuffer = malloc(rowBytes * renderSize.height);
		static CGColorSpaceRef defaultSpace = NULL;
		if (defaultSpace == NULL) {
			defaultSpace = CGColorSpaceCreateDeviceRGB();
		}

		CGContextRef bitmapContext = CGBitmapContextCreate(imageBuffer, renderSize.width, renderSize.height, 8, rowBytes, defaultSpace, kCGImageAlphaPremultipliedLast);
		CGContextClearRect(bitmapContext, CGRectMake(0,0,renderSize.width, renderSize.height));
		CGContextDrawLayerInRect(bitmapContext, CGRectMake(0, 0, renderSize.width, renderSize.height), svg_render_context.renderLayer);
		CGContextRelease(bitmapContext);
		CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, imageBuffer, rowBytes * renderSize.height, DataProviderReleasseCallback);

		returntype = CGImageCreate(renderSize.width, renderSize.height, 8, 32, rowBytes, defaultSpace, kCGImageAlphaPremultipliedLast, dataProvider, NULL, false, kCGRenderingIntentDefault);
		CGDataProviderRelease(dataProvider);
	}
	[svg_render_context release];
	
	svg_destroy(svg_test);
	
	return returntype;
}
