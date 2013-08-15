//
//  TransparentToolbar.m
//  Toxicity
//
//  Created by James Linnell on 8/11/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "TransparentToolbar.h"

@implementation TransparentToolbar

// Override init.
- (id) init
{
    self = [super init];
    [self applyTranslucentBackground];
    return self;
}

// Override initWithFrame.
- (id) initWithFrame:(CGRect) frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self applyTranslucentBackground];
    }
    return self;
}

// Override draw rect to avoid
// background coloring
- (void)drawRect:(CGRect)rect {
    // do nothing in here
}

// Set properties to make background
// translucent.
- (void) applyTranslucentBackground
{
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.translucent = YES;
}

@end
