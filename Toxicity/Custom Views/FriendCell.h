//
//  FriendCell.h
//  Toxicity
//
//  Created by James Linnell on 8/25/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "UIView+Shadow.h"

typedef enum {
    FriendCellStatusColor_Gray,
    FriendCellStatusColor_Green,
    FriendCellStatusColor_Yellow,
    FriendCellStatusColor_Red
} FriendCellStatusColor;

@interface FriendCell : UITableViewCell
{
    UIImageView     *statusImageView;
    UILabel         *messageLabel;
    UIImageView     *avatarImageView;
    
    UIView          *cellBackgroundView;
    CAGradientLayer *mainLayerGradient;
    CALayer         *mainLayerBG;
}

@property (nonatomic, strong) UILabel *nickLabel;
@property (nonatomic, strong) NSString *messageLabelText;
@property (nonatomic, assign) BOOL shouldShowFriendStatus;
@property (nonatomic, assign) FriendCellStatusColor statusColor;
@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, strong) NSString *friendIdentifier;


@end
