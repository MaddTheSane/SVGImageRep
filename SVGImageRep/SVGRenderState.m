//
//  SVGRenderState.m
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGRenderState.h"
#import <Foundation/NSString.h>
#import <AppKit/NSWindow.h>

@implementation SVGRenderState

@synthesize stroke_opacity, dash, color, window, opacity, num_dash, fill_rule;
@synthesize font_size, fill_paint, font_style, dash_offset, font_family, font_weight;
@synthesize text_anchor, fill_opacity, stroke_paint, stroke_width;

- (id)copyWithZone:(NSZone *)zone
{
	SVGRenderState *new = [[SVGRenderState allocWithZone:zone] init];
	
	new.num_dash = num_dash;
	new.stroke_opacity = stroke_opacity;
	new.color = color;
	new.window = window;
	new.opacity = opacity;
	new.fill_rule = fill_rule;
	new.font_size = font_size;
	new.fill_paint = fill_paint;
	new.font_style = font_style;
	new.dash_offset = dash_offset;
	new.font_weight = font_weight;
	new.text_anchor = text_anchor;
	new.fill_opacity = fill_opacity;
	new.stroke_paint = stroke_paint;
	new.stroke_width = stroke_width;
	new.font_family = [font_family copyWithZone:zone];
	
	if (dash)
	{
		new.dash = malloc(sizeof(CGFloat) * new.num_dash);
		memcpy(new.dash, dash, sizeof(CGFloat) * new.num_dash);
	}
	
	return new;
}

- (void)dealloc
{
	if (dash)
		free(dash);
}


@end
