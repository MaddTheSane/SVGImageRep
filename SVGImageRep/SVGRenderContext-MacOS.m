#import <AppKit/NSFontManager.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontDescriptor.h>
#import <AppKit/NSAttributedString.h>
#include <CoreText/CoreText.h>

static inline CGColorRef CreateColorRefFromSVGColor(svg_color_t *c, CGFloat alpha)
{
	return CGColorCreateGenericRGB(svg_color_get_red(c)/255.0, svg_color_get_green(c)/255.0, svg_color_get_blue(c)/255.0, alpha);
}

static CGColorSpaceRef GetGenericRGBColorSpace()
{
	static CGColorSpaceRef theSpace = NULL;
	if (theSpace == NULL) {
		theSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	}
	return theSpace;
}

- (void)prepareRender:(double)a_scale
{
	states = [[NSMutableArray alloc] init];
	current = nil;
	hasSize = NO;
	scale = a_scale;
	size = NSMakeSize(500 * scale, 500 * scale);
	unsizedRenderLayer = CGLayerCreateWithContext((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], NSSizeToCGSize(size), NULL);
}

- (svg_status_t)renderText:(const char *)utf8 atX:(CGFloat)xPos y:(CGFloat)yPos
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	NSFont *f = nil, *tmpfont = nil;
	NSFontManager *fm = [NSFontManager sharedFontManager];
	int w = ceil(current.fontWeight / 80.0);
	NSInteger i;

	svg_paint_t tempFill = current.fillPaint, tempStroke = current.strokePaint;

	if (utf8 == NULL)
	return SVG_STATUS_SUCCESS;

	NSString *utfString = [NSString stringWithUTF8String:utf8];

	{
		NSArray *families;
		NSString *family;
		
		families = [[current fontFamily] componentsSeparatedByString: @","];
		
		for (i = 0; i < [families count]; i++)
		{
			family = [families objectAtIndex: i];
			
			family = [family stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
			if ([family hasPrefix: @"'"])
				family = [[family substringToIndex: [family length]-1] substringFromIndex: 1];
			
			if ([family isEqual: @"serif"])
				family = @"Times";
			else if ([family isEqual: @"sans-serif"])
				family = @"Helvetica";
			else if ([family isEqual: @"monospace"])
				family = @"Courier";
			
			f = [NSFont fontWithName:family size:current.fontSize];
			if (f)
				break;
		}
		
		if (!f)
			f = [NSFont fontWithName:@"Helvetica" size:current.fontSize];
	}

	{
		NSFontTraitMask fontTrait = 0;
		if (current.fontStyle > SVG_FONT_STYLE_NORMAL) {
			fontTrait |= NSItalicFontMask;
		}
		if (current.fontWeight >= 700) {
			fontTrait |= NSBoldFontMask;
		}
		tmpfont = [fm fontWithFamily:[f familyName] traits:fontTrait weight:w size:current.fontSize];
	}

	//Should we set the text CTM here?
	CGContextScaleCTM(tempCtx, 1, -1);
	CGContextSetTextMatrix(tempCtx, CGAffineTransformIdentity);

#if 0

	NSAttributedString *textWFont = nil;
	{
		NSMutableDictionary *fontAttribs = [NSMutableDictionary dictionaryWithCapacity:2];
		
		[fontAttribs setValue:tmpfont forKey:NSFontAttributeName];
		NSColor *foreColor;
		if (tempFill.type == SVG_PAINT_TYPE_COLOR) {
			svg_color_t *tempsvgcolor = &tempFill.p.color;
			[self setFillColor:tempsvgcolor alpha:current.fillOpacity];
			foreColor = [NSColor colorWithDeviceRed:svg_color_get_red(tempsvgcolor)/255.0 green:svg_color_get_green(tempsvgcolor)/255.0 blue:svg_color_get_blue(tempsvgcolor)/255.0 alpha:current.fillOpacity];
		} else {
			foreColor = [NSColor clearColor];
		}
		[fontAttribs setValue:foreColor forKey:NSForegroundColorAttributeName];
		
		if (tempStroke.type == SVG_PAINT_TYPE_COLOR) {
			svg_color_t *tempsvgcolor = &tempStroke.p.color;
			[self setStrokeColor:tempsvgcolor alpha:current.strokeOpacity];
			[fontAttribs setValue:[NSColor colorWithDeviceRed:svg_color_get_red(tempsvgcolor)/255.0 green:svg_color_get_green(tempsvgcolor)/255.0 blue:svg_color_get_blue(tempsvgcolor)/255.0 alpha:current.strokeOpacity] forKey:NSStrokeColorAttributeName];
			[fontAttribs setValue:[NSNumber numberWithDouble:current.strokeWidth] forKey:NSStrokeWidthAttributeName];
		}
		
		textWFont = [[NSAttributedString alloc] initWithString:utfString attributes:fontAttribs];
	}

	CFRange fitRange;
	CTFrameRef tempFrame;
	{
		CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)textWFont);
		CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [textWFont length]), NULL, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX), &fitRange);
		CGMutablePathRef pathRef;
		pathRef = CGPathCreateMutable();
		CGPathMoveToPoint(pathRef, NULL, xPos, yPos);
		CGPathAddLineToPoint(pathRef, NULL, xPos + frameSize.width, yPos);
		CGPathAddLineToPoint(pathRef, NULL, xPos + frameSize.width, yPos - frameSize.height);
		CGPathAddLineToPoint(pathRef, NULL, xPos, yPos - frameSize.height);
		CGPathCloseSubpath(pathRef);
		tempFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [textWFont length]), pathRef, NULL);
		CGPathRelease(pathRef);
		CFRelease(framesetter);
	}
	CTFrameDraw(tempFrame, tempCtx);
	CFRelease(tempFrame);
	[textWFont release];

#else

	CGContextSetTextPosition(tempCtx, xPos, yPos);
	CGContextSelectFont(tempCtx, [[[tmpfont fontDescriptor] postscriptName] UTF8String], current.fontSize, kCGEncodingFontSpecific);
	NSUInteger str8len = [utfString length];
	unichar *chars = malloc(sizeof(unichar) * str8len);
	CGGlyph *glyphChars = malloc(sizeof(CGGlyph) * str8len);
	[utfString getCharacters:chars range:NSMakeRange(0, str8len)];
	CTFontGetGlyphsForCharacters((CTFontRef)tmpfont, chars, glyphChars, str8len);

	switch (tempFill.type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
		{
			CGContextSaveGState(tempCtx);
			CGContextSetTextDrawingMode(tempCtx, kCGTextFillClip);
			CGContextShowGlyphs(tempCtx, glyphChars, str8len);
			
			//CGContextClip(tempCtx);
			CGGradientRef gradient = CreateGradientRefFromSVGGradient(tempFill.p.gradient);
			
			switch (tempFill.p.gradient->type) {
				case SVG_GRADIENT_LINEAR:
				{
					CGFloat x1, y1, x2, y2;
					x1 = [self lengthToPoints:&tempFill.p.gradient->u.linear.x1];
					y1 = [self lengthToPoints:&tempFill.p.gradient->u.linear.y1];
					x2 = [self lengthToPoints:&tempFill.p.gradient->u.linear.x2];
					y2 = [self lengthToPoints:&tempFill.p.gradient->u.linear.y2];
					CGContextDrawLinearGradient(tempCtx, gradient, CGPointMake(x1, y1), CGPointMake(x2, y2), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
				}
					break;
					
				case SVG_GRADIENT_RADIAL:
				{
					CGFloat cx, cy, r, fx, fy;
					cx = [self lengthToPoints:&tempFill.p.gradient->u.radial.cx];
					cy = [self lengthToPoints:&tempFill.p.gradient->u.radial.cy];
					r = [self lengthToPoints:&tempFill.p.gradient->u.radial.r];
					fx = [self lengthToPoints:&tempFill.p.gradient->u.radial.fx];
					fy = [self lengthToPoints:&tempFill.p.gradient->u.radial.fy];
					CGContextDrawRadialGradient(tempCtx, gradient, CGPointMake(cx, cy), r, CGPointMake(fx, fy), r, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
				}
					break;
			}
			CGGradientRelease(gradient);
			CGContextRestoreGState(tempCtx);
		}
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setFillColor:&tempFill.p.color alpha:current.fillOpacity];
			CGContextSetTextDrawingMode(tempCtx, kCGTextFill);
			CGContextShowGlyphs(tempCtx, glyphChars, str8len);
			break;
			
		case SVG_PAINT_TYPE_NONE:
			break;
	}

	switch (tempStroke.type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
		{
			CGContextSaveGState(tempCtx);
			CGContextSetTextDrawingMode(tempCtx, kCGTextStrokeClip);
			CGContextShowGlyphs(tempCtx, glyphChars, str8len);
			//CGContextClip(tempCtx);
			CGGradientRef gradient = CreateGradientRefFromSVGGradient(tempStroke.p.gradient);
			switch (tempStroke.p.gradient->type) {
				case SVG_GRADIENT_LINEAR:
				{
					CGFloat x1, y1, x2, y2;
					x1 = [self lengthToPoints:&tempStroke.p.gradient->u.linear.x1];
					y1 = [self lengthToPoints:&tempStroke.p.gradient->u.linear.y1];
					x2 = [self lengthToPoints:&tempStroke.p.gradient->u.linear.x2];
					y2 = [self lengthToPoints:&tempStroke.p.gradient->u.linear.y2];
					CGContextDrawLinearGradient(tempCtx, gradient, CGPointMake(x1, y1), CGPointMake(x2, y2), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
				}
					break;
					
				case SVG_GRADIENT_RADIAL:
				{
					CGFloat cx, cy, r, fx, fy;
					cx = [self lengthToPoints:&tempStroke.p.gradient->u.radial.cx];
					cy = [self lengthToPoints:&tempStroke.p.gradient->u.radial.cy];
					r = [self lengthToPoints:&tempStroke.p.gradient->u.radial.r];
					fx = [self lengthToPoints:&tempStroke.p.gradient->u.radial.fx];
					fy = [self lengthToPoints:&tempStroke.p.gradient->u.radial.fy];
					CGContextDrawRadialGradient(tempCtx, gradient, CGPointMake(cx, cy), r, CGPointMake(fx, fy), r, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
				}
					break;
			}
			CGGradientRelease(gradient);
			CGContextRestoreGState(tempCtx);
		}
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setStrokeColor:&tempStroke.p.color alpha:current.strokeOpacity];
			CGContextSetTextDrawingMode(tempCtx, kCGTextStroke);
			CGContextShowGlyphs(tempCtx, glyphChars, str8len);
			break;
			
		case SVG_PAINT_TYPE_NONE:
			break;
	}
	free(chars);
	free(glyphChars);
#endif

	//Again, set the text CTM?
	CGContextScaleCTM(tempCtx, 1, -1);

	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_render_image(void *closure, unsigned char *data, unsigned int data_width, unsigned int data_height, svg_length_t *x, svg_length_t *y, svg_length_t *width, svg_length_t *height)
{ 
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	{
		CGFloat cx, cy, cw, ch;
		cx = [self lengthToPoints:x];
		cy = [self lengthToPoints:y];
		cw = [self lengthToPoints:width];
		ch = [self lengthToPoints:height];
		NSBitmapImageRep *temprep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:data_width pixelsHigh:data_height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:data_width * 4 bitsPerPixel:32];
		CGContextDrawImage(CGCtx, CGRectMake(cx, cy, cw, ch), [temprep CGImage]);
		[temprep release];
	}
	
	return SVG_STATUS_SUCCESS;
}
