//
//  TXCFriendCell.m
//  Toxicity
//
//  Created by James Linnell on 8/25/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "TXCFriendCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+Shadow.h"
#import "UIColor+ToxicityColors.h"
#import "TXCFriendObject.h"
#import "TXCSingleton.h"

@interface TXCFriendCell ()

//@property (nonatomic, strong)  UIImageView *avatarImageView;
@property (nonatomic, strong)  UIImageView *statusIndicatorImageView;
@property (nonatomic, strong)  UILabel *statusLabel;
@property (nonatomic, strong)  UILabel *lastMessageLabel;
@property (nonatomic, strong)  UILabel *nameLabel;
@property (nonatomic, strong) UIImageView* pinImageView;
@end

@implementation TXCFriendCell



-(void) configureCellWithGroupObject:(TXCGroupObject*) groupObject {
    self.friendIdentifier = [groupObject.groupPulicKey copy];
    [self configureBackroundColor];
    [self configureLabelsWithGroupObject:groupObject];
    [self configureAvatarImageView];
}

-(void) configureCellWithFriendObject:(TXCFriendObject*) friendObject {
    self.friendIdentifier = [friendObject.publicKey copy];
    [self configureBackroundColor];
    [self configureLabelsWithFriendObject:friendObject];
    [self configureAvatarImageView];
    [self configureStatusIndicatorImageViewWithFriendObject:friendObject];
}

#pragma mark - Labels

-(void) configureLabelsWithGroupObject:(TXCGroupObject*) groupObject {
    [self configureLastMessageLabel];
    [self configureNameLabelWithGroupName:groupObject.groupName];
    [self configureStatusLabelWithGroupStatus:[[groupObject groupMembers] componentsJoinedByString:@", "]];
}

-(void) configureStatusLabelWithGroupStatus:(NSString*) status {
    if (!self.statusLabel)
        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(66., 25., 230., 16.)];
    [self.statusLabel setTextAlignment:NSTextAlignmentLeft];
    [self.statusLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.statusLabel setNumberOfLines:2];
    
    [self.statusLabel setTextColor:[UIColor colorWithRed:0.55f green:0.62f blue:0.68f alpha:1.0f]];
    [self.statusLabel setBackgroundColor:[UIColor clearColor]];
    [self.statusLabel setFont:[UIFont systemFontOfSize:12.0f]];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        [self.statusLabel setShadowColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f]];
        [self.statusLabel setShadowOffset:CGSizeMake(0.5f, 0.5f)];
    }
    [self.contentView addSubview:self.statusLabel];
    
    self.statusLabel.text = status;
}

-(void) configureNameLabelWithGroupName:(NSString*) name {
    self.nameLabel = ({
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(66., 8., 230., 18.)];
        [label setTextColor:[UIColor whiteColor]];
        [label setBackgroundColor:[UIColor clearColor]];
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            // Load resources for iOS 6.1 or earlier
            [label setShadowColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f]];
            [label setShadowOffset:CGSizeMake(1.0f, 1.0f)];
        }
        [label setFont:[UIFont systemFontOfSize:18.0f]];
        [self.contentView addSubview:label];
        if (!name.length){
            label
            .text = [NSString stringWithFormat:@"%@...%@", [self.friendIdentifier substringToIndex:6], [self.friendIdentifier substringFromIndex:[self.friendIdentifier length] - 6]];
        } else {
            label.text = name;
        }
        label;
        
    });
}



-(void) configureLabelsWithFriendObject:(TXCFriendObject*) friendObject {
    [self configureLastMessageLabel];
    [self configureNameLabelWithFriendName:friendObject.nickname];
    [self configureStatusLabelWithFriendStatus:friendObject.statusMessage];
}

-(void) configureStatusLabelWithFriendStatus:(NSString*) status {
    if (!self.statusLabel)
        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(66., 25., 230., 16.)];
    [self.statusLabel setTextAlignment:NSTextAlignmentLeft];
    [self.statusLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.statusLabel setNumberOfLines:2];
    
    [self.statusLabel setTextColor:[UIColor colorWithRed:0.55f green:0.62f blue:0.68f alpha:1.0f]];
    [self.statusLabel setBackgroundColor:[UIColor clearColor]];
    [self.statusLabel setFont:[UIFont systemFontOfSize:12.0f]];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        [self.statusLabel setShadowColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f]];
        [self.statusLabel setShadowOffset:CGSizeMake(0.5f, 0.5f)];
    }
    [self.contentView addSubview:self.statusLabel];
    if (status.length < 27)
        self.statusLabel.text = [status copy];
    else
        self.statusLabel.text = [NSString stringWithFormat:@"%@...", [status substringToIndex:27]] ;
}

-(void) configureNameLabelWithFriendName:(NSString*) name {
    self.nameLabel = ({
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(66., 8., 230., 18.)];
        [label setTextColor:[UIColor whiteColor]];
        [label setBackgroundColor:[UIColor clearColor]];
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            // Load resources for iOS 6.1 or earlier
            [label setShadowColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f]];
            [label setShadowOffset:CGSizeMake(1.0f, 1.0f)];
        }
        [label setFont:[UIFont systemFontOfSize:18.0f]];
        [self.contentView addSubview:label];
        if (!name.length){
            label
            .text = [NSString stringWithFormat:@"%@...%@", [self.friendIdentifier substringToIndex:6], [self.friendIdentifier substringFromIndex:[self.friendIdentifier length] - 6]];
        } else {
            label.text = name;
        }
        label;
        
    });
}

-(void) configureLastMessageLabel {
    if (!self.lastMessageLabel)
        self.lastMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(66., 41., 230., 16)];
    [self.lastMessageLabel setTextAlignment:NSTextAlignmentLeft];
    [self.lastMessageLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.lastMessageLabel setNumberOfLines:2];
    
    [self.lastMessageLabel setTextColor:[UIColor colorWithRed:0.55f green:0.62f blue:0.68f alpha:1.0f]];
    [self.lastMessageLabel setBackgroundColor:[UIColor clearColor]];
    [self.lastMessageLabel setFont:[UIFont systemFontOfSize:12.0f]];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        [self.lastMessageLabel setShadowColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f]];
        [self.lastMessageLabel setShadowOffset:CGSizeMake(0.5f, 0.5f)];
    }
    
    [self.contentView addSubview:self.lastMessageLabel];
    self.lastMessageLabel.text = [self.lastMessage copy];
    
    if (self.lastMessage.length < 27)
        self.lastMessageLabel.text = [self.lastMessage copy];
    else
        self.lastMessageLabel.text = [NSString stringWithFormat:@"%@...", [self.lastMessage substringToIndex:27]] ;
}

#pragma mark - Avatar

-(void) configureAvatarImageView {
    if (!self.avatarImageView)
        self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8., 8., 48., 48)];
    [self.avatarImageView setBackgroundColor:[UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f]];
    [self.avatarImageView.layer setCornerRadius:4.0f];
    [self.avatarImageView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.avatarImageView];
}

#pragma mark - Status

-(void) configureStatusIndicatorImageViewWithFriendObject:(TXCFriendObject*) friendObject {
    if (!self.statusIndicatorImageView)
        self.statusIndicatorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(304., 0., 16., 64)];
    [self setupStatusIndicatorImageViewWithFriendObject:friendObject];
    [self.contentView addSubview:self.statusIndicatorImageView];
}

-(void) setupStatusIndicatorImageViewWithFriendObject:(TXCFriendObject*) friendObject {
    self.shouldShowFriendStatus = YES;
    if (friendObject.connectionType == TXCToxFriendConnectionStatus_None) {
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            // Load resources for iOS 6.1 or earlier
            [self.statusIndicatorImageView setImage:[UIImage imageNamed:@"status-gray"]];
        } else {
            // Load resources for iOS 7 or later
            [self.statusIndicatorImageView setImage:[UIImage imageNamed:@"status-gray-ios7"]];
        }
    } else {
        switch (friendObject.statusType) {
            case TXCToxFriendUserStatus_Away:
            {
                if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                    // Load resources for iOS 6.1 or earlier
                    [self.statusIndicatorImageView setImage:[UIImage imageNamed:@"status-yellow"]];
                } else {
                    // Load resources for iOS 7 or later
                    [self.statusIndicatorImageView setImage:[UIImage imageNamed:@"status-yellow-ios7"]];
                }
                break;
            }
                
            case TXCToxFriendUserStatus_Busy:
            {
                if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                    // Load resources for iOS 6.1 or earlier
                    [self.statusIndicatorImageView setImage:[UIImage imageNamed:@"status-red"]];
                } else {
                    // Load resources for iOS 7 or later
                    [self.statusIndicatorImageView setImage:[UIImage imageNamed:@"status-red-ios7"]];
                }
            }
                
            case TXCToxFriendUserStatus_None:
            {
                if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                    // Load resources for iOS 6.1 or earlier
                    [self.statusIndicatorImageView setImage:[UIImage imageNamed:@"status-green"]];
                } else {
                    // Load resources for iOS 7 or later
                    [self.statusIndicatorImageView setImage:[UIImage imageNamed:@"status-green-ios7"]];
                }
                break;
            }
        }
    }
    
}

#pragma mark - Background color

-(void) configureBackroundColor {
    [self.contentView setFrame:CGRectMake(0., 0., 320., 64)];
    [self setBackgroundColor:[UIColor toxicityCellBackgroundColor]];
}



#pragma mark - New message pin 

-(void) addNewMessagePin {
    if (!self.pinImageView)
        self.pinImageView = [[UIImageView alloc] initWithFrame:CGRectMake(290, 45, 10, 10)];
    self.pinImageView.layer.masksToBounds = YES;
    self.pinImageView.layer.cornerRadius = 5.;
    self.pinImageView.backgroundColor = [UIColor orangeColor];
    [self.contentView addSubview:self.pinImageView];
    
}



@end
