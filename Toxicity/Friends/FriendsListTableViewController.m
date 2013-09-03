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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendListUpdate) name:@"FriendUserStatusChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRequestsButton) name:@"FriendRequestReceived" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRequestsButton) name:@"AcceptedFriendRequest" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRequestsButton) name:@"RejectedFriendRequest" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionStatusView:) name:@"DHTConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionStatusView:) name:@"DHTDisconnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionStatusView:) name:@"NewNumberOfConnectedNodes" object:nil];
    
    settingsButton.title = @"\u2699";
    UIFont *f1 = [UIFont fontWithName:@"Helvetica" size:24.0f];
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:f1, UITextAttributeFont, nil];
    [settingsButton setTitleTextAttributes:dict forState:UIControlStateNormal];
    
    //color stuff
    self.tableView.separatorColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1];
    
    
    //dht connection status, put above table view
    connectionStatusToolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, -55, self.tableView.bounds.size.width, 44)];
    [self updateConnectionStatusView:[NSNotification notificationWithName:@"" object:nil]];
    
    
    [self.tableView addSubview:connectionStatusToolbar];
    
    [self updateRequestsButton];
    
    [self.tableView registerClass:[FriendCell class] forCellReuseIdentifier:@"FriendListCell"];
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

- (void)friendListUpdate {
    [self.tableView reloadData];
}

- (void)updateRequestsButton {
    //update the name of the button
    int count = [[[[Singleton sharedSingleton] pendingFriendRequests] allKeys] count];
    if (count > 0) {
        self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Requests (%d)", count];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return [_mainFriendList count];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FriendListCell";
    FriendCell *cell = (FriendCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    FriendObject *tempFriend = [_mainFriendList objectAtIndex:indexPath.row];
    
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
    
    //change the color. the custo mcell will actually change the image
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
        
//        Tox *m = [[Singleton sharedSingleton] toxCoreInstance];
//        int num = tox_delfriend(m, indexPath.row);
        AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Something went wrong with deleting the friend! Tox Core issue." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
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
    ChatWindowViewController *chatVC = [[ChatWindowViewController alloc] initWithFriendIndex:indexPath.row];
    [self.navigationController pushViewController:chatVC animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
}

@end
