//
//  GADMediationAdapterFyber.m
//  Adapter
//
//  Created by Avi Gelkop on 8/8/19.
//  Copyright © 2019 Google. All rights reserved.
//


#import "GADMediationAdapterFyber.h"

@import IASDKCore;
@import IASDKVideo;
@import IASDKMRAID;
@import CoreLocation;

static NSString * const _Nonnull kFYBApplicationID = @"applicationId";
static NSString * const _Nonnull kFYBSpotID = @"spotId";

typedef NS_ENUM(NSInteger, FYBAdType) {
  FYBAdTypeBanner = 0,
  FYBAdTypeInterstitial = 1,
  FYBAdTypeRewarded = 2,
};

@interface GADMediationAdapterFyber () <IAUnitDelegate, GADMediationAdapter, GADMAdNetworkAdapter>

@property (nonatomic, nonnull) id<GADMAdNetworkConnector> connector;

@property (nonatomic, strong, nonnull) IAViewUnitController *viewUnitController;
@property (nonatomic, strong, nonnull) IAFullscreenUnitController *fullscreenUnitController;

@property (nonatomic, strong, nonnull) IAMRAIDContentController *MRAIDContentController;
@property (nonatomic, strong, nonnull) IAVideoContentController *videoContentController;

@property (nonatomic, strong) IAAdSpot *adSpot;
@property (nonatomic, weak) IAAdView *adView;

@end

@implementation GADMediationAdapterFyber

+ (NSString *)adapterVersion {
    return @"";
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return self.class;
}

+ (GADVersionNumber)adSDKVersion {
    GADVersionNumber version = {0};
    return version;
}


+ (GADVersionNumber)version {
    GADVersionNumber version = {0};
    return version;
}


- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
    self = [super init];
    
    if (self) {
        _connector = connector;
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
    __weak typeof(self) weakSelf = self;
    NSString *spotId = [self.connector credentials][kFYBSpotID];
    
    [self initSpot:spotId adType:FYBAdTypeBanner];
    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        if (error) {
            [weakSelf.connector adapter:weakSelf didFailAd:error];
        } else {
            [weakSelf.connector adapter:weakSelf didReceiveAdView:weakSelf.viewUnitController.adView];
        }
    }];
}

- (void)getInterstitial {
    __weak typeof(self) weakSelf = self;
    NSString *spotId = [self.connector credentials][kFYBSpotID];
    
    [self initSpot:spotId adType:FYBAdTypeInterstitial];
    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        if (error) {
            [weakSelf.connector adapter:weakSelf didFailAd:error];
        } else {
            [weakSelf.connector adapterDidReceiveInterstitial:weakSelf];
        }
    }];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    
}

- (void)stopBeingDelegate {
    
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    [self.fullscreenUnitController showAdAnimated:YES completion:nil];
}

#pragma mark - Service

- (void)initSpot:(NSString * _Nonnull)spotId adType:(FYBAdType)adType {
    __weak typeof(self) weakSelf = self;
    
    IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
        builder.useSecureConnections = NO;
        builder.spotID = spotId;
        builder.timeout = 10;
        builder.keywords = [[self.connector.userKeywords valueForKey:@"description"] componentsJoinedByString:@""];
        
        if ([self.connector userHasLocation]) {
            builder.location = [[CLLocation alloc] initWithLatitude:self.connector.userLatitude longitude:weakSelf.connector.userLongitude];
        }
    }];
    
    if (adType == FYBAdTypeBanner) {
        _MRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder>  _Nonnull builder) {}];
        
        _viewUnitController = [IAViewUnitController build:^(id<IAViewUnitControllerBuilder>  _Nonnull builder) {
            builder.unitDelegate = self;
            [builder addSupportedContentController:self.MRAIDContentController];
        }];
        
        _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
            builder.adRequest = request;
            [builder addSupportedUnitController:self.viewUnitController];
        }];
        
    } else if (adType == FYBAdTypeInterstitial) {
        _MRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder>  _Nonnull builder) {}];
        _videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {}];
        
        _viewUnitController = [IAViewUnitController build:^(id<IAViewUnitControllerBuilder>  _Nonnull builder) {
            builder.unitDelegate = self;
            [builder addSupportedContentController:self.videoContentController];
            [builder addSupportedContentController:self.MRAIDContentController];
        }];
        
        _fullscreenUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder>  _Nonnull builder) {
            builder.unitDelegate = self;
            [builder addSupportedContentController:self.videoContentController];
            [builder addSupportedContentController:self.MRAIDContentController];
        }];
        
        _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
            builder.adRequest = request;
            [builder addSupportedUnitController:self.viewUnitController];
            [builder addSupportedUnitController:self.fullscreenUnitController];
        }];
        
    } else if (adType == FYBAdTypeRewarded) {
        _videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {}];
        
        _fullscreenUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder>  _Nonnull builder) {
            builder.unitDelegate = self;
            [builder addSupportedContentController:self.videoContentController];
        }];
        
        _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
            builder.adRequest = request;
            [builder addSupportedUnitController:self.fullscreenUnitController];
        }];
    } else {
        NSLog(@"<fyber> error");
    }
}

#pragma mark - IAUnitDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
    return [self.connector viewControllerForPresentingModalView];
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    [self.connector adapterDidGetAdClick:self];
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
    if (unitController == self.viewUnitController) {
        [self.connector adapterWillPresentFullScreenModal:self];
    } else if (unitController == self.fullscreenUnitController) {
        [self.connector adapterWillPresentInterstitial:self];
    }
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
    if (unitController == self.viewUnitController) {
        [self.connector adapterWillDismissFullScreenModal:self];
    } else if (unitController == self.fullscreenUnitController) {
        [self.connector adapterWillDismissInterstitial:self];
    }
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    if (unitController == self.viewUnitController) {
        [self.connector adapterDidDismissFullScreenModal:self];
    } else if (unitController == self.fullscreenUnitController) {
        [self.connector adapterDidDismissInterstitial:self];
    }
}

- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController * _Nullable)unitController {
    [self.connector adapterWillLeaveApplication:self];
}

@end
