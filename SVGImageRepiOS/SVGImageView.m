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
	
	CGFloat xScale, yScale;
	xScale = rect.size.width / renderSize.width;
	yScale = rect.size.height / renderSize.height;
	
	svg_status_t rendered;
	@autoreleasepool {
		[svg_render_context prepareRender:MIN(xScale, yScale)];
		rendered = svg_render(svgPrivate, &cocoa_svg_engine, (__bridge void *)(svg_render_context));
		[svg_render_context finishRender];
	}
	
	CGFloat scale = MIN(imageSize.height / fillSize.height, imageSize.width / fillSize.width);
	
	svg_status_t retStatus;
	SVGRenderContext *ctxt = [[SVGRenderContext alloc] init];
	@autoreleasepool {
		[ctxt prepareRender:scale];
		retStatus = svg_render(svgPrivate, &cocoa_svg_engine, ctxt);
		[ctxt finishRender];
	}
}

- (void)dealloc
{
	if (svgPrivate) {
		svg_destroy(svgPrivate);
	}
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
