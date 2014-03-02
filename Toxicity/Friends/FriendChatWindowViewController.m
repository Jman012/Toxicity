//
//  ChatWindowViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/8/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "FriendChatWindowViewController.h"

static NSString *const kSenderMe = @"Me";
static NSString *const kSenderThem = @"Them";

@interface FriendChatWindowViewController ()

@end

@implementation FriendChatWindowViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithFriendIndex:(NSIndexPath *)theIndex {
    
    self = [super init];
    if (self) {
        friendIndex = theIndex;
        
        _mainFriendList = [Singleton sharedSingleton].mainFriendList;
        _mainFriendMessages = [Singleton sharedSingleton].mainFriendMessages;
        
        messages = [[_mainFriendMessages objectAtIndex:theIndex.row] mutableCopy];
        
        _friendInfo = [_mainFriendList objectAtIndex:theIndex.row];
        
        [[Singleton sharedSingleton] setCurrentlyOpenedFriendNumber:friendIndex];
    }
    return self;
}

- (void)viewDidLoad {
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    self.messageInputView.textView.placeHolder = @"";
    self.sender = kSenderMe;
    [self setBackgroundColor:[UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:1.0f]];
    
    if ([_friendInfo.nickname isEqualToString:@""])
        self.title = _friendInfo.publicKey;
    else
        self.title = _friendInfo.nickname;
    
    //setup the colored status indicator on the navbar
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        statusNavBarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status-gray-navbar"]];
    } else {
        // Load resources for iOS 7 or later
        statusNavBarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status-gray-navbar-ios7"]];
    }
    CGRect tempFrame = statusNavBarImageView.frame;
    tempFrame.origin.x = self.navigationController.navigationBar.frame.size.width - tempFrame.size.width;
    statusNavBarImageView.frame = tempFrame;
    [self updateColoredStatusIndicator];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollToBottomAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
//    [self viewDidAppear:animated];
    [self.navigationController.navigationBar addSubview:statusNavBarImageView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUserInfo)
                                                 name:@"FriendAdded"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessage:)
                                                 name:@"NewMessage"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateColoredStatusIndicator)
                                                 name:@"FriendUserStatusChanged"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [statusNavBarImageView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [Singleton sharedSingleton].mainFriendMessages[friendIndex.row] = messages.mutableCopy;
    [[Singleton sharedSingleton] setCurrentlyOpenedFriendNumber:[NSIndexPath indexPathForItem:-1 inSection:-1]];
}

- (void)updateColoredStatusIndicator {
    if (_friendInfo.connectionType == ToxFriendConnectionStatus_Online) {
        switch (_friendInfo.statusType) {
            case ToxFriendUserStatus_None:
                if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                    // Load resources for iOS 6.1 or earlier
                    [statusNavBarImageView setImage:[UIImage imageNamed:@"status-green-navbar"]];
                } else {
                    // Load resources for iOS 7 or later
                    [statusNavBarImageView setImage:[UIImage imageNamed:@"status-green-navbar-ios7"]];
                }
                break;
                
            case ToxFriendUserStatus_Away:
                if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                    // Load resources for iOS 6.1 or earlier
                    [statusNavBarImageView setImage:[UIImage imageNamed:@"status-yellow-navbar"]];
                } else {
                    // Load resources for iOS 7 or later
                    [statusNavBarImageView setImage:[UIImage imageNamed:@"status-yellow-navbar-ios7"]];
                }
                break;
                
            case ToxFriendUserStatus_Busy:
                if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                    // Load resources for iOS 6.1 or earlier
                    [statusNavBarImageView setImage:[UIImage imageNamed:@"status-red-navbar"]];
                } else {
                    // Load resources for iOS 7 or later
                    [statusNavBarImageView setImage:[UIImage imageNamed:@"status-red-navbar-ios7"]];
                }
                break;
                
            default:
                break;
        }
    } else {
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            // Load resources for iOS 6.1 or earlier
            [statusNavBarImageView setImage:[UIImage imageNamed:@"status-gray-navbar"]];
        } else {
            // Load resources for iOS 7 or later
            [statusNavBarImageView setImage:[UIImage imageNamed:@"status-gray-navbar-ios7"]];
        }
    }
}

#pragma mark - Notifications Center stuff

- (void)updateUserInfo {
    if ([_friendInfo.nickname isEqualToString:@""])
        self.title = _friendInfo.publicKey;
    else
        self.title = _friendInfo.nickname;
    
    //todo: status (where to display?) and status type
}

- (void)newMessage:(NSNotification *)notification {
    MessageObject *receivedMessage = (MessageObject *)[notification object];
    
    if ([receivedMessage.senderKey isEqualToString:_friendInfo.publicKey]) {
        [self.tableView beginUpdates];
        
        [messages addObject:receivedMessage];
        
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:(messages.count - 1) inSection:0]]
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
    return messages.count;
}

#pragma mark - Messages view delegate
- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
//- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
//{
    MessageObject *tempMessage = [[MessageObject alloc] init];
    tempMessage.recipientKey = _friendInfo.publicKey;
    
    if ([text length] >= 5) {
        //only check for the "/me " if the message is 5 or more characters in length.
        //5 because we can't send a blank action
        //text:"/me " the action would be ""
        //text:"/me h" the action would be "h"
        if ([[text substringToIndex:4] isEqualToString:@"/me "]) {
            tempMessage.message = [[NSString alloc] initWithFormat:@"* %@", [text substringFromIndex:4]];
            tempMessage.isActionMessage = YES;
        } else {
            tempMessage.message = [text copy];
            tempMessage.isActionMessage = NO;
        }
    } else {
        tempMessage.message = [text copy];
    }
    tempMessage.origin = MessageLocation_Me;
    tempMessage.didFailToSend = NO;
    
    
    [JSMessageSoundEffect playMessageSentSound];
    
    [tempMessage setIsGroupMessage:NO];
    
    AppDelegate *ourDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    BOOL success = [ourDelegate sendMessage:tempMessage];
    if (!success) {
        tempMessage.didFailToSend = YES;
    }
    
    //add the message after we know if it failed or not
    [messages addObject:tempMessage];
//    [messages addObject:[[JSMessage alloc] initWithText:tempMessage.message sender:kSenderMe date:nil]];
    [self finishSend];
    [self scrollToBottomAnimated:YES];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageObject *tempMessage = [messages objectAtIndex:indexPath.row];
    return tempMessage.origin == MessageLocation_Me ? JSBubbleMessageTypeOutgoing : JSBubbleMessageTypeIncoming;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type forRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageObject *tempMessage = [messages objectAtIndex:indexPath.row];
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
    MessageObject *tempMessage = [messages objectAtIndex:indexPath.row];
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
