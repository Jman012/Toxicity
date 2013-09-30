//
//  FriendsListTableViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "FriendsListTableViewController.h"

@interface FriendsListTableViewController ()

@end

@implementation FriendsListTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _mainFriendList = [[Singleton sharedSingleton] mainFriendList];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendListUpdate) name:@"FriendAdded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendListUpdate) name:@"GroupAdded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendListUpdate) name:@"FriendUserStatusChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRequestsButton) name:@"FriendRequestReceived" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRequestsButton) name:@"RejectedFriendRequest" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRequestsButton) name:@"GroupInviteReceived" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionStatusView:) name:@"DHTConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionStatusView:) name:@"DHTDisconnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionStatusView:) name:@"NewNumberOfConnectedNodes" object:nil];
    
    
    /***** Appearance *****/
    
    AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [ourDelegate configureNavigationControllerDesign:self.navigationController];
    
    //set the font size of our settings button
    settingsButton.title = @"\u2699";
    UIFont *f1 = [UIFont fontWithName:@"Helvetica" size:24.0f];
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:f1, UITextAttributeFont, [UIColor whiteColor], UITextAttributeTextColor, nil];
    [settingsButton setTitleTextAttributes:dict forState:UIControlStateNormal];
    
    //table view separator colors
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        self.tableView.separatorColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    } else {
        // Load resources for iOS 7 or later
        self.tableView.separatorColor = [UIColor clearColor];
    }
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    
    //dht connection status, put above table view
    connectionStatusToolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, -55, self.tableView.bounds.size.width, 44)];
    [self updateConnectionStatusView:[NSNotification notificationWithName:@"" object:nil]];
    [self.tableView addSubview:connectionStatusToolbar];
    
    /***** End Appearance *****/
    
    [settingsButton setTarget:self];
    [settingsButton setAction:@selector(settingsButtonPushed)];
    
    
    [self updateRequestsButton];
    
    [self.tableView registerClass:[FriendCell class] forCellReuseIdentifier:@"FriendListCell"];
    
    headerForFriends = [[FriendListHeader alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    headerForGroups = [[FriendListHeader alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
}

- (void)viewDidAppear:(BOOL)animated {
    [self updateRequestsButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)requestsButtonPushed:(id)sender {
    RequestsTableViewController *requestsVC = [[RequestsTableViewController alloc] init];
    [self.navigationController pushViewController:requestsVC animated:YES];
}

- (void)settingsButtonPushed {
    UINavigationController *settingsVC = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingsNavController"];
    AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [ourDelegate configureNavigationControllerDesign:settingsVC];
    
    [self.navigationController presentViewController:settingsVC animated:YES completion:nil];
}

- (void)friendListUpdate {
    [self.tableView reloadData];
}

- (void)updateRequestsButton {
    //update the name of the button
    int countRequests = [[[[Singleton sharedSingleton] pendingFriendRequests] allKeys] count];
    int countInvites = [[[[Singleton sharedSingleton] pendingGroupInvites] allKeys] count];
    if (countRequests > 0 || countInvites > 0) {
        self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Requests (%d)", countRequests + countInvites];
    } else {
        self.navigationItem.rightBarButtonItem.title = @"Requests";
    }
}
     
- (void)updateConnectionStatusView:(NSNotification *)notificaton {
    UIBarButtonItem *dhtStatus = [[UIBarButtonItem alloc] init];
    if (tox_isconnected([[Singleton sharedSingleton] toxCoreInstance])) {
        if ([notificaton object] == nil || ![notificaton object]) {
            dhtStatus.title = @"Connected to Network";
        } else {
            dhtStatus.title = [NSString stringWithFormat:@"Connected to Network: %d Nodes", [[notificaton object] integerValue]];
        }
        dhtStatus.tintColor = [UIColor colorWithRed:0.0f green:0.6f blue:0.0f alpha:1.0f];
    } else {
        dhtStatus.title = @"Not Connected";
        dhtStatus.tintColor = [UIColor colorWithRed:0.6f green:0.0f blue:0.0f alpha:1.0f];
    }
    dhtStatus.style = UIBarButtonItemStyleBordered;
    dhtStatus.width = 310;
    
    [connectionStatusToolbar setItems:[NSArray arrayWithObject:dhtStatus]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return [[[Singleton sharedSingleton] groupList] count];
            break;
            
        case 1:
            return [_mainFriendList count];
            break;
            
        default:
            return 0;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            if ([[[Singleton sharedSingleton] groupList] count] > 0) {
                headerForGroups.textLabel.text = @"Groups";
                return headerForGroups;
            }
            break;
            
        case 1:
            if ([_mainFriendList count] > 0) {
                headerForFriends.textLabel.text = @"Friends";
                return headerForFriends;
            }
            break;
            
        default:
            return nil;
            break;
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
            if ([[[Singleton sharedSingleton] groupList] count] == 0) {
                return 0;
            } else {
                return 22;
            }
            break;
            
        case 1:
            if ([_mainFriendList count] == 0) {
                return 0;
            } else {
                return 22;
            }
            break;
            
        default:
            return 0;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FriendListCell";
    FriendCell *cell = (FriendCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        /***** Groups *****/
        //i have this all squashed down to save on visual space
        GroupObject *tempGroup = [[[Singleton sharedSingleton] groupList] objectAtIndex:indexPath.row];
        cell.friendIdentifier = tempGroup.groupPulicKey;
        NSString *temp = tempGroup.groupPulicKey;
        NSString *front = [temp substringToIndex:6];
        NSString *end = [temp substringFromIndex:[temp length] - 6];
        NSString *formattedString = [[NSString alloc] initWithFormat:@"%@...%@", front, end];
        cell.nickLabel.text = formattedString;
        cell.messageLabelText = [[tempGroup groupMembers] componentsJoinedByString:@", "]; //"JmanGuy, stqism, stal" etc
        cell.avatarImage = [[Singleton sharedSingleton] defaultAvatarImage];
        [[Singleton sharedSingleton] avatarImageForKey:tempGroup.groupPulicKey type:AvatarType_Group finishBlock:^(UIImage *theAvatarImage) {
            if (cell) {
                if ([cell.friendIdentifier isEqualToString:tempGroup.groupPulicKey]) {
                    cell.avatarImage = theAvatarImage;
                } else {
                    NSArray *visibleCells = [tableView visibleCells];
                    for (FriendCell *tempCell in visibleCells) {
                        if (tempCell) {
                            if ([tempCell.friendIdentifier isEqualToString:[[[Singleton sharedSingleton] groupList] objectAtIndex:indexPath.row]]) {
                                tempCell.avatarImage = theAvatarImage;
                            }
                        }
                    }
                }
            } else {
                FriendCell *theCell = (FriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (theCell) {
                    if ([theCell.friendIdentifier isEqualToString:tempGroup.groupPulicKey]) {
                        theCell.avatarImage = theAvatarImage;
                    }}}}];
        cell.shouldShowFriendStatus = NO;
        return cell;
        
    } else {
        /***** Friends *****/
        FriendObject *tempFriend = [_mainFriendList objectAtIndex:indexPath.row];
        
        //set the identifier
        cell.friendIdentifier = tempFriend.publicKey; //make this a copy?
        
        //if we don't yet have a name for this friend (after just adding them, for instance) then use the first/last 6 chars of their key
        //e.g., AF4E32...B6C899
        if ([tempFriend.nickname isEqualToString:@""]){
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
        cell.avatarImage = [[Singleton sharedSingleton] defaultAvatarImage];
        [[Singleton sharedSingleton] avatarImageForKey:tempFriend.publicKey type:AvatarType_Friend finishBlock:^(UIImage *theAvatarImage) {
            
            if (cell) {
                if ([cell.friendIdentifier isEqualToString:tempFriend.publicKey]) {
                    cell.avatarImage = theAvatarImage;
                } else {
                    //this could have taken any amount of time to accomplish (either right from cache had to download a new one
                    //so we have to recheck to see if this cell is still alive and with the right id attached to it and stuff
                    NSArray *visibleCells = [tableView visibleCells];
                    for (FriendCell *tempCell in visibleCells) {
                        if (tempCell) {
                            if ([tempCell.friendIdentifier isEqualToString:[_mainFriendList objectAtIndex:indexPath.row]]) {
                                tempCell.avatarImage = theAvatarImage;
                            }
                        }
                    }
                }
            } else {
                FriendCell *theCell = (FriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (theCell) {
                    if ([theCell.friendIdentifier isEqualToString:tempFriend.publicKey]) {
                        theCell.avatarImage = theAvatarImage;
                    }
                }
            }
        }];
        
        //change the color. the custo mcell will actually change the image
        cell.shouldShowFriendStatus = YES;
        if (tempFriend.connectionType == ToxFriendConnectionStatus_None) {
            cell.statusColor = FriendCellStatusColor_Gray;
        } else {
            switch (tempFriend.statusType) {
                case ToxFriendUserStatus_Away:
                {
                    cell.statusColor = FriendCellStatusColor_Yellow;
                    break;
                }
                    
                case ToxFriendUserStatus_Busy:
                {
                    cell.statusColor = FriendCellStatusColor_Red;
                    break;
                }
                    
                case ToxFriendUserStatus_None:
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


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //delete the friend from the table view, singleton, and messenger instance
        
        AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if (indexPath.section == 0) {
            
            //group delete
            int num = [ourDelegate deleteGroupchat:indexPath.row];
            
            if (num == 0) {
                [self.tableView beginUpdates];
                
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                
                [[[Singleton sharedSingleton] groupList] removeObjectAtIndex:indexPath.row];
                [[[Singleton sharedSingleton] groupMessages] removeObjectAtIndex:indexPath.row];

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
            int num = [ourDelegate deleteFriend:indexPath.row];
            
            if (num == 0) {
                [self.tableView beginUpdates];
                
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                
                [[[Singleton sharedSingleton] mainFriendList] removeObjectAtIndex:indexPath.row];
                [[[Singleton sharedSingleton] mainFriendMessages] removeObjectAtIndex:indexPath.row];
                
                //save in user defaults
                [Singleton saveFriendListInUserDefaults];
                
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


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        GroupChatWindowViewController *chatVC = [[GroupChatWindowViewController alloc] initWithFriendIndex:indexPath];
        [self.navigationController pushViewController:chatVC animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        FriendChatWindowViewController *chatVC = [[FriendChatWindowViewController alloc] initWithFriendIndex:indexPath];
        [self.navigationController pushViewController:chatVC animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
