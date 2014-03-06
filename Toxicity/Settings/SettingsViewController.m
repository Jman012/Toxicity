//
//  SettingsViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "SettingsViewController.h"
#import "InputCell.h"
#import "StatusCell.h"
#import "QRCodeViewController.h"

static NSString *const QRCodeViewControllerIdentifier = @"QRCodeViewController";

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (NSString *)clientID {
    char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
    int pos = 0;
    uint8_t ourAddress[TOX_FRIEND_ADDRESS_SIZE];
    tox_get_address([[Singleton sharedSingleton] toxCoreInstance], ourAddress);
    for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", ourAddress[i] & 0xff);
    }
    return [NSString stringWithUTF8String:convertedKey];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _dhtNodeList = [Singleton sharedSingleton].dhtNodeList;
}

- (void)addDHTServer:(NSNotification *)notification {
    
    if ([notification.userInfo[@"editing"] isEqualToString:@"yes"]) {
                
        NSIndexPath *path = notification.userInfo[@"indexpath"];
        DHTNodeObject *tempDHT = _dhtNodeList[path.row - 1];
        tempDHT.dhtName = notification.userInfo[@"dht_name"];
        tempDHT.dhtIP = notification.userInfo[@"dht_ip"];
        tempDHT.dhtPort = notification.userInfo[@"dht_port"];
        tempDHT.dhtKey = notification.userInfo[@"dht_key"];
        
        [self.tableView reloadData];
        
        NSLog(@"Saving dhts");
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (DHTNodeObject *arrayDHT in [Singleton sharedSingleton].dhtNodeList) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:arrayDHT.copy];
            [array addObject:data];
        }
        [prefs setObject:array forKey:@"dht_node_list"];
        [prefs synchronize];
        
    } else {
        
        [self.tableView beginUpdates];
        
        DHTNodeObject *tempDHT = [[DHTNodeObject alloc] init];
        tempDHT.dhtName = notification.userInfo[@"dht_name"];
        tempDHT.dhtIP = notification.userInfo[@"dht_ip"];
        tempDHT.dhtPort = notification.userInfo[@"dht_port"];
        tempDHT.dhtKey = notification.userInfo[@"dht_key"];
        tempDHT.connectionStatus = ToxDHTNodeConnectionStatus_NotConnected;
        [_dhtNodeList addObject:tempDHT];
        
        NSArray *paths = @[[NSIndexPath indexPathForRow:_dhtNodeList.count inSection:2]];
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        NSLog(@"Saving dhts");
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (DHTNodeObject *arrayDHT in [Singleton sharedSingleton].dhtNodeList) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:arrayDHT.copy];
            [array addObject:data];
        }
        [prefs setObject:array forKey:@"dht_node_list"];
        [prefs synchronize];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addDHTServer:)
                                                 name:@"NewDHT"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dhtConnected:)
                                                 name:@"DHTConnected"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dhtDisconnected:)
                                                 name:@"DHTDisonnected"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didStartDHTNodeConnection:)
                                                 name:@"DidStartDHTNodeConnection"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFailToConnect:)
                                                 name:@"DHTFailedToConnect"
                                               object:nil];
}


- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)dhtConnected:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)dhtDisconnected:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)didStartDHTNodeConnection:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)didFailToConnect:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (IBAction)saveButtonPushed:(id)sender {
    if (![nameTextField.text isEqualToString:[Singleton sharedSingleton].userNick]) {
        //they changed their name
        
        [Singleton sharedSingleton].userNick = nameTextField.text;
        
        AppDelegate *ourDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate userNickChanged];
        
    }
    
    if (![statusTextField.text isEqualToString:[Singleton sharedSingleton].userStatusMessage]) {
        //they changed their name
        
        [Singleton sharedSingleton].userStatusMessage = statusTextField.text;
        AppDelegate *ourDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate userStatusChanged];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editButtonPushed:(id)sender {
    UIBarButtonItem *doneEditingButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                          style:UIBarButtonItemStyleDone
                                                                         target:self
                                                                         action:@selector(doneEditingButtonPushed)];

    self.navigationItem.leftBarButtonItem = doneEditingButton;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.tableView setEditing:YES animated:YES];
}

- (void)doneEditingButtonPushed {
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(editButtonPushed:)];

    self.navigationItem.leftBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 3;
        case 1:
            return 2;
        case 2:
            //Add ones for the row to add a new server
            return _dhtNodeList.count + 1;
        default:break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier;
    if (indexPath.section == 0 && indexPath.row != 2) {
        CellIdentifier = @"settingsInfoCell";
    } else if (indexPath.section == 0 && indexPath.row == 2) {
        CellIdentifier = @"settingsStatusCell";
    } else if (indexPath.section == 1) {
        CellIdentifier = @"settingsCopyIDCell";
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        CellIdentifier = @"settingsNewDHTCell";
    } else if (indexPath.section == 2 && indexPath.row >= 1) {
        CellIdentifier = @"settingsDHTCell";
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    // Configure the cell...
    switch (indexPath.section) {
        case 0: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if (indexPath.row != 2) {
                //name/status message field
                
                InputCell *inputCell = (InputCell *)cell;
                inputCell.textField.delegate = self;

                switch (indexPath.row) {
                    case 0:
                        inputCell.titleLabel.text = @"Name:";
                        inputCell.textField.text = [Singleton sharedSingleton].userNick;
                        nameTextField = inputCell.textField;
                        break;
                    case 1:
                        inputCell.titleLabel.text = @"Status:";
                        inputCell.textField.text = [Singleton sharedSingleton].userStatusMessage;
                        statusTextField = inputCell.textField;
                        break;
                }

            } else {
                //segmented control for status type

                StatusCell *statusCell = (StatusCell *)cell;

                switch ([Singleton sharedSingleton].userStatusType) {
                    case ToxFriendUserStatus_None:
                        statusCell.segmentedControl.selectedSegmentIndex = 0;
                        break;

                    case ToxFriendUserStatus_Away:
                        statusCell.segmentedControl.selectedSegmentIndex = 1;
                        break;

                    case ToxFriendUserStatus_Busy:
                        statusCell.segmentedControl.selectedSegmentIndex = 2;
                        break;

                    default:
                        statusCell.segmentedControl.selectedSegmentIndex = 0;
                        break;
                }

            }
            break;
        }

        case 1: {

            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;

            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Copy ID to clipboard";
                    break;
                case 1:
                    cell.textLabel.text = @"Generate QR-Code";
                    break;
                default:break;
            }

            break;
        }

        case 2: {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;

            //Do nothing for first row in thi section (new dht node button)
            if (indexPath.row == 0)
                break;

            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;


            DHTNodeObject *tempDHT = _dhtNodeList[indexPath.row - 1];
            cell.textLabel.text = tempDHT.dhtName;

            UIActivityIndicatorView *activityConnecting = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(240, 12, 20, 20)];
            activityConnecting.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            activityConnecting.tag = 101;

            DHTNodeObject *currentDHT = [Singleton sharedSingleton].currentConnectDHT;
            DHTNodeObject *cellDHT = _dhtNodeList[indexPath.row - 1];
            if ([currentDHT.dhtIP isEqualToString:cellDHT.dhtIP] &&
                [currentDHT.dhtPort isEqualToString:cellDHT.dhtPort] &&
                [currentDHT.dhtKey isEqualToString:cellDHT.dhtKey]) {
                //this cell has the ip, port, and key of the node currently connected/ing to

                if (currentDHT.connectionStatus == ToxDHTNodeConnectionStatus_Connected){
                    //do "Connected!"
                    [activityConnecting stopAnimating];
                    activityConnecting.hidden = YES;
                    cell.detailTextLabel.text = @"Connected!";
                } else if (currentDHT.connectionStatus == ToxDHTNodeConnectionStatus_Connecting) {
                    //do the uiactivityview
                    [activityConnecting startAnimating];
                    activityConnecting.hidden = NO;
                    cell.detailTextLabel.text = @"";
                }
            } else {
                //just a regular node in the list
                [activityConnecting stopAnimating];
                activityConnecting.hidden = YES;
                cell.detailTextLabel.text = @"";
            }

            [cell.contentView addSubview:activityConnecting];

            break;
        }
            
        default:break;
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row > 0) {
        [tableView cellForRowAtIndexPath:indexPath].showsReorderControl = YES;
        
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

    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [_dhtNodeList removeObjectAtIndex:(indexPath.row - 1)];

    [tableView endUpdates];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == 0) {
        NSString *myId = [self clientID];

        [[UIPasteboard generalPasteboard] setString:myId];

    } else if (indexPath.section == 1 && indexPath.row == 1) {
        [self performSegueWithIdentifier:QRCodeViewControllerIdentifier sender:self];
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        //new dht connection

        //get our new dht viewcontroller
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        NewDHTNodeViewController *newDHTViewCont = [sb instantiateViewControllerWithIdentifier:@"NewDHTView"];

        //compile an array of the names of nodes already in our list
        NSMutableArray *names = [[NSMutableArray alloc] init];
        for (DHTNodeObject *tempDHT in _dhtNodeList) {
            [names addObject:tempDHT.dhtName.copy];
        }

        //pass along the lsit of names. prevents multiples
        [newDHTViewCont setNamesAlreadyPresent:names];

        [self.navigationController pushViewController:newDHTViewCont animated:YES];
    }
    else if (indexPath.section == 2 && indexPath.row != 0) {
        DHTNodeObject *currentDHT = [[Singleton sharedSingleton] currentConnectDHT];
        if (currentDHT.dhtIP.length &&
            currentDHT.dhtPort.length &&
            currentDHT.dhtKey.length) {
            NSLog(@"return");
            //stop here because the current dht is either connecting or connected, so dont do anything
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }
        //connect to a node
        //gets called if the cell is actually that of a node, and we are not triyng to connect to a node, and if we're not connect

        //attempt connection
        AppDelegate *ourDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate connectToDHTWithIP:[_dhtNodeList[indexPath.row - 1] copy]];



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
    NSIndexSet *indexSet = [_dhtNodeList indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        DHTNodeObject *node = (DHTNodeObject *)obj;
        return ![node.dhtName isEqualToString:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
    }];
    NSArray *names = [_dhtNodeList objectsAtIndexes:indexSet];

    DHTNodeObject *tempDHT = _dhtNodeList[indexPath.row - 1];
    //pass along the lsit of names. prevents multiples
    newDHTViewCont.namesAlreadyPresent = names;
    
    newDHTViewCont.editingMode = YES;
    newDHTViewCont.pathToEdit = indexPath;
    newDHTViewCont.alreadyName = tempDHT.dhtName.copy;
    newDHTViewCont.alreadyIP = tempDHT.dhtIP.copy;
    newDHTViewCont.alreadyPort = tempDHT.dhtPort.copy;
    newDHTViewCont.alreadyKey = tempDHT.dhtKey.copy;
    
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
    
    return [NSIndexPath indexPathForRow:(proposedDestinationIndexPath.row ? proposedDestinationIndexPath.row : 1)
                              inSection:sourceIndexPath.section];
}

#pragma mark - Text field delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UITapGestureRecognizer *tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(dismissKeyboard:)];
//    [tapToDismiss setCancelsTouchesInView:NO];
    
    [self.view addGestureRecognizer:tapToDismiss];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

- (void)dismissKeyboard:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
    
    [self.view removeGestureRecognizer:sender];
    
    if (![nameTextField.text isEqualToString:[Singleton sharedSingleton].userNick]) {
        //they changed their name
        
        [Singleton sharedSingleton].userNick = nameTextField.text;
        AppDelegate *ourDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate userNickChanged];
    }
    
    if (![statusTextField.text isEqualToString:[Singleton sharedSingleton].userStatusMessage]) {
        //they changed their name
        
        [Singleton sharedSingleton].userStatusMessage = statusTextField.text;
        AppDelegate *ourDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate userStatusChanged];
    }
}

#pragma mark - Segmented Control Delegate

- (IBAction)userStatusTypeDidChange:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            [Singleton sharedSingleton].userStatusType = ToxFriendUserStatus_None;
            break;

        case 1:
            [Singleton sharedSingleton].userStatusType = ToxFriendUserStatus_Away;
            break;
            
        case 2:
            [Singleton sharedSingleton].userStatusType = ToxFriendUserStatus_Busy;
            break;
        default: break;
    }
    AppDelegate *ourDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [ourDelegate userStatusTypeChanged];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:QRCodeViewControllerIdentifier]) {
        QRCodeViewController *qrCodeViewController = segue.destinationViewController;
        qrCodeViewController.code = self.clientID;
    }
}

@end
