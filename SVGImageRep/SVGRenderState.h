//
//  SVGRenderState.h
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSObject.h>
#if !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)
#import <Foundation/NSGeometry.h>
#endif
#include <svg.h>

@class NSString;

@interface SVGRenderState : NSObject <NSCopying>
{
@private
	svg_paint_t fillPaint, strokePaint;
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
	size_t dashLength;
	CGFloat dashOffset;
}
@property (readwrite, nonatomic) svg_paint_t fillPaint;
@property (readwrite, nonatomic) svg_paint_t strokePaint;
@property (readwrite, nonatomic) double fillOpacity;
@property (readwrite, nonatomic) double strokeOpacity;
@property (readwrite, nonatomic) svg_color_t color;
@property (readwrite, nonatomic) double opacity;
@property (readwrite, nonatomic) double strokeWidth;
@property (readwrite, nonatomic) int fillRule;
@property (readwrite, nonatomic, copy) NSString *fontFamily;
@property (readwrite, nonatomic) svg_font_style_t fontStyle;
@property (readwrite, nonatomic) double fontSize;
@property (readwrite, nonatomic) double fontWeight;
@property (readwrite, nonatomic) svg_text_anchor_t textAnchor;
@property (readwrite, nonatomic) CGFloat *dash;
@property (readwrite, nonatomic) size_t dashLength;
@property (readwrite, nonatomic) CGFloat dashOffset;

@end
