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

@synthesize stroke_opacity, dash, color, window, opacity, num_dash, fill_rule, font_size, fill_paint, font_style, dash_offset, font_family, font_weight, text_anchor, fill_opacity, stroke_paint, stroke_width;

- (id)copyWithZone:(NSZone *)zone
{
	SVGRenderState *new = NSCopyObject(self, 0, zone);
	
	[[new window] retain];
	[[new font_family] retain];
	
	if ([new dash])
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
	[window release];
	[font_family release];
	[super dealloc];
}

- (void)finalize
{
	if (dash)
		free(dash);
	
	[super finalize];
}

@end
