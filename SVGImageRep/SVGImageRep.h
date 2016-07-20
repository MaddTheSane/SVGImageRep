//
//  SVGImageRep.h
//  SVGImageRep
//
//  Created by Charles Betts on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef SVGImageRep_SVGImageRep_h
#define SVGImageRep_SVGImageRep_h

#import <AppKit/NSImageRep.h>

@class NSData;

@interface SVGImageRep : NSImageRep

- (id)initWithData:(NSData *)d;
@end

#endif
