//
//  RNPostViewController.m
//  RNCardStreamDemo
//
//  Created by Ryan Nystrom on 7/24/14.
//  Copyright (c) 2014 Ryan Nystrom. All rights reserved.
//

#import "RNPostViewController.h"

@interface RNPostViewController ()

@property (nonatomic, strong) NSDictionary *item;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *postLabel;

@end

@implementation RNPostViewController

- (instancetype)initWithItem:(NSDictionary *)item {
    if (self = [super init]) {
        _item = item;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.clipsToBounds = YES;
    self.nameLabel.text = self.item[@"name"];
    self.postLabel.text = self.item[@"text"];
}

- (IBAction)onDone:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
