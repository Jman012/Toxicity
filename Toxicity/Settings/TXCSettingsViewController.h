//
//  TXCSettingsViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TXCSettingsViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *dhtNodeList;
@property (nonatomic, strong) UITextField *statusTextField;
@property (nonatomic, strong) UITextField *nameTextField;
- (IBAction)saveButtonPushed:(id)sender;

@end
