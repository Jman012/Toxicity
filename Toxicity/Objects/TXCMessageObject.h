//
//  TXCMessageObject.h
//  Toxicity
//
//  Created by James Linnell on 8/15/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MessageOrigin) {
    MessageLocation_Me,
    MessageLocation_Them
};

typedef NS_ENUM(NSUInteger, MessageFamily) {
    MessageFamily_Friend,
    MessageFamily_Group
};

typedef NS_ENUM(NSUInteger, MessageType) {
    MessageType_Regular,
    MessageType_Action
};

@interface TXCMessageObject : NSObject

@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) MessageOrigin origin;
@property (nonatomic, assign) BOOL didFailToSend;
@property (nonatomic, assign) MessageFamily family;
@property (nonatomic, assign) MessageType type;
@property (nonatomic, strong) NSString *recipientKey;
@property (nonatomic, strong) NSString *senderKey;
@property (nonatomic, strong) NSString *senderName;

- (id)initWithMessage:(NSString *)message origin:(MessageOrigin)origin family:(MessageFamily)family type:(MessageType)type senderName:(NSString *)senderName senderKey:(NSString *)senderKey recipientKey:(NSString *)recipientKey;

@end
