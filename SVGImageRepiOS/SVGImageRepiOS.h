//
//  SVGImageRepiOS.h
//  SVGImageRepiOS
//
//  Created by Charles Betts on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGImageRef CreateSVGImageFromData(NSData* data);
extern CGImageRef CreateSVGImageFromDataWithScale(NSData *data, CGFloat scale);
extern CGSize GetSVGImageSizeFromData(NSData *data);
