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
	
#if 0
	UIGraphicsBeginImageContextWithOptions(GetSVGImageSizeFromData(data), NO, autoscale ? 0.0 : 1.0);
#endif
	
	[svg_render_context prepareRender:scale];
	svg_status_t rendered = svg_render(svg_test, &cocoa_svg_engine, (__bridge void *)(svg_render_context));
	[svg_render_context finishRender];
	
	if (rendered == SVG_STATUS_SUCCESS) {
		CGSize renderSize = [svg_render_context size];
#if 1
		unsigned rowBytes = 4 * renderSize.width;
		void *imageBuffer = malloc(rowBytes * renderSize.height);
		static CGColorSpaceRef defaultSpace = NULL;
		if (defaultSpace == NULL) {
			defaultSpace = CGColorSpaceCreateDeviceRGB();
		}

		CGContextRef bitmapContext = CGBitmapContextCreate(imageBuffer, renderSize.width, renderSize.height, 8, rowBytes, defaultSpace, kCGImageAlphaPremultipliedLast);
		CGContextClearRect(bitmapContext, CGRectMake(0, 0, renderSize.width, renderSize.height));
		CGContextDrawLayerInRect(bitmapContext, CGRectMake(0, 0, renderSize.width, renderSize.height), svg_render_context.renderLayer);
		CGContextRelease(bitmapContext);
		CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, imageBuffer, rowBytes * renderSize.height, DataProviderReleasseCallback);

		returntype = CGImageCreate(renderSize.width, renderSize.height, 8, 32, rowBytes, defaultSpace, kCGImageAlphaPremultipliedLast, dataProvider, NULL, false, kCGRenderingIntentDefault);
		CGDataProviderRelease(dataProvider);
#else
		CGContextDrawLayerInRect(UIGraphicsGetCurrentContext(), CGRectMake(0,0,renderSize.width, renderSize.height), svg_render_context.renderLayer);
		UIImage *tempImage = UIGraphicsGetImageFromCurrentImageContext();
		returntype = CGImageRetain([tempImage CGImage]);
#endif
	}
	
#if 0
	UIGraphicsEndImageContext();
#endif
	
	svg_destroy(svg_test);
	
	return returntype;
}
