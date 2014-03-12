//
// Created by Виктор Шаманов on 3/12/14.
// Copyright (c) 2014 JamesTech. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TXCStatusLabel : UILabel

@property (strong, nonatomic) UIColor *statusColor;
@property (strong, nonatomic) NSString *statusString; // by default is ●
@property (strong, nonatomic) UIFont *statusFont; // if not set, using label.font

@end