//
//  RNSampleImageView.m
//  RNCardStreamDemo
//
//  Created by Ryan Nystrom on 7/24/14.
//  Copyright (c) 2014 Ryan Nystrom. All rights reserved.
//

#import "RNSampleImageView.h"

@implementation RNSampleImageView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = 4;
    self.layer.borderColor = [UIColor colorWithWhite:0.4 alpha:1].CGColor;
    self.layer.borderWidth = 0.5;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 2);
    self.layer.shadowRadius = 3;
    self.layer.shadowOpacity = 0.4;
    self.clipsToBounds = NO;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = 4;
}

@end
