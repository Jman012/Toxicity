//
// Created by Виктор Шаманов on 3/12/14.
// Copyright (c) 2014 JamesTech. All rights reserved.
//

#import "UIColor+ToxicityColors.h"


@implementation UIColor (ToxicityColors)

+ (instancetype)toxicityStatusGrayColor {
    return [self colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1.0];
}

+ (instancetype)toxicityStatusRedColor {
    return [self colorWithRed:1.0 green:38.0/255.0 blue:0.0 alpha:1.0];
}

+ (instancetype)toxicityStatusGreenColor {
    return [self colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
}

+ (instancetype)toxicityStatusYellowColor {
    return [self colorWithRed:1.0 green:251.0/255.0 blue:0.0 alpha:1.0];
}

+ (instancetype)toxicityBackgroundDarkColor {
    return [self colorWithWhite:0.25 alpha:1.0];
}

+ (instancetype)toxicityBackgroundLightColor {
    return [self colorWithWhite:0.4 alpha:1.0];
}

+ (instancetype)toxicityCellBackgroundColor {
    return [self colorWithWhite:0.35 alpha:1.0];
}

+ (instancetype)toxicityCellSelectedColor {
    return [self colorWithWhite:0.2 alpha:1.0];
}

@end