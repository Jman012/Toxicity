//
//  UIImageView+GradientImageView.h
//  Toxicity
//
//  Created by Vlad Mihaylenko on 15.03.14.
//  Copyright (c) 2014 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (GradientImageView)
+ (UIImageView*)gradientImageViewFromColor:(UIColor*)firstColor toColor:(UIColor*)secondColor withSize:(CGSize)size;
@end
