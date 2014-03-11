//
// Created by Виктор Шаманов on 3/12/14.
// Copyright (c) 2014 JamesTech. All rights reserved.
//

#import "UIColor+ToxicityColors.h"


@implementation UIColor (ToxicityColors)

+ (instancetype)toxicityStatusColorGray {
    return [self colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1.0];
}

+ (instancetype)toxicityStatusColorRed {
    return [self colorWithRed:1.0 green:38.0/255.0 blue:0.0 alpha:1.0];
}

+ (instancetype)toxicityStatusColorGreen {
    return [self colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
}

+ (instancetype)toxicityStatusColorYellow {
    return [self colorWithRed:1.0 green:251.0/255.0 blue:0.0 alpha:1.0];
}

@end