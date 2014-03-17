//
//  TXCFriendCell.h
//  Toxicity
//
//  Created by James Linnell on 8/25/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TXCFriendObject;
@class TXCGroupObject;

typedef NS_ENUM(NSUInteger, FriendCellStatusColor) {
    FriendCellStatusColor_Gray,
    FriendCellStatusColor_Green,
    FriendCellStatusColor_Yellow,
    FriendCellStatusColor_Red
};

@interface TXCFriendCell : UITableViewCell

@property (nonatomic, copy) NSString *friendIdentifier;
@property (nonatomic, strong) UILabel *nickLabel;
@property (nonatomic, copy) NSString *messageLabelText;
@property (nonatomic, strong) UIImage *avatarImage;

@property (nonatomic, assign, getter = isShouldShowFriendStatus) BOOL shouldShowFriendStatus;
@property (nonatomic, assign) FriendCellStatusColor statusColor;
@property (nonatomic, strong) TXCFriendObject* friendObject;
@property (nonatomic, strong)  UIImageView *avatarImageView;
@property (nonatomic, copy) NSString *lastMessage;
-(void) configureCellWithFriendObject:(TXCFriendObject*) friendObject ;
-(void) configureCellWithGroupObject:(TXCGroupObject*) groupObject;
-(void) addNewMessagePin;
@end
