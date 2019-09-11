//
//  GADMediationAdapterFyber.h
//  Adapter
//
//  Created by Avi Gelkop on 8/8/19.
//  Copyright © 2019 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;

static NSString * const _Nonnull kFYBApplicationID = @"applicationId";
static NSString * const _Nonnull kFYBSpotID = @"spotId";

NS_ASSUME_NONNULL_BEGIN

@interface GADMediationAdapterFyber : NSObject

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfig
completionHandler:(GADMediationRewardedLoadCompletionHandler)handler;
@end

NS_ASSUME_NONNULL_END
