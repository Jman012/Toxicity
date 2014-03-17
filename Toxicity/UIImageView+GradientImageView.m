//
//  UIImageView+GradientImageView.m
//  Toxicity
//
//  Created by Vlad Mihaylenko on 15.03.14.
//  Copyright (c) 2014 JamesTech. All rights reserved.
//

#import "UIImageView+GradientImageView.h"

@implementation UIImageView (GradientImageView)
+ (UIImageView*)gradientImageViewFromColor:(UIColor*)firstColor toColor:(UIColor*)secondColor withSize:(CGSize)size{
    
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    
    UIGraphicsBeginImageContext(bounds.size);
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 0.8 };
    
    CGFloat firstColorRedComponent = 0.0, firstColorGreenComponent = 0.0, firstColorBlueComponent = 0.0, firstColorAlphaComponent =0.0;
    [firstColor getRed:&firstColorRedComponent green:&firstColorGreenComponent blue:&firstColorBlueComponent alpha:&firstColorAlphaComponent];
    
    
    CGFloat secondColorRedComponent = 0.0, secondColorGreenComponent = 0.0, secondColorBlueComponent = 0.0, secondColorAlphaComponent =0.0;
    [secondColor getRed:&secondColorRedComponent green:&secondColorGreenComponent blue:&secondColorBlueComponent alpha:&secondColorAlphaComponent];
    
    CGFloat components[8] = {
        firstColorRedComponent,   firstColorGreenComponent,  firstColorBlueComponent,  firstColorAlphaComponent,
        secondColorRedComponent, secondColorGreenComponent, secondColorBlueComponent, secondColorAlphaComponent
        
    };
    
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
    
    
    CGPoint topCenter = CGPointMake(CGRectGetMidX(bounds), 0.0f);
    CGPoint midCenter = CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds));
    CGContextDrawLinearGradient(context, glossGradient, topCenter, midCenter, 0);
    
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
    CGContextRestoreGState(context);
    
    UIImage* returnImage = UIGraphicsGetImageFromCurrentImageContext();
    
    
    UIGraphicsEndImageContext();
    
    UIImageView* returnImageView = [[UIImageView alloc] initWithImage:returnImage];
    return (returnImageView);
    
}

@end
