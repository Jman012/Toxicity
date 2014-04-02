//
// Created by Виктор Шаманов on 3/19/14.
// Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCChatViewController.h"
#import "UIColor+ToxicityColors.h"


@implementation TXCChatViewController

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];

    self.backgroundColor = [UIColor toxicityBackgroundLightColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollToBottomAnimated:NO];
}

@end