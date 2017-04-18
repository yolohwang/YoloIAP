//
//  YoloPurchase.h
//  YoloIAP
//
//  Created by YoloHwang on 17/4/12.
//  Copyright © 2017年 Yolo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol YoloPurchaseDelegate <NSObject>
- (void)successPurchaseWithTransaction:(SKPaymentTransaction *)transaction;
- (void)unfinishTransaction:(SKPaymentTransaction *)transaction;
- (void)failPurchaseWithMessage:(NSString *)message transaction:(SKPaymentTransaction *)transaction;
@end

typedef void(^YoloPurchaseValidateProductsInfo)(NSArray<SKProduct *> *products);
typedef void(^YoloPurchaseInvalidateProductsInfo)(NSArray *products);
typedef void(^YoloPurchaseRequestProductsErrorMsg)(NSString *message);

@interface YoloPurchase : NSObject
@property(nonatomic, copy, readonly) NSArray<SKProduct *> *products;
@property(nonatomic, copy, readonly) NSString *productIdentifier;
@property(nonatomic, weak) id<YoloPurchaseDelegate> delegate;

+ (instancetype)shareManager;

- (void)requestAllProductIdentifiers:(NSArray *)productIdentifiers
                    validateProducts:(YoloPurchaseValidateProductsInfo)validateProductsCompletonHandler
                  invalidateProducts:(YoloPurchaseInvalidateProductsInfo)invalidateProductsCompletonHandler
                        requestError:(YoloPurchaseRequestProductsErrorMsg)messageCompletonHandler;
;

//- (void)validateProductIdentifiers:(NSArray *)productIdentifiers;
- (void)purchaseWithProductIdentifier:(NSString *)productIdentifier;
- (void)finishTransaction:(SKPaymentTransaction *)transaction;
- (NSData *)getReceiptWithTransaction:(SKPaymentTransaction *)transaction;

- (void)verifyReceipt:(NSData *)receiptdata completion:(void(^)(BOOL success, NSDictionary *receiptInfo))completionHandler;

@end
