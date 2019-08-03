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
#import "Cropping.h"
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

    [[self class] rotateImage:imageMat :image];
    
    if(imageMat.channels() == 1) return image;
    
    cv::Mat grayMat;
    cv::cvtColor(imageMat, grayMat, cv::COLOR_BGR2GRAY);

    return MatToUIImage(grayMat);
}

+ (UIImage *) detectEdges:(UIImage *) image :(double) cannyThreshold
{
    cv::Mat imageMat;
    UIImageToMat(image, imageMat);
    
//    [[self class] rotateImage:imageMat :image];
    
    cv::Mat grayMat;
    cv::cvtColor(imageMat, grayMat, cv::COLOR_BGR2GRAY);
    
    cv::Mat gaussianMat;
    cv::GaussianBlur(grayMat, gaussianMat, cv::Size(5, 5), 0);
    
    cv::Mat cannyMat;
    double lowCannyThreshold = 50;
    double cannyThresholdRatio = 3;
    cv::Canny(gaussianMat, cannyMat, lowCannyThreshold, lowCannyThreshold * cannyThresholdRatio);
    
    vector<vector<cv::Point>> contours;
    cv::findContours(cannyMat, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

    double largest_area, largest_area_index = 0;
    cv::Rect bounding_rect;

    for(int i = 0; i<contours.size(); i++)
    {
        double area = cv::contourArea(contours[i], false);
        if(area > largest_area){
            largest_area = area;
            largest_area_index = i;
            bounding_rect = cv::boundingRect(contours[i]);
        }
    }

    cv::cvtColor(imageMat, imageMat, cv::COLOR_BGR2RGB);
    
    cv::rectangle(imageMat, bounding_rect ,cv::Scalar(0,255,0), cv::LINE_8, cv::LINE_8);
    
    rotate(imageMat, imageMat, cv::ROTATE_90_CLOCKWISE);
    
    return MatToUIImage(imageMat);
}

+ (void) rotateImage :(cv::Mat&) mat :(UIImage *) image
{
    if ([image imageOrientation] == UIImageOrientationRight ||
        [image imageOrientation] == UIImageOrientationLeft) {
        rotate(mat, mat, cv::ROTATE_90_CLOCKWISE);
    }
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
    stitcher->setWarper(creator);
    
    vector<vector<cv::Rect>> rois;
    vector<cv::Rect> roi = {};
    
    cv::Rect leftRect(leftMat.cols/2, 0, leftMat.cols/2, leftMat.rows);
    cv::Rect rightRect(0, 0, rightMat.cols/2, rightMat.rows);
    
    roi.push_back(leftRect);
    roi.push_back(rightRect);
    
    rois.push_back(roi);
    
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
    
    cv::Mat cropedMat;
    
    [Cropping cropWithMat:pano andResult:cropedMat];
    
//    cv::rectangle(cropedMat, leftRect, cv::Scalar(0, 255, 0), cv::LINE_8);
    
//    cv::rectangle(cropedMat, rightRect, cv::Scalar(0, 255, 255), cv::LINE_8);
    
    UIImage * panoImage = MatToUIImage(cropedMat);
    
    return panoImage;
}

@end
