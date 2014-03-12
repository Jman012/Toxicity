//
//  TXCFriendChatWindowViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/8/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "TXCFriendChatWindowViewController.h"
#import "UIColor+ToxicityColors.h"
#import "JSMessage.h"
#import "TXCSingleton.h"
#import "TXCAppDelegate.h"
#import "TXCStatusLabel.h"

static NSString *const kSenderMe = @"Me";
static NSString *const kSenderThem = @"Them";

extern NSString *const TXCToxAppDelegateNotificationFriendAdded;
extern NSString *const TXCToxAppDelegateNotificationNewMessage;
extern NSString *const TXCToxAppDelegateNotificationFriendUserStatusChanged;

@interface TXCFriendChatWindowViewController ()

@property(nonatomic, strong) NSMutableArray *mainFriendList;
@property(nonatomic, strong) NSMutableArray *mainFriendMessages;
@property(nonatomic, strong) TXCFriendObject *friendInfo;
@property(nonatomic, strong) NSMutableArray *messages;
@property(nonatomic, strong) NSIndexPath *friendIndex;

@property (strong, nonatomic) TXCStatusLabel *statusLabel;

@end

@implementation TXCFriendChatWindowViewController

#pragma mark - Initialization

- (id)initWithFriendIndex:(NSIndexPath *)theIndex {

    self = [super init];
    if (self) {
        self.friendIndex = theIndex;
        
        self.mainFriendList = [TXCSingleton sharedSingleton].mainFriendList;
        self.mainFriendMessages = [TXCSingleton sharedSingleton].mainFriendMessages;
        
        self.messages = [[self.mainFriendMessages objectAtIndex:theIndex.row] mutableCopy];
        
        self.friendInfo = [self.mainFriendList objectAtIndex:theIndex.row];

        [[TXCSingleton sharedSingleton] setCurrentlyOpenedFriendNumber:self.friendIndex];
    }
    return self;
}

#pragma mark - View controller life cycle

- (void)viewDidLoad {
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    self.messageInputView.textView.placeHolder = @"";
    self.sender = kSenderMe;
    [self setBackgroundColor:[UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:1.0f]];

    self.statusLabel = ({
        TXCStatusLabel *statusLabel = [[TXCStatusLabel alloc] init];

        statusLabel.textAlignment = NSTextAlignmentCenter;
        statusLabel.textColor = self.navigationController.navigationBar.tintColor;
        statusLabel.font = [UIFont boldSystemFontOfSize:17.0];
        statusLabel.statusColor = [UIColor toxicityStatusColorGray];

        statusLabel;
    });

    self.navigationItem.titleView = self.statusLabel;

    [self updateUserInfo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollToBottomAnimated:NO];
    [self updateColoredStatusIndicator];
}

- (void)viewDidAppear:(BOOL)animated {
//    [self viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUserInfo)
                                                 name:TXCToxAppDelegateNotificationFriendAdded
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessage:)
                                                 name:TXCToxAppDelegateNotificationNewMessage
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateColoredStatusIndicator)
                                                 name:TXCToxAppDelegateNotificationFriendUserStatusChanged
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [TXCSingleton sharedSingleton].mainFriendMessages[self.friendIndex.row] = self.messages.mutableCopy;
    [[TXCSingleton sharedSingleton] setCurrentlyOpenedFriendNumber:[NSIndexPath indexPathForItem:-1 inSection:-1]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super viewDidDisappear:animated];
}

#pragma mark - Setters

- (void)setTitle:(NSString *)title {
    self.statusLabel.text = title;
    [self.statusLabel sizeToFit];
}

#pragma mark - Methods

- (void)updateColoredStatusIndicator {

    if (self.friendInfo.connectionType == TXCToxFriendConnectionStatus_Online) {
        switch (self.friendInfo.statusType) {
            case TXCToxFriendUserStatus_None:
                self.statusLabel.statusColor = [UIColor toxicityStatusColorGreen];
                break;
            case TXCToxFriendUserStatus_Away:
                self.statusLabel.statusColor = [UIColor toxicityStatusColorYellow];
                break;
            case TXCToxFriendUserStatus_Busy:
                self.statusLabel.statusColor = [UIColor toxicityStatusColorRed];
                break;
            default:break;
        }
    } else {
        self.statusLabel.statusColor = [UIColor toxicityStatusColorGray];
    }
}

#pragma mark - Notifications Center stuff

- (void)updateUserInfo {

    self.title = self.friendInfo.nickname.length ? self.friendInfo.nickname : self.friendInfo.publicKey;
    
    //todo: status (where to display?) and status type
}

- (void)newMessage:(NSNotification *)notification {
    TXCMessageObject *receivedMessage = (TXCMessageObject *)[notification object];
    
    if ([receivedMessage.senderKey isEqualToString:self.friendInfo.publicKey]) {
        [self.tableView beginUpdates];
        
        [self.messages addObject:receivedMessage];
        
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:(self.messages.count - 1) inSection:0]]
                              withRowAnimation:UITableViewRowAnimationBottom];
        [self.tableView endUpdates];
        [self scrollToBottomAnimated:YES];
    }
    
    [self scrollToBottomAnimated:YES];
    [JSMessageSoundEffect playMessageReceivedSound];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma mark - Messages view delegate
- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
//- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
//{
    TXCMessageObject *tempMessage = [[TXCMessageObject alloc] init];
    tempMessage.recipientKey = self.friendInfo.publicKey;
    
    if ([text length] >= 5) {
        //only check for the "/me " if the message is 5 or more characters in length.
        //5 because we can't send a blank action
        //text:"/me " the action would be ""
        //text:"/me h" the action would be "h"
        if ([[text substringToIndex:4] isEqualToString:@"/me "]) {
            tempMessage.message = [[NSString alloc] initWithFormat:@"* %@", [text substringFromIndex:4]];
            tempMessage.actionMessage = YES;
        } else {
            tempMessage.message = [text copy];
            tempMessage.actionMessage = NO;
        }
    } else {
        tempMessage.message = [text copy];
    }
    tempMessage.origin = MessageLocation_Me;
    tempMessage.didFailToSend = NO;
    
    
    [JSMessageSoundEffect playMessageSentSound];
    
    [tempMessage setIsGroupMessage:NO];
    
    TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[UIApplication sharedApplication].delegate;
    BOOL success = [ourDelegate sendMessage:tempMessage];
    if (!success) {
        tempMessage.didFailToSend = YES;
    }
    
    //add the message after we know if it failed or not
    [self.messages addObject:tempMessage];
//    [messages addObject:[[JSMessage alloc] initWithText:tempMessage.message sender:kSenderMe date:nil]];
    [self finishSend];
    [self scrollToBottomAnimated:YES];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    TXCMessageObject *tempMessage = [self.messages objectAtIndex:indexPath.row];
    return tempMessage.origin == MessageLocation_Me ? JSBubbleMessageTypeOutgoing : JSBubbleMessageTypeIncoming;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type forRowAtIndexPath:(NSIndexPath *)indexPath {
    TXCMessageObject *tempMessage = [self.messages objectAtIndex:indexPath.row];
    if (tempMessage.origin == MessageLocation_Me) {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleBlueColor]];
    } else {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleLightGrayColor]];
    }
}

- (JSMessageInputViewStyle)inputViewStyle {
    return JSMessageInputViewStyleFlat;
}

- (BOOL)shouldPreventScrollToBottomWhileUserScrolling {
    return YES;
}

- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)allowsPanToDismissKeyboard {
    return YES;
}

- (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (JSMessage *)messageForRowAtIndexPath:(NSIndexPath *)indexPath {
    TXCMessageObject *tempMessage = [self.messages objectAtIndex:indexPath.row];
    return [[JSMessage alloc] initWithText:tempMessage.message
                                    sender:tempMessage.origin == MessageLocation_Me ? kSenderMe : kSenderThem
                                      date:nil];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender {
    return nil;
}

- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (cell.subtitleLabel) {
        cell.subtitleLabel.text = nil;
    }
}

@end
