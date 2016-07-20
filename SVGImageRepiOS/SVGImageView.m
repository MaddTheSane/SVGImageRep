//
//  SVGImageView.m
//  SVGImageRep
//
//  Created by Charles Betts on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGImageView.h"
#import "SVGRenderContext.h"
#include "svg.h"

@interface SVGImageView ()
@property (readonly, nonatomic) svg_t *svgPrivate;
@end

@implementation SVGImageView

@synthesize svgPrivate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (UIImage *)UIImage
{
	if (!svgPrivate) {
		return nil;
	}
	svg_length_t w, h;
	svg_get_size(svgPrivate, &w, &h);

	return [self UIImageWithSize:CGSizeMake([SVGRenderContext lengthToPoints:&w], [SVGRenderContext lengthToPoints:&h])];
}

- (UIImage *)UIImageWithSize:(CGSize)imageSize
{
	if (!svgPrivate) {
		return nil;
	}
	CGSize fillSize;
	{
	svg_length_t w, h;
	svg_get_size(svgPrivate, &w, &h);
		fillSize = CGSizeMake([SVGRenderContext lengthToPoints:&w], [SVGRenderContext lengthToPoints:&h]);
	}
	
	CGFloat scale = MIN(imageSize.height / fillSize.height, imageSize.width / fillSize.width);
	
	svg_status_t retStatus;
	SVGRenderContext *ctxt = [[SVGRenderContext alloc] init];
	@autoreleasepool {
		[ctxt prepareRender:scale];
		retStatus = svg_render(svgPrivate, &cocoa_svg_engine, ctxt);
		[ctxt finishRender];
	}
	CGColorSpaceRef defaultSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef tmpCtx = CGBitmapContextCreateWithData(NULL, imageSize.width, imageSize.height, 8, imageSize.width * 4, defaultSpace, kCGImageAlphaPremultipliedLast, NULL, NULL);
	CGColorSpaceRelease(defaultSpace);
	CGContextDrawLayerInRect(tmpCtx, CGRectMake(0, 0, imageSize.width, imageSize.height), ctxt.renderLayer);
	[ctxt release];
	CGImageRef tmpImage = CGBitmapContextCreateImage(tmpCtx);
	CGContextRelease(tmpCtx);
	UIImage *tmpUIImage = [UIImage imageWithCGImage:tmpImage];
	CGImageRelease(tmpImage);
	return tmpUIImage;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	if (svgPrivate) {
		SVGRenderContext *svg_render_context;
		CGContextRef CGCtx = UIGraphicsGetCurrentContext();
		svg_render_context = [[SVGRenderContext alloc] init];
		
		CGSize renderSize;
		{
			svg_length_t w, h;
			svg_get_size(svgPrivate, &w, &h);
			renderSize = CGSizeMake([SVGRenderContext lengthToPoints:&w], [SVGRenderContext lengthToPoints:&h]);
		}
		
		CGFloat xScale, yScale;
		xScale = rect.size.width / renderSize.width;
		yScale = rect.size.height / renderSize.height;
		
		svg_status_t rendered;
		@autoreleasepool{
			[svg_render_context prepareRender:MIN(xScale, yScale)];
			rendered = svg_render(svgPrivate, &cocoa_svg_engine, svg_render_context);
			[svg_render_context finishRender];
		}
		
		if (rendered == SVG_STATUS_SUCCESS) {
			CGContextDrawLayerInRect(CGCtx, rect, svg_render_context.renderLayer);
		}
		[svg_render_context release];
	} else {
		[[UIColor clearColor] set];
		CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
	}
}

- (void)dealloc
{
	if (svgPrivate) {
		svg_destroy(svgPrivate);
	}
	
	[super dealloc];
}

- (void)finalize
{
	if (svgPrivate) {
		svg_destroy(svgPrivate);
	}
	
	[super finalize];
}

- (void)setData:(NSData *)data
{
	svg_t *tmpSVG = NULL;
	
	svg_create(&tmpSVG);
	svg_status_t status = svg_parse_buffer(tmpSVG, [data bytes], [data length]);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(tmpSVG);
		return;
	} else {
		if (svgPrivate) {
			svg_destroy(svgPrivate);
			svgPrivate = NULL;
		}
		svgPrivate = tmpSVG;
		[self setNeedsDisplay];
	}
}

- (void)setSVGFilePath:(NSString *)path
{
	svg_t *tmpSVG = NULL;
	
	svg_create(&tmpSVG);
	svg_status_t status = svg_parse(tmpSVG, [path fileSystemRepresentation]);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(tmpSVG);
		return;
	}else {
		if (svgPrivate) {
			svg_destroy(svgPrivate);
			svgPrivate = NULL;
		}
		svgPrivate = tmpSVG;
		[self setNeedsDisplay];
	}
}

- (void)setSVGFileURL:(NSURL *)url
{
	if ([url isFileURL]) {
		[self setSVGFilePath:[url path]];
	} else {
		[self setData:[NSData dataWithContentsOfURL:url]];
	}
}

@end
