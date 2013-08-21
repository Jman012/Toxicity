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
    
    settingsButton.title = @"\u2699";
    UIFont *f1 = [UIFont fontWithName:@"Helvetica" size:24.0f];
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:f1, UITextAttributeFont, nil];
    [settingsButton setTitleTextAttributes:dict forState:UIControlStateNormal];
    
    //color stuff
    self.tableView.separatorColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1];
    
    
    //dht connection status, put above table view
    //todo: make it work
    UIBarButtonItem *dhtStatus = [[UIBarButtonItem alloc] init];
    dhtStatus.title = @"Temporary Placeholder";
    dhtStatus.style = UIBarButtonItemStyleBordered;
    dhtStatus.width = 310;
    dhtStatus.tintColor = [UIColor colorWithRed:0.0f green:0.8f blue:0.0f alpha:1.0f];
    
    TransparentToolbar *toolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, -55, self.tableView.bounds.size.width, 44)];
    [toolbar setItems:[NSArray arrayWithObject:dhtStatus]];
    
    
    [self.tableView addSubview:toolbar];
    
    [self updateRequestsButton];
    
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    //do all the fancy stuff here
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = CGRectMake(cell.bounds.origin.x, cell.bounds.origin.y + 1, cell.bounds.size.width, cell.bounds.size.height - 1);
    UIColor *top = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.4f alpha:1.0f];
    UIColor *bottom = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.3f alpha:1.0f];
    grad.colors = [NSArray arrayWithObjects:(id)[top CGColor], (id)[bottom CGColor], nil];
    grad.name = @"Gradient";
    
    NSArray* sublayers = [NSArray arrayWithArray:cell.contentView.layer.sublayers];
    for (CALayer *layer in sublayers) {
        if ([layer.name isEqualToString:@"Gradient"]) {
            [layer removeFromSuperlayer];
        }
    }
    [cell.contentView.layer insertSublayer:grad atIndex:0];
    
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell.textLabel setBackgroundColor:[UIColor clearColor]];
    [cell.detailTextLabel setTextColor:[UIColor colorWithRed:0.55f green:0.62f blue:0.68f alpha:1.0f]];
    [cell.detailTextLabel setBackgroundColor:[UIColor clearColor]];
    
    cell.contentView.backgroundColor = [UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1.0f];
    
    
    cell.textLabel.shadowColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f];
    cell.textLabel.shadowOffset = CGSizeMake(1.0f, 1.0f);
    cell.detailTextLabel.shadowColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    cell.detailTextLabel.shadowOffset = CGSizeMake(0.5f, 0.5f);
    
    cell.textLabel.font = [UIFont systemFontOfSize:18.0f];
    
    
    //and here only give the cells info if it's actually in our array
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";
    
    
    /***************/
    
    
    //only do this stuff if it's an actual friend cell, not a blank one
    if ([_mainFriendList count] <= indexPath.row) {
        return  cell;
    }
    
    FriendObject *tempFriend = [_mainFriendList objectAtIndex:indexPath.row];
    
    if ([tempFriend.nickname isEqualToString:@""]){
        NSString *temp = tempFriend.publicKey;
        NSString *front = [temp substringToIndex:6];
        NSString *end = [temp substringFromIndex:[temp length] - 6];
        NSString *formattedString = [[NSString alloc] initWithFormat:@"%@...%@", front, end];
        cell.textLabel.text = formattedString;
    } else {
        cell.textLabel.text = tempFriend.nickname;
    }
    
    cell.detailTextLabel.text = tempFriend.statusMessage;
    
    //Currently not working due to bug in Tox
    UIImageView *statusView;
    if (tempFriend.connectionType == ToxFriendConnectionStatus_None) {
        statusView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status-gray"]];
    } else {
        switch (tempFriend.statusType) {
            case ToxFriendUserStatus_Away:
            {
                statusView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status-yellow"]];
                break;
            }
                
            case ToxFriendUserStatus_Busy:
            {
                statusView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status-red"]];
                break;
            }
                
            case ToxFriendUserStatus_None:
            {
                statusView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status-green"]];
                break;
            }
                
            default:
                break;
        }
    }
    statusView.frame = CGRectMake(cell.contentView.bounds.size.width - 16, 0, statusView.frame.size.width, statusView.frame.size.height);
    
    [cell.contentView addSubview:statusView];
    
    
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
        [self.tableView beginUpdates];
        
        Messenger *m = [[Singleton sharedSingleton] toxCoreMessenger];
        int num = m_delfriend(m, indexPath.row);
        
        if (num == 0) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
            [[[Singleton sharedSingleton] mainFriendList] removeObjectAtIndex:indexPath.row];
            [[[Singleton sharedSingleton] mainFriendMessages] removeObjectAtIndex:indexPath.row];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Something went wrong with deleting the friend! Tox Core issue." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [alert show];
        }
        
        [self.tableView endUpdates];
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

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSArray* sublayers = [NSArray arrayWithArray:cell.contentView.layer.sublayers];
    for (CALayer *layer in sublayers) {
        if ([layer.name isEqualToString:@"Gradient"]) {
            CAGradientLayer *gradLayer = (CAGradientLayer *)layer;
            UIColor *top = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.3f alpha:1.0f];
            UIColor *bottom = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.4f alpha:1.0f];
            gradLayer.colors = [NSArray arrayWithObjects:(id)[top CGColor], (id)[bottom CGColor], nil];
        }
    }
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSArray* sublayers = [NSArray arrayWithArray:cell.contentView.layer.sublayers];
    for (CALayer *layer in sublayers) {
        if ([layer.name isEqualToString:@"Gradient"]) {
            CAGradientLayer *gradLayer = (CAGradientLayer *)layer;
            UIColor *top = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.4f alpha:1.0f];
            UIColor *bottom = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.3f alpha:1.0f];
            gradLayer.colors = [NSArray arrayWithObjects:(id)[top CGColor], (id)[bottom CGColor], nil];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_mainFriendList count] <= indexPath.row) {
        return;
    }
    
    ChatWindowViewController *chatVC = [[ChatWindowViewController alloc] initWithFriendIndex:indexPath.row];
    [self.navigationController pushViewController:chatVC animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
}

@end
