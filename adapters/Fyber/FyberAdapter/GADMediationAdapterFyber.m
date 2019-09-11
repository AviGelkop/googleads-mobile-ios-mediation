//
//  GADMediationAdapterFyber.m
//  Adapter
//
//  Created by Avi Gelkop on 8/8/19.
//  Copyright © 2019 Google. All rights reserved.
//


#import "GADMediationAdapterFyber.h"
#import "GADFYBMediationRewardedAd.h"

@import IASDKCore;
@import IASDKVideo;
@import IASDKMRAID;
@import CoreLocation;

typedef NS_ENUM(NSInteger, FYBAdType) {
  FYBAdTypeBanner = 0,
  FYBAdTypeInterstitial = 1,
};

@interface GADMediationAdapterFyber () <GADMediationAdapter, GADMAdNetworkAdapter, IAUnitDelegate>

@property (nonatomic, nonnull) id<GADMAdNetworkConnector> connector;

@property (nonatomic, strong, nonnull) IAViewUnitController *viewUnitController;
@property (nonatomic, strong, nonnull) IAFullscreenUnitController *fullscreenUnitController;

@property (nonatomic, strong, nonnull) IAMRAIDContentController *MRAIDContentController;
@property (nonatomic, strong, nonnull) IAVideoContentController *videoContentController;

@property (nonatomic, strong) IAAdSpot *adSpot;

@property (nonatomic, strong, nullable) GADFYBMediationRewardedAd *rewardedAd;

@end

@implementation GADMediationAdapterFyber

#pragma mark - GADMediationAdapter

+ (GADVersionNumber)adSDKVersion {
    NSString *VAMPVersion = [[IASDKCore sharedInstance] version];
    NSArray <NSString *> *versionAsArray = [VAMPVersion componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    
    if (versionAsArray.count == 3) {
        version.majorVersion = versionAsArray[0].integerValue;
        version.minorVersion = versionAsArray[1].integerValue;
        version.patchVersion = versionAsArray[2].integerValue;
    }
    return version;
}


+ (GADVersionNumber)version {
    GADVersionNumber version = {0};
    
    version.majorVersion = 1;
    version.minorVersion = 0;
    version.patchVersion = 0;
    
    return version;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {

    if (configuration.credentials.count > 0) {
        GADMediationCredentials *credentials = configuration.credentials[0];
        NSString *applicationId = credentials.settings[@"applicationId"];
        
        if (applicationId) {
            NSLog(@"Fyber marketplace SDK version: %@", IASDKCore.sharedInstance.version);
            [IALogger setLogLevel:IALogLevelVerbose];
            dispatch_async(dispatch_get_main_queue(), ^{
                [IASDKCore.sharedInstance initWithAppID:applicationId];
                completionHandler(nil);
            });
        } else {
            completionHandler([NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:@{NSLocalizedDescriptionKey:@"Fyber marketplace could not initialized, app ID is unknown"}]);
        }
    }
}

#pragma mark - GADMAdNetworkAdapter

+ (NSString *)adapterVersion {
    return @"1.0.0";
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return nil;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
    self = [super init];
    
    if (self) {
        _connector = connector;
    }
    
    return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
    NSString *spotId = [self.connector credentials][kFYBSpotID];
    
    [self initSpot:spotId adType:FYBAdTypeBanner];
    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        if (error) {
            [self.connector adapter:self didFailAd:error];
        } else {
            [self.connector adapter:self didReceiveAdView:self.viewUnitController.adView];
        }
    }];
}

- (void)getInterstitial {
    NSString *spotId = [self.connector credentials][kFYBSpotID];
    
    [self initSpot:spotId adType:FYBAdTypeInterstitial];
    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        if (error) {
            [self.connector adapter:self didFailAd:error];
        } else {
            [self.connector adapterDidReceiveInterstitial:self];
        }
    }];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    _rewardedAd = [[GADFYBMediationRewardedAd alloc] init];
    [self.rewardedAd loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)stopBeingDelegate {
    if (self.viewUnitController.unitDelegate) {
        self.viewUnitController.unitDelegate = nil;
    }
    
    if (self.fullscreenUnitController.unitDelegate) {
        self.fullscreenUnitController.unitDelegate = nil;
    }
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
        builder.debugger = [IADebugger build:^(id<IADebuggerBuilder>  _Nonnull builder) {
            builder.server = @"ia-cert";
            builder.database = @"5431";
            builder.mockResponsePath = @"7715";
        }];
        
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
