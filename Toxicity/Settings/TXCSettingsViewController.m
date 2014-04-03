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
            
        default:break;
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == 0) {
        NSString *myId = [self clientID];

        [[UIPasteboard generalPasteboard] setString:myId];

    } else if (indexPath.section == 1 && indexPath.row == 1) {
        [self performSegueWithIdentifier:QRCodeViewControllerIdentifier sender:self];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

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
