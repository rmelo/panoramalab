//
//  OpenCVConversion.h
//  PanoramaLab
//
//  Created by Rodrigo Melo on 02/08/19.
//  Copyright © 2019 Rodrigo Melo. All rights reserved.
//

#import <opencv2/stitching.hpp>
#import <UIKit/UIKit.h>

@interface OpenCVConversion : NSObject

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;
+ (cv::Mat)cvMat3FromUIImage:(UIImage *)image; //convert UIImage to cv::Mat without alpha channel
+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;


@end

