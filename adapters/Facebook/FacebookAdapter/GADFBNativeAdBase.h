//
//  GADFBNativeAdBase.h
//  Adapter
//
//  Created by Manikanta Nomula on 7/2/19.
//  Copyright © 2019 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GADMAdNetworkAdapter;
@protocol GADMAdNetworkConnector;

@interface GADFBNativeAdBase : NSObject

/// Initializes a new instance with |connector| and |adapter|.
- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
                                       adapter:(id<GADMAdNetworkAdapter>)adapter
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (instancetype)init NS_UNAVAILABLE;

/// Starts fetching a native banner ad for the provided ad types and options.
- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options;

/// Stops the receiver from delegating any notifications from Facebook's Audience Network.
- (void)stopBeingDelegate;

@end
