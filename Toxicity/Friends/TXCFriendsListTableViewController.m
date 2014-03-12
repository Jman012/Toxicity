//
//  TXCFriendsListTableViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "TXCFriendsListTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TXCSingleton.h"
#import "TXCFriendChatWindowViewController.h"
#import "TXCGroupChatWindowViewController.h"
#import "TXCRequestsTableViewController.h"
#import "TXCFriendCell.h"
#import "TXCAppDelegate.h"
#import "TXCFriendListHeader.h"
#import "TXCGroupObject.h"
#import "TXCSettingsViewController.h"

#include "tox.h"

extern NSString *const TXCToxAppDelegateNotificationFriendAdded;
extern NSString *const TXCToxAppDelegateNotificationNewMessage;
extern NSString *const TXCToxAppDelegateNotificationFriendUserStatusChanged;
extern NSString *const TXCToxAppDelegateNotificationGroupAdded;
extern NSString *const TXCToxAppDelegateNotificationFriendRequestReceived;
extern NSString *const TXCToxAppDelegateNotificationGroupInviteReceived;

@interface TXCFriendsListTableViewController ()
@property (nonatomic, weak) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *requestsButton;
@property (nonatomic, strong) NSMutableArray *mainFriendList;
@property (nonatomic, strong) TXCFriendListHeader *headerForFriends;
@property (nonatomic, strong) TXCFriendListHeader *headerForGroups;
- (IBAction)requestsButtonPushed:(id)sender;
@end

@implementation TXCFriendsListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mainFriendList = [[TXCSingleton sharedSingleton] mainFriendList];

    /***** Appearance *****/
    
    TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[[UIApplication sharedApplication] delegate];
    [ourDelegate configureNavigationControllerDesign:self.navigationController];
    
    //set the font size of our settings button
    self.settingsButton.title = @"\u2699";
    UIFont *f1 = [UIFont fontWithName:@"Helvetica" size:24.0f];

    NSDictionary *attributes = @{
            UITextAttributeFont:f1,
            UITextAttributeTextColor:[UIColor whiteColor]
    };

    [self.settingsButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    //table view separator colors
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        self.tableView.separatorColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    } else {
        // Load resources for iOS 7 or later
        self.tableView.separatorColor = [UIColor clearColor];
    }
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    
    /***** End Appearance *****/
    
    [self.settingsButton setTarget:self];
    [self.settingsButton setAction:@selector(settingsButtonPushed)];
    
    
    [self updateRequestsButton];
    
    [self.tableView registerClass:[TXCFriendCell class] forCellReuseIdentifier:@"FriendListCell"];
    
    self.headerForFriends = [[TXCFriendListHeader alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    self.headerForGroups = [[TXCFriendListHeader alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateRequestsButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(friendListUpdate)
                                                 name:TXCToxAppDelegateNotificationFriendAdded
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(friendListUpdate)
                                                 name:TXCToxAppDelegateNotificationGroupAdded
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(friendListUpdate)
                                                 name:TXCToxAppDelegateNotificationFriendUserStatusChanged
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateRequestsButton)
                                                 name:TXCToxAppDelegateNotificationFriendRequestReceived
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateRequestsButton)
                                                 name:@"RejectedFriendRequest"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateRequestsButton)
                                                 name:TXCToxAppDelegateNotificationGroupInviteReceived
                                               object:nil];
    [self friendListUpdate];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)requestsButtonPushed:(id)sender {
    TXCRequestsTableViewController *requestsVC = [[TXCRequestsTableViewController alloc] init];
    [self.navigationController pushViewController:requestsVC animated:YES];
}

- (void)settingsButtonPushed {
    UINavigationController *settingsVC = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingsNavController"];
    TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[[UIApplication sharedApplication] delegate];
    [ourDelegate configureNavigationControllerDesign:settingsVC];
    
    [self.navigationController presentViewController:settingsVC animated:YES completion:nil];
}

- (void)friendListUpdate {
    [self.tableView reloadData];
}

- (void)updateRequestsButton {
    //update the name of the button
    int countRequests = [[[[TXCSingleton sharedSingleton] pendingFriendRequests] allKeys] count];
    int countInvites = [[[[TXCSingleton sharedSingleton] pendingGroupInvites] allKeys] count];
    if (countRequests > 0 || countInvites > 0) {
        self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Requests (%d)", countRequests + countInvites];
    } else {
        self.navigationItem.rightBarButtonItem.title = @"Requests";
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [TXCSingleton sharedSingleton].groupList.count;

        case 1:
            return self.mainFriendList.count;

        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            if ([TXCSingleton sharedSingleton].groupList.count > 0) {
                self.headerForGroups.textLabel.text = @"Groups";
                return self.headerForGroups;
            }
            break;
            
        case 1:
            if (self.mainFriendList.count > 0) {
                self.headerForFriends.textLabel.text = @"Friends";
                return self.headerForFriends;
            }
            break;
            
        default:
            return nil;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return 22;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if ([TXCSingleton sharedSingleton].groupList.count == 0) {
                return 0;
            } else {
                return 22;
            }

        case 1:
            if (self.mainFriendList.count == 0) {
                return 0;
            } else {
                return 22;
            }

        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FriendListCell";
    TXCFriendCell *cell = (TXCFriendCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        /***** Groups *****/
        //i have this all squashed down to save on visual space
        TXCGroupObject *tempGroup = [[TXCSingleton sharedSingleton].groupList objectAtIndex:indexPath.row];
        cell.friendIdentifier = tempGroup.groupPulicKey;
        NSString *temp = tempGroup.groupPulicKey;
        NSString *front = [temp substringToIndex:6];
        NSString *end = [temp substringFromIndex:temp.length - 6];
        NSString *formattedString = [[NSString alloc] initWithFormat:@"%@...%@", front, end];
        cell.nickLabel.text = formattedString;
        cell.messageLabelText = [[tempGroup groupMembers] componentsJoinedByString:@", "]; //"JmanGuy, stqism, stal" etc
        cell.avatarImage = [[TXCSingleton sharedSingleton] defaultAvatarImage];
        [[TXCSingleton sharedSingleton] avatarImageForKey:tempGroup.groupPulicKey type:AvatarType_Group finishBlock:^(UIImage *theAvatarImage) {
            if (cell) {
                if ([cell.friendIdentifier isEqualToString:tempGroup.groupPulicKey]) {
                    cell.avatarImage = theAvatarImage;
                } else {
                    NSArray *visibleCells = [tableView visibleCells];
                    for (TXCFriendCell *tempCell in visibleCells) {
                        if (tempCell) {
                            if ([tempCell.friendIdentifier isEqualToString:[[TXCSingleton sharedSingleton].groupList objectAtIndex:indexPath.row]]) {
                                tempCell.avatarImage = theAvatarImage;
                            }
                        }
                    }
                }
            } else {
                TXCFriendCell *theCell = (TXCFriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (theCell) {
                    if ([theCell.friendIdentifier isEqualToString:tempGroup.groupPulicKey]) {
                        theCell.avatarImage = theAvatarImage;
                    }}}}];
        cell.shouldShowFriendStatus = NO;
        return cell;
        
    } else {
        /***** Friends *****/
        TXCFriendObject *tempFriend = [self.mainFriendList objectAtIndex:indexPath.row];
        
        //set the identifier
        cell.friendIdentifier = tempFriend.publicKey; //make this a copy?
        
        //if we don't yet have a name for this friend (after just adding them, for instance) then use the first/last 6 chars of their key
        //e.g., AF4E32...B6C899
        if (!tempFriend.nickname.length){
            NSString *temp = tempFriend.publicKey;
            NSString *front = [temp substringToIndex:6];
            NSString *end = [temp substringFromIndex:[temp length] - 6];
            NSString *formattedString = [[NSString alloc] initWithFormat:@"%@...%@", front, end];
            cell.nickLabel.text = formattedString;
        } else {
            cell.nickLabel.text = tempFriend.nickname;
        }
        
        //the custom cell automatically changes the height of double line messages
        cell.messageLabelText = tempFriend.statusMessage;
        
        //set the avatar image
        cell.avatarImage = [TXCSingleton sharedSingleton].defaultAvatarImage;
        [[TXCSingleton sharedSingleton] avatarImageForKey:tempFriend.publicKey type:AvatarType_Friend finishBlock:^(UIImage *theAvatarImage) {
            
            if (cell) {
                if ([cell.friendIdentifier isEqualToString:tempFriend.publicKey]) {
                    cell.avatarImage = theAvatarImage;
                } else {
                    //this could have taken any amount of time to accomplish (either right from cache had to download a new one
                    //so we have to recheck to see if this cell is still alive and with the right id attached to it and stuff
                    NSArray *visibleCells = [tableView visibleCells];
                    for (TXCFriendCell *tempCell in visibleCells) {
                        if (tempCell) {
                            if ([tempCell.friendIdentifier isEqualToString:[self.mainFriendList objectAtIndex:indexPath.row]]) {
                                tempCell.avatarImage = theAvatarImage;
                            }
                        }
                    }
                }
            } else {
                TXCFriendCell *theCell = (TXCFriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (theCell) {
                    if ([theCell.friendIdentifier isEqualToString:tempFriend.publicKey]) {
                        theCell.avatarImage = theAvatarImage;
                    }
                }
            }
        }];
        
        //change the color. the custo mcell will actually change the image
        cell.shouldShowFriendStatus = YES;
        if (tempFriend.connectionType == TXCToxFriendConnectionStatus_None) {
            cell.statusColor = FriendCellStatusColor_Gray;
        } else {
            switch (tempFriend.statusType) {
                case TXCToxFriendUserStatus_Away:
                {
                    cell.statusColor = FriendCellStatusColor_Yellow;
                    break;
                }
                    
                case TXCToxFriendUserStatus_Busy:
                {
                    cell.statusColor = FriendCellStatusColor_Red;
                    break;
                }
                    
                case TXCToxFriendUserStatus_None:
                {
                    cell.statusColor = FriendCellStatusColor_Green;
                    break;
                }
                    
                default:
                    break;
            }
        }
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //delete the friend from the table view, singleton, and messenger instance
        
        TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[UIApplication sharedApplication].delegate;
        
        if (indexPath.section == 0) {
            
            //group delete
            int num = [ourDelegate deleteGroupchat:indexPath.row];
            
            if (num == 0) {
                [self.tableView beginUpdates];
                
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                
                [[TXCSingleton sharedSingleton].groupList removeObjectAtIndex:indexPath.row];
                [[TXCSingleton sharedSingleton].groupMessages removeObjectAtIndex:indexPath.row];

                //todo: save when i start saving these things
                
                [self.tableView endUpdates];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Something went wrong ith deleting the group chat! Tox Core issue."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            
        } else {
            
            //friend delete
            TXCFriendObject *tempFriend = self.mainFriendList[indexPath.row];
            int num = [ourDelegate deleteFriend:tempFriend.publicKey];
            
            if (num == 0) {
                [self.tableView beginUpdates];
                
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                
                [[TXCSingleton sharedSingleton].mainFriendList removeObjectAtIndex:indexPath.row];
                [[TXCSingleton sharedSingleton].mainFriendMessages removeObjectAtIndex:indexPath.row];
                
                //save in user defaults
                [TXCSingleton saveFriendListInUserDefaults];
                
                [self.tableView endUpdates];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Something went wrong with deleting the friend! Tox Core issue."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        TXCGroupChatWindowViewController *chatVC = [[TXCGroupChatWindowViewController alloc] initWithFriendIndex:indexPath];
        [self.navigationController pushViewController:chatVC animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        TXCFriendChatWindowViewController *chatVC = [[TXCFriendChatWindowViewController alloc] initWithFriendIndex:indexPath];
        [self.navigationController pushViewController:chatVC animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}



@end
