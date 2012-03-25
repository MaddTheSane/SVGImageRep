//
//  SVGImageRep.h
//  SVGImageRep
//
//  Created by Charles Betts on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef SVGImageRep_SVGImageRep_h
#define SVGImageRep_SVGImageRep_h

#include <svg.h>
#import <AppKit/NSImageRep.h>

extern svg_render_engine_t cocoa_svg_engine;
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
@property (readwrite, retain) NSWindow *window;
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


@interface SVGImageRep : NSImageRep
{
	svg_t *svg;
}

- initWithData: (NSData *)d;
@end

@interface SVGRenderContext : NSObject
{
@public
	NSWindow *result;
	NSSize size;
	
	double scale;
	
	SVGRenderState *current;
	NSMutableArray *states;
}

@property (readwrite, assign) SVGRenderState *current;
@property (readwrite, retain) NSMutableArray *states;
@property (readonly) NSSize size;

-(void) prepareRender: (double)a_scale;
-(void) finishRender;


-(double) lengthToPoints: (svg_length_t *)l;


-(void) arcTo: (double)rx : (double) ry
			 : (double)x_axis_rotation
			 : (int)large_arc_flag
			 : (int)sweep_flag
			 : (double)x : (double)y;


-(svg_status_t) beginGroup: (double)opacity;
-(svg_status_t) endGroup: (double)opacity;

-(svg_status_t) setViewportDimension: (svg_length_t *)width :(svg_length_t *)height;
-(svg_status_t) applyViewbox: (svg_view_box_t)viewbox
							: (svg_length_t *)width : (svg_length_t *)height;

-(svg_status_t) renderRect: (svg_length_t *)x : (svg_length_t *)y
						  : (svg_length_t *)width : (svg_length_t *)height
						  : (svg_length_t *)rx : (svg_length_t *)ry;
-(svg_status_t) renderPath;
-(svg_status_t) renderText: (const unsigned char *)utf8;
-(svg_status_t) renderEllipse: (svg_length_t *)cx : (svg_length_t *)cy
							 : (svg_length_t *)rx : (svg_length_t *)ry;

@end


#endif
