//
//  OpenCVWrapper.m
//  PanoramaLab
//
//  Created by Rodrigo Melo on 30/07/19.
//  Copyright © 2019 Rodrigo Melo. All rights reserved.
//

#import <opencv2/stitching.hpp>
#import <opencv2/imgcodecs/ios.h>
#include <opencv2/flann/any.h>
#import "OpenCVWrapper.h"
#include <iostream>

using namespace std;

@implementation OpenCVWrapper

+ (NSString *) openCvVersionString{
    return [NSString stringWithFormat:@"OpenCV version is %s", CV_VERSION];
}

+ (UIImage *) makeGrayscaleImage:(UIImage *) image
{
    cv::Mat imageMat;
    UIImageToMat(image, imageMat);
    
    if(imageMat.channels() == 1) return image;
    
    cv::Mat grayMat;
    cv::cvtColor(imageMat, grayMat, cv::COLOR_BGR2GRAY);

    return MatToUIImage(grayMat);
}

+ (UIImage *) stitchImage:(UIImage *) leftImage :(UIImage *) rightImage
{
    
    
    cv::Mat pano;
    
    vector<cv::Mat> images;
    cv::Mat leftMat;
    cv::Mat rightMat;
    
    UIImageToMat(leftImage, leftMat);
    UIImageToMat(rightImage, rightMat);
    
    if ([leftImage imageOrientation] == UIImageOrientationRight) {
        rotate(leftMat, leftMat, cv::ROTATE_90_CLOCKWISE);
    }

    if ([rightImage imageOrientation] == UIImageOrientationRight) {
        rotate(rightMat, rightMat, cv::ROTATE_90_CLOCKWISE);
    }
    
    cv::cvtColor(leftMat, leftMat, cv::COLOR_BGRA2BGR);
    cv::cvtColor(rightMat, rightMat, cv::COLOR_BGRA2BGR);
    
    images.push_back(leftMat);
    images.push_back(rightMat);
    
    cv::Stitcher::Mode mode = cv::Stitcher::PANORAMA;
    cv::Ptr<cv::Stitcher> stitcher = cv::Stitcher::create(mode);
    cv::Ptr<cv::WarperCreator> creator = new cv::PlaneWarper();
    
    stitcher->setWaveCorrection(false);
    stitcher->setWarper(creator);
    
    try {
    
        cv::Stitcher::Status status = stitcher->stitch(images, pano);
        
        if(status != cv::Stitcher::OK){
            printf("Can't stitch images, error code = %d", status);
            return leftImage;
        }
    } catch ( const std::exception & ex ) {
        printf("Error stitching is %s", ex.what());
        return leftImage;
    }
    
    cout << "Stitched!";
    
//    rotate(pano, pano, cv::ROTATE_90_COUNTERCLOCKWISE);
    UIImage * panoImage = MatToUIImage(pano);
    
    return panoImage;
}

@end
