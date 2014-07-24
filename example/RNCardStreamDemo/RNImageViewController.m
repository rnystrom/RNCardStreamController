//
//  RNImageViewController.m
//  RNCardStreamDemo
//
//  Created by Ryan Nystrom on 7/24/14.
//  Copyright (c) 2014 Ryan Nystrom. All rights reserved.
//

#import "RNImageViewController.h"

@interface RNImageViewController ()

@property (nonatomic, strong) NSDictionary *item;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end

@implementation RNImageViewController

- (instancetype)initWithItem:(NSDictionary *)item {
    if (self = [super init]) {
        _item = item;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.clipsToBounds = YES;
    self.imageView.image = [UIImage imageNamed:self.item[@"image"]];
    self.detailLabel.text = self.item[@"text"];
}

- (IBAction)onDone:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
