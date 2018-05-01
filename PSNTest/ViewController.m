//
//  ViewController.m
//  PSNTest
//
//  Created by Jeremy Blaker on 4/30/18.
//  Copyright © 2018 Five Sigma Studio. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<WKNavigationDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet WKWebView *webView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *entitlements;

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.webView.navigationDelegate = self;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://store.playstation.com"]]];
}

- (void)doThing
{
    NSString *script = @"function getEntitlements() { var instance = Ember.Application.NAMESPACES_BY_ID[\"valkyrie-storefront\"].__container__; var ents = instance.lookup(\"service:macross-brain\").macrossBrainInstance.getEntitlementStore().getAllEntitlements(); var results = instance.lookup(\"service:macross-brain\").macrossBrainInstance._entitlementStore._storage._entitlementMapCache; return results} getEntitlements()";
    [self.webView evaluateJavaScript:script completionHandler:^(id _Nullable jesus, NSError * _Nullable error) {
        if ([jesus isKindOfClass:NSDictionary.class]) {
            [self handleEntitlements:jesus];
        }
    }];
}

- (void)handleEntitlements:(NSDictionary *)entitlements
{
    NSMutableArray *tempEntitlements = [NSMutableArray new];
    
    for (NSDictionary *entitlement in [entitlements allValues]) {
        if ([self isValidEntitlement:entitlement]) {
            NSDictionary *gameMeta = entitlement[@"game_meta"];
            NSString *name = gameMeta[@"name"];
            [tempEntitlements addObject:name];
        }
    }
    
    self.entitlements = [NSArray arrayWithArray:tempEntitlements];
    self.webView.hidden = YES;
    [self.tableView reloadData];
}

- (BOOL)isValidEntitlement:(NSDictionary *)dict
{
    NSNumber *entitlementType = dict[@"entitlement_type"];
    if (entitlementType.integerValue == 1 || entitlementType.integerValue == 4) {
        return NO;
    }
    
    NSDictionary *drmDef = dict[@"drm_def"];
    NSString *contentType = drmDef[@"contentType"];
    if ([contentType isEqualToString:@"TV"]) {
        return NO;
    }
    
    NSDictionary *license = dict[@"license"];
    BOOL inf = [license[@"infinite_duration"] boolValue];
    if (!inf) {
        // Check date to see if expired
        //NSDate *exp = ;
    }
    
    return YES;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    [self performSelector:@selector(doThing) withObject:nil afterDelay:5.0];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.entitlements.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EntitlementCell"];
    cell.textLabel.text = self.entitlements[indexPath.row];
    return cell;
}

@end
