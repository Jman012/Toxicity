//
//  TXCFriendCell.m
//  Toxicity
//
//  Created by James Linnell on 8/25/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        /*** Status Label ***/
        self.statusLabel = ({
            UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(66.0f, 25.0f, 230.0f, 16.0f)];
            [statusLabel setTextAlignment:NSTextAlignmentLeft];
            [statusLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [statusLabel setNumberOfLines:2];
            
            [statusLabel setTextColor:[UIColor colorWithRed:0.55f green:0.62f blue:0.68f alpha:1.0f]];
            [statusLabel setBackgroundColor:[UIColor clearColor]];
            [statusLabel setFont:[UIFont systemFontOfSize:12.0f]];
            
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                // Load resources for iOS 6.1 or earlier
                [statusLabel setShadowColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f]];
                [statusLabel setShadowOffset:CGSizeMake(0.5f, 0.5f)];
            }
            
            statusLabel;
        });
        [self.contentView addSubview:self.statusLabel];
        
        /*** Name Label ***/
        self.nameLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(66., 8., 230., 18.)];
            [label setTextColor:[UIColor whiteColor]];
            [label setBackgroundColor:[UIColor clearColor]];
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                // Load resources for iOS 6.1 or earlier
                [label setShadowColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f]];
                [label setShadowOffset:CGSizeMake(1.0f, 1.0f)];
            }
            [label setFont:[UIFont systemFontOfSize:18.0f]];
            
            label;
        });
        [self.contentView addSubview:self.nameLabel];

        /*** Last Message Label ***/
        self.lastMessageLabel = ({
            UILabel *lastMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(66., 41., 230., 16)];
            [lastMessageLabel setTextAlignment:NSTextAlignmentLeft];
            [lastMessageLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [lastMessageLabel setNumberOfLines:2];
            
            [lastMessageLabel setTextColor:[UIColor colorWithRed:0.55f green:0.62f blue:0.68f alpha:1.0f]];
            [lastMessageLabel setBackgroundColor:[UIColor clearColor]];
            [lastMessageLabel setFont:[UIFont systemFontOfSize:12.0f]];
            
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                // Load resources for iOS 6.1 or earlier
                [lastMessageLabel setShadowColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f]];
                [lastMessageLabel setShadowOffset:CGSizeMake(0.5f, 0.5f)];
            }
            
            lastMessageLabel;
        });
        [self.contentView addSubview:self.lastMessageLabel];
        
        /*** Avatar Image View ***/
        self.avatarImageView = ({
            UIImageView *avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8., 8., 48., 48)];
            [avatarImageView setBackgroundColor:[UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f]];
            [avatarImageView.layer setCornerRadius:4.0f];
            [avatarImageView.layer setMasksToBounds:YES];
            
            avatarImageView;
        });
        [self.contentView addSubview:self.avatarImageView];
        
        /*** Status Indicator View ***/
        self.statusIndicatorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(304., 0., 16., 64)];
        [self.contentView addSubview:self.statusIndicatorImageView];

        /*** Pin Image View ***/
        self.pinImageView = ({
            UIImageView *pinImageView = [[UIImageView alloc] initWithFrame:CGRectMake(290, 45, 10, 10)];
            pinImageView.layer.masksToBounds = YES;
            pinImageView.layer.cornerRadius = 5.0f;
            pinImageView.backgroundColor = [UIColor clearColor];
            
            pinImageView;
        });
        [self.contentView addSubview:self.pinImageView];
    }
    
    return self;
}

- (void)configureCellWithGroupObject:(TXCGroupObject *)groupObject
{
    self.friendIdentifier = [groupObject.groupPulicKey copy];
    [self configureBackroundColor];
    [self configureLabelsWithGroupObject:groupObject];
    self.statusIndicatorImageView.hidden = YES;
}

- (void)configureCellWithFriendObject:(TXCFriendObject *)friendObject
{
    self.friendIdentifier = [friendObject.publicKey copy];
    [self configureBackroundColor];
    [self configureLabelsWithFriendObject:friendObject];
    self.statusIndicatorImageView.hidden = NO;
    [self setupStatusIndicatorImageViewWithFriendObject:friendObject];
}

#pragma mark - Labels

- (void)configureLabelsWithGroupObject:(TXCGroupObject *)groupObject
{
    [self configureLastMessageLabel];
    [self configureNameLabelWithGroupName:groupObject.groupName];
    [self configureStatusLabelWithGroupStatus:[[groupObject groupMembers] componentsJoinedByString:@", "]];
}

- (void)configureStatusLabelWithGroupStatus:(NSString *)status
{
    
    self.statusLabel.text = status;
}

- (void)configureNameLabelWithGroupName:(NSString *)name
{
    if (!name.length){
        self.nameLabel.text = [NSString stringWithFormat:@"%@...%@", [self.friendIdentifier substringToIndex:6], [self.friendIdentifier substringFromIndex:[self.friendIdentifier length] - 6]];
    } else {
        self.nameLabel.text = name;
    }
}



- (void)configureLabelsWithFriendObject:(TXCFriendObject *)friendObject
{
    [self configureLastMessageLabel];
    [self configureNameLabelWithFriendName:friendObject.nickname];
    [self configureStatusLabelWithFriendStatus:friendObject.statusMessage];
}

- (void)configureStatusLabelWithFriendStatus:(NSString *)status
{
    if (status.length < 27)
        self.statusLabel.text = [status copy];
    else
        self.statusLabel.text = [NSString stringWithFormat:@"%@...", [status substringToIndex:27]] ;
}

- (void)configureNameLabelWithFriendName:(NSString *)name
{
    if (!name.length){
        self.nameLabel.text = [NSString stringWithFormat:@"%@...%@", [self.friendIdentifier substringToIndex:6], [self.friendIdentifier substringFromIndex:[self.friendIdentifier length] - 6]];
    } else {
        self.nameLabel.text = name;
    }
}

- (void)configureLastMessageLabel
{
    self.lastMessageLabel.text = [self.lastMessage copy];
    
    if (self.lastMessage.length < 27)
        self.lastMessageLabel.text = [self.lastMessage copy];
    else
        self.lastMessageLabel.text = [NSString stringWithFormat:@"%@...", [self.lastMessage substringToIndex:27]] ;
}

#pragma mark - Status

- (void)setupStatusIndicatorImageViewWithFriendObject:(TXCFriendObject *)friendObject
{
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

- (void)configureBackroundColor
{
    [self.contentView setFrame:CGRectMake(0., 0., 320., 64)];
    [self setBackgroundColor:[UIColor toxicityCellBackgroundColor]];
    
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
    selectedBackgroundView.backgroundColor = [UIColor toxicityCellSelectedColor];
    self.selectedBackgroundView = selectedBackgroundView;
}



#pragma mark - New message pin 

- (void)addNewMessagePin
{
    self.pinImageView.backgroundColor = [UIColor orangeColor];
}

- (void)removeNewMessagePin
{
    self.pinImageView.backgroundColor = [UIColor clearColor];
}



@end
