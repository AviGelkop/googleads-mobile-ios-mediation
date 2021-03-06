// Copyright 2018 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GADMediationAdapterAdColony.h"

#import <AdColony/AdColony.h>
#include <stdatomic.h>

#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMAdapterAdColonyInitializer.h"
#import "GADMAdapterAdColonyRTBInterstitialRenderer.h"
#import "GADMAdapterAdColonyRewardedRenderer.h"

static AdColonyAppOptions *GADMAdapterAdColonyAppOptions;

@implementation GADMediationAdapterAdColony {
  /// Completion handler for signal generation. Returns either signals or an error object.
  GADRTBSignalCompletionHandler _signalCompletionHandler;

  /// AdColony interstitial ad renderer.
  GADMAdapterAdColonyRTBInterstitialRenderer *_interstitialRenderer;

  /// AdColony rewarded ad renderer.
  GADMAdapterAdColonyRewardedRenderer *_rewardedRenderer;
}

+ (void)load {
  GADMAdapterAdColonyAppOptions = [[AdColonyAppOptions alloc] init];
}

+ (AdColonyAppOptions *)appOptions {
  return GADMAdapterAdColonyAppOptions;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *zoneIDs = [[NSMutableSet alloc] init];
  NSMutableSet *appIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *zoneID = GADMAdapterAdColonyZoneIDForSettings(cred.settings);
    GADMAdapterAdColonyMutableSetAddObject(zoneIDs, zoneID);

    NSString *appID = cred.settings[kGADMAdapterAdColonyAppIDkey];
    GADMAdapterAdColonyMutableSetAddObject(appIDs, appID);
  }

  if (appIDs.count < 1 || zoneIDs.count < 1) {
    NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(
        GADMAdapterAdColonyErrorMissingServerParameters,
        @"AdColony mediation configurations did not contain a valid app ID or zone ID.");
    completionHandler(error);
    return;
  }

  NSString *appID = [appIDs anyObject];

  if (appIDs.count != 1) {
    GADMAdapterAdColonyLog(@"Found the following app IDs: %@. Please remove any app IDs you are "
                           @"not using from the AdMob/Ad Manager UI.",
                           appIDs);
    GADMAdapterAdColonyLog(@"Configuring AdColony SDK with the app ID %@", appID);
  }

  [[GADMAdapterAdColonyInitializer sharedInstance]
      initializeAdColonyWithAppId:appID
                            zones:[zoneIDs allObjects]
                          options:GADMAdapterAdColonyAppOptions
                         callback:^(NSError *error) {
                           // After configuration completion, register custom message listener
                           // to get bid values
                           [AdColony
                               sendCustomMessageOfType:@"register_handler"
                                           withContent:@"bid"
                                                 reply:^(id _Nullable reply) {
                                                   if (![reply isKindOfClass:[NSString class]]) {
                                                     return;
                                                   }

                                                   NSString *zoneID =
                                                       GADMAdapterAdColonyZoneIDForReply(reply);
                                                   GADMAdapterAdColonyMutableDictionarySetObjectForKey(
                                                       GADMediationAdapterAdColony.bidValues,
                                                       zoneID, reply);
                                                 }];
                           // Tell the Google Mobile Ads SDK that AdColony is initialized and
                           // is ready to service requests.
                           completionHandler(error);
                         }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [AdColony getSDKVersion];
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAdColonyExtras class];
}

+ (GADVersionNumber)version {
  return [GADMediationAdapterAdColony adapterVersion];
}

+ (GADVersionNumber)adapterVersion {
  NSString *versionString = kGADMAdapterAdColonyVersionString;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (NSMutableDictionary *)bidValues {
  static NSMutableDictionary *valuesDict = nil;
  if (valuesDict == nil) {
    valuesDict = [[NSMutableDictionary alloc] init];
  }
  return valuesDict;
}

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
  // Keep handler, in practice this call may be asynchronous.
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADRTBSignalCompletionHandler originalCompletionHandler = [completionHandler copy];
  _signalCompletionHandler = ^void(NSString *_Nullable signals, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return;
    }

    if (originalCompletionHandler) {
      originalCompletionHandler(signals, error);
    }
    originalCompletionHandler = nil;
  };

  NSString *signals = nil;

  // Get Zone Id for which signals are requested
  NSString *zoneId;
  if (params.configuration.credentials.count > 0) {
    zoneId = params.configuration.credentials[0].settings[kGADMAdapterAdColonyZoneIDOpenBiddingKey];
  }
  if (zoneId.length) {
    // Take out saved signals for above zone Id
    signals = [self getSignalsForZone:zoneId];
  }
  _signalCompletionHandler(signals, nil);
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedRenderer = [[GADMAdapterAdColonyRewardedRenderer alloc] init];
  [_rewardedRenderer loadRewardedAdForAdConfiguration:adConfiguration
                                    completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitialRenderer = [[GADMAdapterAdColonyRTBInterstitialRenderer alloc] init];
  [_interstitialRenderer renderInterstitialForAdConfig:adConfiguration
                                     completionHandler:completionHandler];
}

// Build JSON with signals values
- (NSString *)getSignalsForZone:(NSString *)zoneId {
  NSString *signals = nil;
  NSMutableDictionary<NSString *, NSString *> *values = [[NSMutableDictionary alloc] init];

  // Add alternative ad Id if it's there
  NSString *adcID = [self getAlternateAdId];
  if (adcID.length) {
    values[kGADMAdapterAdColonyAltAdIdKey] = adcID;
  }

  // Add bid reply for above zone Id if it's there
  NSString *bidReply = GADMediationAdapterAdColony.bidValues[zoneId];
  if (bidReply.length) {
    values[kGADMAdapterAdColonyBidReplyKey] = bidReply;
  }

  if (values.count) {
    // get JSON string from dictionary
    signals = [GADMAdapterAdColonyHelper getJsonStringFromDictionary:values];
  }

  return signals;
}

// Get Alternative Ad Id if LAT is enabled
- (NSString *)getAlternateAdId {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString *adcID = [userDefaults stringForKey:kGADMAdapterAdColonyAltAdIdKey];
  return adcID;
}

@end
