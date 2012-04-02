//
//  SVGRenderState.h
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSObject.h>
#include <ApplicationServices/ApplicationServices.h>
#include <svg.h>
@class NSWindow, NSString;

@interface SVGRenderState : NSObject <NSCopying>
{
@public
	NSWindow *window;
	
	svg_paint_t fill_paint,stroke_paint;
	double fill_opacity,stroke_opacity;
	
	svg_color_t color;
	double opacity;
	
	double stroke_width;
	
	int fill_rule;
	
	NSString *font_family;
	svg_font_style_t font_style;
	double font_size;
	double font_weight;
	svg_text_anchor_t text_anchor;
	
	CGFloat *dash;
	size_t num_dash;
	CGFloat dash_offset;
}
@property (readwrite) NSWindow *window;
@property (readwrite) svg_paint_t fill_paint;
@property (readwrite) svg_paint_t stroke_paint;
@property (readwrite) double fill_opacity;
@property (readwrite) double stroke_opacity;
@property (readwrite) svg_color_t color;
@property (readwrite) double opacity;
@property (readwrite) double stroke_width;
@property (readwrite) int fill_rule;
@property (readwrite, copy) NSString *font_family;
@property (readwrite) svg_font_style_t font_style;
@property (readwrite) double font_size;
@property (readwrite) double font_weight;
@property (readwrite) svg_text_anchor_t text_anchor;
@property (readwrite) CGFloat *dash;
@property (readwrite) size_t num_dash;
@property (readwrite) CGFloat dash_offset;

@end
