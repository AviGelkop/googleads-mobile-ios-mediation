//
//  GADFBNativeAdBase.m
//  Adapter
//
//  Created by Manikanta Nomula on 7/2/19.
//  Copyright © 2019 Google. All rights reserved.
//

#import "GADFBNativeAdBase.h"
#import "GADFBNativeBannerAd.h"
#import "GADFBNetworkExtras.m"
#import "GADFBUnifiedNativeAd.h"

@interface GADFBNativeAdBase () {
  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  GADFBNativeBannerAd *_nativeBannerAd;

  GADFBUnifiedNativeAd *_nativeAd;

  GADFBNetworkExtras *_extras;
}

@end

@implementation GADFBNativeAdBase

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
                                       adapter:(id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
    _extras = connector.networkExtras;
  }
  return self;
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (_extras.requestNativeBanner) {
    _nativeBannerAd = [[GADFBNativeBannerAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                          adapter:strongAdapter];
    [_nativeBannerAd getNativeAdWithAdTypes:adTypes options:options];
  } else {
    _nativeAd = [[GADFBUnifiedNativeAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                     adapter:strongAdapter];
    [_nativeAd getNativeAdWithAdTypes:adTypes options:options];
  }
}

- (void)stopBeingDelegate {
  if (_extras.requestNativeBanner) {
    [_nativeBannerAd stopBeingDelegate];
  } else {
    [_nativeAd stopBeingDelegate];
  }
}

@end
