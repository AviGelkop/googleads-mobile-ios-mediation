//
//  GADMediationAdapterFyber.m
//  Adapter
//
//  Created by Avi Gelkop on 8/8/19.
//  Copyright © 2019 Google. All rights reserved.
//


#import "GADMediationAdapterFyber.h"

@import IASDKCore;

static NSString * const _Nonnull kFYBApplicationID = @"applicationId";
static NSString * const _Nonnull kFYBSpotID = @"spotId";

static NSString * const _Nonnull kFYBBanner = @"kFYBBanner";
static NSString * const _Nonnull kFYBInterstitial = @"kFYBInterstitial";
static NSString * const _Nonnull kFYBRewarded = @"kFYBRewarded";

@interface GADMediationAdapterFyber ()

@property (nonatomic, nonnull) id<GADMAdNetworkConnector> connector;

@property (nonatomic, nullable, strong) NSMutableDictionary <NSString *, IAUnitController *> *IAUnitControllers;
@property (nonatomic, nullable, strong) NSMutableDictionary <NSString *, IAContentController *> *IAContentControllers;
@property (nonatomic, nullable, strong) NSMutableDictionary <NSString *, IAAdSpot *> *IAAdspots;

@end

@implementation GADMediationAdapterFyber

+ (NSString *)adapterVersion {
    return @"";
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return self.class;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
    self = [super init];
    
    if (self) {
        _connector = connector;
        _IAUnitControllers = [NSMutableDictionary new];
        _IAContentControllers = [NSMutableDictionary new];
        _IAAdspots = [NSMutableDictionary new];
    }
    
    if (self.connector) {
        NSString *appID = [self.connector credentials][kFYBApplicationID];
        
        if (appID) {
            [[IASDKCore sharedInstance] initWithAppID:appID];
            [IALogger setLogLevel:IALogLevelInfo];
        } else {
            NSLog(@"Failed to init Fyber marketplace SDK. Reason: can't get application ID");
        }
    }
    return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
    NSString *spotId = [self.connector credentials][kFYBSpotID];
    if (self.IAAdspots[spotId]) {
        
    } else {
        [self initSpot:spotId adType:kFYBBanner];
    }
}

- (void)getInterstitial {

}

- (void)stopBeingDelegate {
    
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    
}

#pragma mark - Service

- (void)initSpot:(NSString * _Nonnull)spotId adType:(NSString * _Nonnull)adType {

}

@end
