/*
copyright 2003 Alexander Malmberg <alexander@malmberg.org>
*/

#ifndef Document_h
#define Document_h

#include <AppKit/NSWindowController.h>

@class NSString,NSScrollView;
@class SVGView;

@interface Document : NSWindowController
{
	NSString *path;

	NSScrollView *scroll_view;
	SVGView *svg_view;

	double scale;
}

+(void) openFile: (NSString *)path;

- initWithFile: (NSString *)path;

@end

#endif

