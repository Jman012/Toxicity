//
//  SettingsViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewDHTNodeViewController.h"
#import "Singleton.h"
#import "Messenger.h"
#import "network.h"

@interface SettingsViewController : UITableViewController <UITabBarControllerDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    NSMutableArray      *_dhtNodeList;
    
//    NSIndexPath         *currentlyConnectedIndex;
//    NSTimer             *connectTimeoutTimer;
    
    UITextField         *nameTextField;
    UITextField         *statusTextField;
}

- (IBAction)saveButtonPushed:(id)sender;

@end
