//
//  SVGRenderState.h
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#include <svg.h>

@class NSString;

@interface SVGRenderState : NSObject <NSCopying>
{
@public
	svg_paint_t fillPaint, strokePaint;
@private
	double fillOpacity, strokeOpacity;
	
	svg_color_t color;
	double opacity;
	
	double strokeWidth;
	
	int fillRule;
	
	NSString *fontFamily;
	svg_font_style_t fontStyle;
	double fontSize;
	double fontWeight;
	svg_text_anchor_t textAnchor;
	
	CGFloat *dash;
	size_t numDash;
	CGFloat dashOffset;
}
@property (readwrite) svg_paint_t fillPaint;
@property (readwrite) svg_paint_t strokePaint;
@property (readwrite) double fillOpacity;
@property (readwrite) double strokeOpacity;
@property (readwrite) svg_color_t color;
@property (readwrite) double opacity;
@property (readwrite) double strokeWidth;
@property (readwrite) int fillRule;
@property (readwrite, copy) NSString *fontFamily;
@property (readwrite) svg_font_style_t fontStyle;
@property (readwrite) double fontSize;
@property (readwrite) double fontWeight;
@property (readwrite) svg_text_anchor_t textAnchor;
@property (readwrite) CGFloat *dash;
@property (readwrite) size_t numDash;
@property (readwrite) CGFloat dashOffset;

@end
