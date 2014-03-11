//
//  ChatWindowViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/8/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "GroupChatWindowViewController.h"

static NSString *const kSenderMe = @"Me";
extern NSString *const ToxAppDelegateNotificationNewMessage;
@interface GroupChatWindowViewController ()

@end

@implementation GroupChatWindowViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
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
        
        _mainGroupList = [[Singleton sharedSingleton] groupList];
        _mainGroupMessages = [[Singleton sharedSingleton] groupMessages];
        
        messages = [[_mainGroupMessages objectAtIndex:theIndex.row] mutableCopy];
        
        _groupInfo = [_mainGroupList objectAtIndex:theIndex.row];
        
        [[Singleton sharedSingleton] setCurrentlyOpenedFriendNumber:friendIndex];
    }
    return self;
}

- (void)viewDidLoad
{
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    self.messageInputView.textView.placeHolder = @"";
    self.sender = kSenderMe;
    [self setBackgroundColor:[UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:1.0f]];
    
    if (!_groupInfo.groupName.length) {
        self.title = _groupInfo.groupPulicKey;
    } else {
        self.title = _groupInfo.groupName;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollToBottomAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessage:)
                                                 name:ToxAppDelegateNotificationNewMessage
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [Singleton sharedSingleton].groupMessages[friendIndex.row] = messages.mutableCopy;
    [[Singleton sharedSingleton] setCurrentlyOpenedFriendNumber:[NSIndexPath indexPathForItem:-1 inSection:-1]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications Center stuff

- (void)updateUserInfo {
    if (!_groupInfo.groupName.length)
        self.title = _groupInfo.groupPulicKey;
    else
        self.title = _groupInfo.groupName;
    
    //todo: status (where to display?) and status type
}

- (void)newMessage:(NSNotification *)notification {
    MessageObject *receivedMessage = [notification object];
    
    if ([receivedMessage.senderKey isEqualToString:_groupInfo.groupPulicKey]) {
        [self.tableView beginUpdates];
        
        [messages addObject:receivedMessage];
        
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:(messages.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
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
- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
    MessageObject *tempMessage = [[MessageObject alloc] init];
    tempMessage.recipientKey = _groupInfo.groupPulicKey;
    
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
    
    
    [tempMessage setIsGroupMessage:YES];
    
    AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL success = [ourDelegate sendMessage:tempMessage];
    if (!success) {
        tempMessage.didFailToSend = YES;
    }
    
    //add the message after we know if it failed or not
//    [messages addObject:tempMessage];
    
    [self finishSend];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageObject *tempMessage = [messages objectAtIndex:indexPath.row];
    return tempMessage.origin == MessageLocation_Me ? JSBubbleMessageTypeOutgoing : JSBubbleMessageTypeIncoming;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type forRowAtIndexPath:(NSIndexPath *)indexPath
{
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

- (BOOL)shouldPreventScrollToBottomWhileUserScrolling
{
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
                                    sender:tempMessage.origin == MessageLocation_Me ? kSenderMe : tempMessage.senderName
                                      date:nil];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender
{
    return nil;
}

- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    MessageObject *tempMessage = [messages objectAtIndex:indexPath.row];
    if (cell.subtitleLabel && tempMessage.origin == MessageLocation_Them) {
        cell.subtitleLabel.text = [tempMessage senderName];
    }
}


@end
