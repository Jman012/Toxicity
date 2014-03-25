//
//  TXCSettingsViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCSettingsViewController.h"
#import "InputCell.h"
#import "StatusCell.h"
#import "TXCQRCodeViewController.h"
#import "TXCNewDHTNodeViewController.h"
#import "TXCSingleton.h"
#import "TXCAppDelegate.h"

#include "tox.h"

static NSString *const QRCodeViewControllerIdentifier = @"TXCQRCodeViewController";
extern NSString *const ToxNewDHTNodeViewControllerNotificatiobNewDHT;
extern NSString *const ToxAppDelegateNotificationDHTConnected ;
extern NSString *const ToxAppDelegateNotificationDHTDisconnected ;

@interface TXCSettingsViewController () <UITabBarControllerDelegate, UITextFieldDelegate>

@end

@implementation TXCSettingsViewController

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dhtNodeList = [TXCSingleton sharedSingleton].dhtNodeList;
}

#pragma mark - Actions

- (IBAction)returnButtonPressedInTextField:(UITextField *)textField {
    [textField resignFirstResponder];
}

#pragma mark - Private methods

- (NSString *)clientID {
    char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
    int pos = 0;
    uint8_t ourAddress[TOX_FRIEND_ADDRESS_SIZE];
    tox_get_address([[TXCSingleton sharedSingleton] toxCoreInstance], ourAddress);
    for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", ourAddress[i] & 0xff);
    }
    return [NSString stringWithUTF8String:convertedKey];
}

- (void)addDHTServer:(NSNotification *)notification {
    
    if ([notification.userInfo[@"editing"] isEqualToString:@"yes"]) {
                
        NSIndexPath *path = notification.userInfo[@"indexpath"];
        TXCDHTNodeObject *tempDHT = _dhtNodeList[path.row - 1];
        tempDHT.dhtName = notification.userInfo[@"dht_name"];
        tempDHT.dhtIP = notification.userInfo[@"dht_ip"];
        tempDHT.dhtPort = notification.userInfo[@"dht_port"];
        tempDHT.dhtKey = notification.userInfo[@"dht_key"];
        
        [self.tableView reloadData];
        
        NSLog(@"Saving dhts");
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [[TXCSingleton sharedSingleton].dhtNodeList enumerateObjectsUsingBlock:^(TXCDHTNodeObject *arrayDHT, NSUInteger idx, BOOL *stop) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:arrayDHT.copy];
            [array addObject:data];
        }];
        [prefs setObject:array forKey:@"dht_node_list"];
        [prefs synchronize];
        
    } else {
        
        [self.tableView beginUpdates];
        
        TXCDHTNodeObject *tempDHT = [[TXCDHTNodeObject alloc] init];
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
        [[TXCSingleton sharedSingleton].dhtNodeList enumerateObjectsUsingBlock:^(TXCDHTNodeObject *arrayDHT, NSUInteger idx, BOOL *stop) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:arrayDHT.copy];
            [array addObject:data];
        }];
        [prefs setObject:array forKey:@"dht_node_list"];
        [prefs synchronize];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addDHTServer:)
                                                 name:ToxNewDHTNodeViewControllerNotificatiobNewDHT
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dhtConnected:)
                                                 name:ToxAppDelegateNotificationDHTConnected
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dhtDisconnected:)
                                                 name:ToxAppDelegateNotificationDHTDisconnected
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

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    if (![self.nameTextField.text isEqualToString:[TXCSingleton sharedSingleton].userNick]) {
        //they changed their name
        
        [TXCSingleton sharedSingleton].userNick = self.nameTextField.text;
        
        TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate userNickChanged];
        
    }
    
    if (![self.statusTextField.text isEqualToString:[TXCSingleton sharedSingleton].userStatusMessage]) {
        //they changed their name
        
        [TXCSingleton sharedSingleton].userStatusMessage = self.statusTextField.text;
        TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate userStatusChanged];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
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
            return self.dhtNodeList.count + 1;
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
                        inputCell.textField.text = [TXCSingleton sharedSingleton].userNick;
                        self.nameTextField = inputCell.textField;
                        break;
                    case 1:
                        inputCell.titleLabel.text = @"Status:";
                        inputCell.textField.text = [TXCSingleton sharedSingleton].userStatusMessage;
                        self.statusTextField = inputCell.textField;
                        break;
                }

            } else {
                //segmented control for status type

                StatusCell *statusCell = (StatusCell *)cell;

                switch ([TXCSingleton sharedSingleton].userStatusType) {
                    case TXCToxFriendUserStatus_None:
                        statusCell.segmentedControl.selectedSegmentIndex = 0;
                        break;

                    case TXCToxFriendUserStatus_Away:
                        statusCell.segmentedControl.selectedSegmentIndex = 1;
                        break;

                    case TXCToxFriendUserStatus_Busy:
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


            TXCDHTNodeObject *tempDHT = self.dhtNodeList[indexPath.row - 1];
            cell.textLabel.text = tempDHT.dhtName;

            UIActivityIndicatorView *activityConnecting = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(240, 12, 20, 20)];
            activityConnecting.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            activityConnecting.tag = 101;

            TXCDHTNodeObject *currentDHT = [TXCSingleton sharedSingleton].currentConnectDHT;
            TXCDHTNodeObject *cellDHT = self.dhtNodeList[indexPath.row - 1];
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
    
    TXCDHTNodeObject *tempDHT = [[self.dhtNodeList objectAtIndex:(fromIndexPath.row - 1)] copy];
    
    [self.dhtNodeList removeObjectAtIndex:(fromIndexPath.row - 1)];
    
    [self.dhtNodeList insertObject:tempDHT atIndex:(toIndexPath.row - 1)];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete)
        return;

    [tableView beginUpdates];

    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.dhtNodeList removeObjectAtIndex:(indexPath.row - 1)];

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
        TXCNewDHTNodeViewController *newDHTViewCont = [sb instantiateViewControllerWithIdentifier:@"NewDHTView"];

        //compile an array of the names of nodes already in our list
        NSMutableArray *names = [[NSMutableArray alloc] init];
        [self.dhtNodeList enumerateObjectsUsingBlock:^(TXCDHTNodeObject *tempDHT, NSUInteger idx, BOOL *stop) {
            [names addObject:tempDHT.dhtName.copy];
        }];

        //pass along the lsit of names. prevents multiples
        [newDHTViewCont setNamesAlreadyPresent:names];

        [self.navigationController pushViewController:newDHTViewCont animated:YES];
    }
    else if (indexPath.section == 2 && indexPath.row != 0) {
        TXCDHTNodeObject *currentDHT = [[TXCSingleton sharedSingleton] currentConnectDHT];
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
        TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate connectToDHTWithIP:[self.dhtNodeList[indexPath.row - 1] copy]];



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
    TXCNewDHTNodeViewController *newDHTViewCont = [sb instantiateViewControllerWithIdentifier:@"NewDHTView"];
    
    //compile an array of the names of nodes already in our list. remove the name about to be edited
    NSIndexSet *indexSet = [self.dhtNodeList indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        TXCDHTNodeObject *node = (TXCDHTNodeObject *)obj;
        return ![node.dhtName isEqualToString:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
    }];
    NSArray *names = [self.dhtNodeList objectsAtIndexes:indexSet];

    TXCDHTNodeObject *tempDHT = self.dhtNodeList[indexPath.row - 1];
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
    
    if (![self.nameTextField.text isEqualToString:[TXCSingleton sharedSingleton].userNick]) {
        //they changed their name
        
        [TXCSingleton sharedSingleton].userNick = self.nameTextField.text;
        TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate userNickChanged];
    }
    
    if (![self.statusTextField.text isEqualToString:[TXCSingleton sharedSingleton].userStatusMessage]) {
        //they changed their name
        
        [TXCSingleton sharedSingleton].userStatusMessage = self.statusTextField.text;
        TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[UIApplication sharedApplication].delegate;
        [ourDelegate userStatusChanged];
    }
}

#pragma mark - Segmented Control Delegate

- (IBAction)userStatusTypeDidChange:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            [TXCSingleton sharedSingleton].userStatusType = TXCToxFriendUserStatus_None;
            break;

        case 1:
            [TXCSingleton sharedSingleton].userStatusType = TXCToxFriendUserStatus_Away;
            break;
            
        case 2:
            [TXCSingleton sharedSingleton].userStatusType = TXCToxFriendUserStatus_Busy;
            break;
        default: break;
    }
    TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[UIApplication sharedApplication].delegate;
    [ourDelegate userStatusTypeChanged];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:QRCodeViewControllerIdentifier]) {
        TXCQRCodeViewController *qrCodeViewController = segue.destinationViewController;
        qrCodeViewController.code = self.clientID;
    }
}

@end
