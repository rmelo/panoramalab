//
//  OpenCVWrapper.h
//  PanoramaLab
//
//  Created by Rodrigo Melo on 30/07/19.
//  Copyright © 2019 Rodrigo Melo. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (NSString *) openCvVersionString;

+ (UIImage *) makeGrayscaleImage:(UIImage *) image;

+ (UIImage *) stitchImage:(UIImage *) leftImage :(UIImage *) rightImage;

@end
