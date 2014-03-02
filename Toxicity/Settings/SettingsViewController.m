//
//  SettingsViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

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
    
    _dhtNodeList = [[Singleton sharedSingleton] dhtNodeList];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDHTServer:) name:@"NewDHT" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dhtConnected:) name:@"DHTConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dhtDisonnected:) name:@"DHTDisonnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStartDHTNodeConnection:) name:@"DidStartDHTNodeConnection" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToConnect:) name:@"DHTFailedToConnect" object:nil];
    
}

- (void)addDHTServer:(NSNotification *)notification {
    
    if ([[notification userInfo][@"editing"] isEqualToString:@"yes"]) {
                
        NSIndexPath *path = [notification userInfo][@"indexpath"];
        DHTNodeObject *tempDHT = [_dhtNodeList objectAtIndex:(path.row - 1)];
        [tempDHT setDhtName:[notification userInfo][@"dht_name"]];
        [tempDHT setDhtIP:[notification userInfo][@"dht_ip"]];
        [tempDHT setDhtPort:[notification userInfo][@"dht_port"]];
        [tempDHT setDhtKey:[notification userInfo][@"dht_key"]];
        
        [self.tableView reloadData];
        
        NSLog(@"Saving dhts");
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (DHTNodeObject *arrayDHT in [[Singleton sharedSingleton] dhtNodeList]) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[arrayDHT copy]];
            [array addObject:data];
        }
        [prefs setObject:array forKey:@"dht_node_list"];
        [prefs synchronize];
        
    } else {
        
        [self.tableView beginUpdates];
        
        DHTNodeObject *tempDHT = [[DHTNodeObject alloc] init];
        [tempDHT setDhtName:[notification userInfo][@"dht_name"]];
        [tempDHT setDhtIP:[notification userInfo][@"dht_ip"]];
        [tempDHT setDhtPort:[notification userInfo][@"dht_port"]];
        [tempDHT setDhtKey:[notification userInfo][@"dht_key"]];
        [tempDHT setConnectionStatus:ToxDHTNodeConnectionStatus_NotConnected];
        [_dhtNodeList addObject:tempDHT];
        
        NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[_dhtNodeList count] inSection:2]];
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        NSLog(@"Saving dhts");
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (DHTNodeObject *arrayDHT in [[Singleton sharedSingleton] dhtNodeList]) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[arrayDHT copy]];
            [array addObject:data];
        }
        [prefs setObject:array forKey:@"dht_node_list"];
        [prefs synchronize];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dhtConnected:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)dhtDisconnecting:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)didStartDHTNodeConnection:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)didFailToConnect:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (IBAction)saveButtonPushed:(id)sender {
    if (![nameTextField.text isEqualToString:[[Singleton sharedSingleton] userNick]]) {
        //they changed their name
        
        [[Singleton sharedSingleton] setUserNick:[nameTextField text]];
        
        AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [ourDelegate userNickChanged];
        
    }
    
    if (![statusTextField.text isEqualToString:[[Singleton sharedSingleton] userStatusMessage]]) {
        //they changed their name
        
        [[Singleton sharedSingleton] setUserStatusMessage:[statusTextField text]];
        AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [ourDelegate userStatusChanged];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editButtonPushed:(id)sender {
    UIBarButtonItem *doneEditingButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneEditingButtonPushed)];
    self.navigationItem.leftBarButtonItem = doneEditingButton;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.tableView setEditing:YES animated:YES];
}

- (void)doneEditingButtonPushed {
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editButtonPushed:)];
    self.navigationItem.leftBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    [self.tableView setEditing:NO animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    
    //Section 1: Name/Statuss
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    switch (section) {
        case 0:
            return 3;
            break;
            
        case 1:
            return 1;
            break;
            
        case 2:
            //Add ones for the row to add a new server
            return [_dhtNodeList count] + 1;
            break;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier;
    if (indexPath.section == 0)
        CellIdentifier = @"settingsInfoCell";
    else if (indexPath.section == 1)
        CellIdentifier = @"settingsCopyIDCell";
    else if (indexPath.section == 2 && indexPath.row == 0)
        CellIdentifier = @"settingsNewDHTCell";
    else if (indexPath.section == 2 && indexPath.row >= 1)
        CellIdentifier = @"settingsDHTCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    switch ([indexPath section]) {
        case 0:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if (indexPath.row != 2) {
                //name/status message field
                
                UILabel *label;
                BOOL shouldAddLabel;
                if ([cell viewWithTag:300] == nil) {
                    label = [[UILabel alloc] initWithFrame:CGRectMake(18, 11, 60, 21)];
                    label.backgroundColor = [UIColor clearColor];
                    label.font = [UIFont boldSystemFontOfSize:17.0f];
                    label.textAlignment = NSTextAlignmentRight;
                    label.tag = 300;
                    shouldAddLabel = YES;
                } else {
                    label = (UILabel *)[cell viewWithTag:300];
                    shouldAddLabel = NO;
                }
                
                if (indexPath.row == 0)
                    label.text = @"Name:";
                else if (indexPath.row == 1) {
                    label.text = @"Status:";
                }
                
                if (shouldAddLabel)
                    [cell.contentView addSubview:label];
                
                UITextField *textField;
                BOOL shouldAddTextField;
                if ([cell viewWithTag:301] == nil) {
                    textField = [[UITextField alloc] initWithFrame:CGRectMake(85, 11, 195, 30)];
                    textField.delegate = self;
                    textField.tag = 301;
                    shouldAddTextField = YES;
                } else {
                    textField = (UITextField *)[cell viewWithTag:301];
                    shouldAddTextField = NO;
                }
                
                if (indexPath.row == 0) {
                    [textField setText:[[Singleton sharedSingleton] userNick]];
                    
                    nameTextField = textField;
                }
                else if (indexPath.row == 1) {
                    [textField setText:[[Singleton sharedSingleton] userStatusMessage]];
                    
                    statusTextField = textField;
                }
                
                [textField setBorderStyle:UITextBorderStyleNone];
                
                if (shouldAddTextField)
                    [cell.contentView addSubview:textField];
            } else {
                //segmented control for status type
                UISegmentedControl *statusTypeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Online", @"Away", @"Busy", nil]];
                statusTypeControl.segmentedControlStyle = UISegmentedControlStyleBar;
                [statusTypeControl addTarget:self action:@selector(userStatusTypeDidChange:) forControlEvents:UIControlEventValueChanged];
                statusTypeControl.frame = CGRectMake(cell.contentView.bounds.origin.x + 10, 7, cell.contentView.frame.size.width - 20, 30);
                switch ([[Singleton sharedSingleton] userStatusType]) {
                    case ToxFriendUserStatus_None:
                        statusTypeControl.selectedSegmentIndex = 0;
                        break;
                        
                    case ToxFriendUserStatus_Away:
                        statusTypeControl.selectedSegmentIndex = 1;
                        break;
                        
                    case ToxFriendUserStatus_Busy:
                        statusTypeControl.selectedSegmentIndex = 2;
                        break;
                        
                    default:
                        statusTypeControl.selectedSegmentIndex = 0;
                        break;
                }
                
                [cell.contentView addSubview:statusTypeControl];
            }
            break;
        }
            
        case 1:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = @"Copy ID to clipboard";
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            
            break;
        }
            
        case 2:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            //Do nothing for first row in thi section (new dht node button)
            if (indexPath.row == 0)
                break;
            
            [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
            
            
            DHTNodeObject *tempDHT = [_dhtNodeList objectAtIndex:(indexPath.row - 1)];
            cell.textLabel.text = tempDHT.dhtName;
            
            UIActivityIndicatorView *activityConnecting = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(240, 12, 20, 20)];
            [activityConnecting setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
            [activityConnecting setTag:101];
            
            DHTNodeObject *currentDHT = [[Singleton sharedSingleton] currentConnectDHT];
            DHTNodeObject *cellDHT = [_dhtNodeList objectAtIndex:(indexPath.row - 1)];
            if ([currentDHT.dhtIP isEqualToString:cellDHT.dhtIP] &&
                [currentDHT.dhtPort isEqualToString:cellDHT.dhtPort] &&
                [currentDHT.dhtKey isEqualToString:cellDHT.dhtKey]) {
                //this cell has the ip, port, and key of the node currently connected/ing to
                
                if (currentDHT.connectionStatus == ToxDHTNodeConnectionStatus_Connected){
                    //do "Connected!"
                    [activityConnecting stopAnimating];
                    [activityConnecting setHidden:YES];
                    cell.detailTextLabel.text = @"Connected!";
                } else if (currentDHT.connectionStatus == ToxDHTNodeConnectionStatus_Connecting) {
                    //do the uiactivityview
                    [activityConnecting startAnimating];
                    [activityConnecting setHidden:NO];
                    cell.detailTextLabel.text = @"";
                }
            } else {
                //just a regular node in the list
                [activityConnecting stopAnimating];
                [activityConnecting setHidden:YES];
                cell.detailTextLabel.text = @"";
            }
           
            [cell.contentView addSubview:activityConnecting];
            
            break;
        }
            
        default:
            break;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row > 0) {
        [[tableView cellForRowAtIndexPath:indexPath] setShowsReorderControl:YES];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row > 0) {
        return YES;
    }
    
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    DHTNodeObject *tempDHT = [[_dhtNodeList objectAtIndex:(fromIndexPath.row - 1)] copy];
    
    [_dhtNodeList removeObjectAtIndex:(fromIndexPath.row - 1)];
    
    [_dhtNodeList insertObject:tempDHT atIndex:(toIndexPath.row - 1)];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete)
        return;
    
    [tableView beginUpdates];
    
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [_dhtNodeList removeObjectAtIndex:(indexPath.row - 1)];
    
    [tableView endUpdates];
}

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
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
    if (indexPath.section == 1 && indexPath.row == 0) {
        char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
        int pos = 0;
        uint8_t ourAddress[TOX_FRIEND_ADDRESS_SIZE];
        tox_get_address([[Singleton sharedSingleton] toxCoreInstance], ourAddress);
        for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", ourAddress[i] & 0xff);
        }
        
        [[UIPasteboard generalPasteboard] setString:[NSString stringWithUTF8String:convertedKey]];
    }
    else if (indexPath.section == 2 && indexPath.row == 0) {
        //new dht connection
        
        //get our new dht viewcontroller
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        NewDHTNodeViewController *newDHTViewCont = [sb instantiateViewControllerWithIdentifier:@"NewDHTView"];
        
        //compile an array of the names of nodes already in our list
        NSMutableArray *names = [[NSMutableArray alloc] init];
        for (DHTNodeObject *tempDHT in _dhtNodeList) {
            [names addObject:[tempDHT.dhtName copy]];
        }
        
        //pass along the lsit of names. prevents multiples
        [newDHTViewCont setNamesAlreadyPresent:names];
        
        [self.navigationController pushViewController:newDHTViewCont animated:YES];
    }
    else if (indexPath.section == 2 && indexPath.row != 0) {
        DHTNodeObject *currentDHT = [[Singleton sharedSingleton] currentConnectDHT];
        if (![currentDHT.dhtIP isEqualToString:@""] &&
            ![currentDHT.dhtPort isEqualToString:@""] &&
            ![currentDHT.dhtKey isEqualToString:@""]) {
            NSLog(@"return");
            //stop here because the current dht is either connecting or connected, so dont do anything
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }
        //connect to a node
        //gets called if the cell is actually that of a node, and we are not triyng to connect to a node, and if we're not connect
        
        //attempt connection        
        AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [ourDelegate connectToDHTWithIP:[[_dhtNodeList objectAtIndex:(indexPath.row - 1)] copy]];
        

        [self.tableView reloadData];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 2 && indexPath.row == 0)
        return;
    
    //edit dht connection
    
    //get our new dht viewcontroller
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    NewDHTNodeViewController *newDHTViewCont = [sb instantiateViewControllerWithIdentifier:@"NewDHTView"];
    
    //compile an array of the names of nodes already in our list. remove the name about to be edited
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (DHTNodeObject *tempDHT in _dhtNodeList) {
        if (![tempDHT.dhtName isEqualToString:[tableView cellForRowAtIndexPath:indexPath].textLabel.text]) {
            [names addObject:[tempDHT.dhtName copy]];
        }
    }
    
    DHTNodeObject *tempDHT = [_dhtNodeList objectAtIndex:(indexPath.row - 1)];
    //pass along the lsit of names. prevents multiples
    [newDHTViewCont setNamesAlreadyPresent:names];
    
    [newDHTViewCont setEditingMode:YES];
    [newDHTViewCont setPathToEdit:indexPath];
    [newDHTViewCont setAlreadyName:[tempDHT.dhtName copy]];
    [newDHTViewCont setAlreadyIP:[tempDHT.dhtIP copy]];
    [newDHTViewCont setAlreadyPort:[tempDHT.dhtPort copy]];
    [newDHTViewCont setAlreadyKey:[tempDHT.dhtKey copy]];
    
    [self.navigationController pushViewController:newDHTViewCont animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    //Only lets moveable rows in the second section, and only and row not the first in the second section.
    
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        NSInteger row = 1;
        if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
            row = [tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
        }
        return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
    }
    
    return [NSIndexPath indexPathForRow:(proposedDestinationIndexPath.row ? proposedDestinationIndexPath.row : 1) inSection:sourceIndexPath.section];
}

#pragma mark - Text field delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UITapGestureRecognizer *tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
//    [tapToDismiss setCancelsTouchesInView:NO];
    
    [self.view addGestureRecognizer:tapToDismiss];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

- (void)dismissKeyboard:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
    
    [self.view removeGestureRecognizer:sender];
    
    if (![nameTextField.text isEqualToString:[[Singleton sharedSingleton] userNick]]) {
        //they changed their name
        
        [[Singleton sharedSingleton] setUserNick:[nameTextField text]];
        AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [ourDelegate userNickChanged];
    }
    
    if (![statusTextField.text isEqualToString:[[Singleton sharedSingleton] userStatusMessage]]) {
        //they changed their name
        
        [[Singleton sharedSingleton] setUserStatusMessage:[statusTextField text]];
        AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [ourDelegate userStatusChanged];
    }
}

#pragma mark - Segmented Control Delegate

- (void)userStatusTypeDidChange:(id)sender {
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    switch (segment.selectedSegmentIndex) {
        case 0:
            [[Singleton sharedSingleton] setUserStatusType:ToxFriendUserStatus_None];
            break;

        case 1:
            [[Singleton sharedSingleton] setUserStatusType:ToxFriendUserStatus_Away];
            break;
            
        case 2:
            [[Singleton sharedSingleton] setUserStatusType:ToxFriendUserStatus_Busy];
            break;
        default:
            break;
    }
    AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [ourDelegate userStatusTypeChanged];
}

@end
