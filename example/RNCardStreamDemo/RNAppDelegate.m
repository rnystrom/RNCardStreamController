//
//  RNAppDelegate.m
//  RNCardStreamDemo
//
//  Created by Ryan Nystrom on 7/21/14.
//  Copyright (c) 2014 Ryan Nystrom. All rights reserved.
//

#import "RNAppDelegate.h"
#import "RNCardStreamController.h"
#import "RNSampleCardView.h"
#import "RNSampleImageView.h"
#import "RNSampleSectionView.h"
#import "RNPostViewController.h"
#import "RNImageViewController.h"

@interface RNAppDelegate ()
<RNCardStreamControllerDataSource>

@property (nonatomic, strong) NSArray *sections;

@end

@implementation RNAppDelegate

NSString * const SampleViewIdentifier = @"SampleViewIdentifier";
NSString * const SampleImageIdentifier = @"SampleImageIdentifier";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"]];
    self.sections = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]; // don't nil errors!
    
    RNCardStreamController *card = [[RNCardStreamController alloc] init];
    card.dataSource = self;
    
    [card registerNib:[UINib nibWithNibName:@"RNSampleCardView" bundle:nil] forReuseIdentifier:SampleViewIdentifier];
    [card registerNib:[UINib nibWithNibName:@"RNSampleImageView" bundle:nil] forReuseIdentifier:SampleImageIdentifier];
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:card];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (UIColor *)randomColor {
    // https://gist.github.com/kylefox/1689973
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

#pragma mark - RNCardStreamControllerDataSource

- (NSInteger)numberOfSectionsInCardStreamController:(RNCardStreamController *)cardStreamController {
    return self.sections.count;
}

- (NSInteger)cardStreamController:(RNCardStreamController *)cardStreamController numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dic = self.sections[section];
    NSArray *feed = dic[@"feed"];
    return feed.count;
}

- (UIView *)cardStreamController:(RNCardStreamController *)cardStreamController viewForSection:(NSInteger)section {
    RNSampleSectionView *view = [[[UINib nibWithNibName:@"RNSampleSectionView" bundle:nil] instantiateWithOwner:nil options:nil] firstObject];
    
    NSDictionary *dic = self.sections[section];
    
    view.imageView.image = [UIImage imageNamed:dic[@"image"]];
    view.textLabel.text = dic[@"text"];
        
    return view;
}

- (UIView *)cardStreamController:(RNCardStreamController *)cardStreamController viewForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dic = self.sections[indexPath.section];
    NSArray *feed = dic[@"feed"];
    NSDictionary *item = feed[indexPath.row];
    NSString *type = item[@"type"];
    
    id view;
    
    if ([type isEqualToString:@"post"]) {
        RNSampleCardView *post = [cardStreamController dequeReusableViewWithIdentifier:SampleViewIdentifier];
        post.nameLabel.text = item[@"name"];
        post.postDetailLabel.text = item[@"text"];
        view = post;
    } else if ([type isEqualToString:@"image"]) {
        RNSampleImageView *image = [cardStreamController dequeReusableViewWithIdentifier:SampleImageIdentifier];
        image.imageView.image = [UIImage imageNamed:item[@"image"]];
        image.textLabel.text = item[@"text"];
        view = image;
    }
    
    return view;
}

- (UIViewController *)cardStreamController:(RNCardStreamController *)cardStreamController controllerForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dic = self.sections[indexPath.section];
    NSArray *feed = dic[@"feed"];
    NSDictionary *item = feed[indexPath.row];
    NSString *type = item[@"type"];
    
    id controller;
    
    if ([type isEqualToString:@"post"]) {
        RNPostViewController *post = [[RNPostViewController alloc] initWithItem:item];
        controller = post;
    } else if ([type isEqualToString:@"image"]) {
        RNImageViewController *image = [[RNImageViewController alloc] initWithItem:item];
        controller = image;
    }
    
    return controller;
}

@end
