//
//  GADMediationAdapterFyber.m
//  Adapter
//
//  Created by Avi Gelkop on 8/8/19.
//  Copyright © 2019 Google. All rights reserved.
//


#import "GADMediationAdapterFyber.h"

@import IASDKCore;

@implementation GADMediationAdapterFyber

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

+ (GADVersionNumber)version {
    GADVersionNumber version = {0};
    version.majorVersion = 1;
    version.minorVersion = 0;
    version.patchVersion = 0;
    return version;
}

+ (GADVersionNumber)adSDKVersion {
    GADVersionNumber version = {0};
    NSArray<NSString*> *components = [[IASDKCore sharedInstance].version componentsSeparatedByString:@"."];
    if (components.count == 3) {
        version.majorVersion = components[0].integerValue;
        version.minorVersion = components[1].integerValue;
        version.patchVersion = components[2].integerValue;
    } else {
        NSLog(@"Unexpected version string: %@. Returning 0 for adSDKVersion.", [IASDKCore sharedInstance].version);
    }
    return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
    return nil;
}

- (void)loadBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
    NSLog(@"");

}

- (void)loadInterstitialForAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
    NSLog(@"");
}

- (void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
    NSLog(@"");

}



+ (void)setUp {
    
}

@end
