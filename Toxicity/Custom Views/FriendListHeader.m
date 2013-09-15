//
//  FriendListHeader.m
//  Toxicity
//
//  Created by James Linnell on 9/13/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "FriendListHeader.h"

@implementation FriendListHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        /***** Gradient *****/
        CAGradientLayer *gradient = [CAGradientLayer layer];
        frame.size.height += 1;
        gradient.frame = frame;
        UIColor *topColor = [UIColor colorWithRed:0.14 green:0.13 blue:0.12 alpha:1];
        UIColor *bottomColor = [UIColor colorWithRed:0.19 green:0.18 blue:0.17 alpha:1];
        gradient.colors = [[NSArray alloc] initWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
        
        [self.layer insertSublayer:gradient atIndex:0];
        
        /***** Text Label *****/
        self.textLabel.textColor = [UIColor whiteColor];
        [self.textLabel setShadowColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f]];
        [self.textLabel setShadowOffset:CGSizeMake(1.0f, 1.0f)];
        [self.textLabel setFont:[UIFont systemFontOfSize:18.0f]];

    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
