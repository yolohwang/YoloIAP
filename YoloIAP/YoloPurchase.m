//
//  YoloPurchase.m
//  YoloIAP
//
//  Created by YoloHwang on 17/4/12.
//  Copyright © 2017年 Yolo. All rights reserved.
//

#import "YoloPurchase.h"
#import <CommonCrypto/CommonCrypto.h>
@interface YoloPurchase ()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
@property(nonatomic, copy) YoloPurchaseValidateProductsInfo validateProductsBlock;
@property(nonatomic, copy) YoloPurchaseInvalidateProductsInfo invalidateProductsBlock;
@property(nonatomic, copy) YoloPurchaseRequestProductsErrorMsg requestErrorMsgBlock;

@property(nonatomic, copy) NSArray<SKProduct *> *products;
@property(nonatomic, copy) NSString *productIdentifier;
@end

static NSString *const sandboxURL = @"https://sandbox.itunes.apple.com/verifyReceipt";
static NSString *const buyURL = @"https://buy.itunes.apple.com/verifyReceipt";

@implementation YoloPurchase

+ (instancetype)shareManager
{
    static YoloPurchase *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)requestAllProductIdentifiers:(NSArray *)productIdentifiers
                    validateProducts:(YoloPurchaseValidateProductsInfo)validateProductsCompletonHandler
                  invalidateProducts:(YoloPurchaseInvalidateProductsInfo)invalidateProductsCompletonHandler
                        requestError:(YoloPurchaseRequestProductsErrorMsg)messageCompletonHandler
{
    if (productIdentifiers.count == 0) {
        if (validateProductsCompletonHandler) {
            validateProductsCompletonHandler(nil);
        }
        if (validateProductsCompletonHandler) {
            invalidateProductsCompletonHandler(nil);
        }
        if (validateProductsCompletonHandler) {
            messageCompletonHandler(@"productIdentifiers is nil");
        }
        
    } else if (![SKPaymentQueue canMakePayments]) {
        if (validateProductsCompletonHandler) {
            validateProductsCompletonHandler(nil);
        }
        if (validateProductsCompletonHandler) {
            invalidateProductsCompletonHandler(nil);
        }
        if (validateProductsCompletonHandler) {
            messageCompletonHandler(@"IAP disabled");
        }
        
    } else{
        self.validateProductsBlock = validateProductsCompletonHandler;
        self.invalidateProductsBlock = invalidateProductsCompletonHandler;
        self.requestErrorMsgBlock = messageCompletonHandler;
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
        productsRequest.delegate = self;
        [productsRequest start];
    }
    
}

/***********************************retrieving product*************************************/
//- (void)validateProductIdentifiers:(NSArray *)productIdentifiers
//{
//    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
//    productsRequest.delegate = self;
//    [productsRequest start];
//}

//  Formatting a product’s price
- (NSString *)getProductLocalPrice:(SKProduct *)product
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    return [numberFormatter stringFromNumber:product.price];
}

#pragma mark - SKRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    if (response.products) {
        self.products = response.products;
        if (self.validateProductsBlock) {
            self.validateProductsBlock(response.products);
            self.validateProductsBlock = nil;
        }
    }
    if (response.invalidProductIdentifiers) {
        if (self.invalidateProductsBlock) {
            self.invalidateProductsBlock(response.invalidProductIdentifiers);
            self.invalidateProductsBlock = nil;
        }
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    if (self.requestErrorMsgBlock) {
        self.requestErrorMsgBlock(error.description);
    }
}

/***********************************requesting payment*************************************/
- (void)purchaseWithProductIdentifier:(NSString *)productIdentifier
{
    if (self.products.count != 0) {
        self.productIdentifier = productIdentifier;
        [self.products enumerateObjectsUsingBlock:^(SKProduct * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.productIdentifier isEqualToString:productIdentifier]) {
                *stop = YES;
                SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:obj];
                payment.quantity = 1;
                [[SKPaymentQueue defaultQueue] addPayment:payment];
            }
        }];
    } else {
        if ([self.delegate respondsToSelector:@selector(failPurchaseWithMessage:transaction:)]) {
            [self.delegate failPurchaseWithMessage:@"productIdentifier not found" transaction:nil];
        }
    }
}


#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"purchasing");
                
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"purchased");
                if (self.productIdentifier != nil) {
                    [self showTransactionAsInProgress:transaction deferred:NO];
                } else {
                    [self unfinishedTransaction:transaction];
                }
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"failed");
                if ([self.delegate respondsToSelector:@selector(failPurchaseWithMessage:transaction:)]) {
                    [self.delegate failPurchaseWithMessage:transaction.error.localizedDescription transaction:transaction];
                }
                [self finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                
                break;
            case SKPaymentTransactionStateDeferred:
                [self showTransactionAsInProgress:transaction deferred:YES];
                break;
            default:
                NSLog(@"Unexpected transaction state %@",@(transaction.transactionState));
                break;
        }
    }
}


- (void)showTransactionAsInProgress:(SKPaymentTransaction *)transaction deferred:(BOOL)isDefer
{
    NSLog(@"transaction_id : = %@",transaction.transactionIdentifier);
    if ([self.delegate respondsToSelector:@selector(successPurchaseWithTransaction:)] && !isDefer) {
        [self.delegate successPurchaseWithTransaction:transaction];
    } else
    {
        NSLog(@"transaction defer");
    }
}

- (void)unfinishedTransaction:(SKPaymentTransaction *)transaction
{
    if ([self.delegate respondsToSelector:@selector(unfinishTransaction:)]) {
        [self.delegate unfinishTransaction:transaction];
    }
}


- (void)finishTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark - others

- (NSData *)getReceiptWithTransaction:(SKPaymentTransaction *)transaction
{
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        return [NSData dataWithContentsOfURL:receiptURL];
    } else {
        return transaction.transactionReceipt;
    }
}

- (void)verifyReceipt:(NSData *)receiptdata completion:(void (^)(BOOL, NSDictionary *))completionHandler
{
    NSError *error;
    NSDictionary *requestContents = @{@"receipt-data":[receiptdata base64EncodedStringWithOptions:0]};
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents options:0 error:&error];
    if (requestData) {
        NSURL *storeURL = [NSURL URLWithString:sandboxURL];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:storeURL];
        [request setHTTPBody:requestData];
        [request setHTTPMethod:@"post"];
        
        NSURLSession *session = [NSURLSession  sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"session = %@",dict);
            if ([dict[@"status"] integerValue] == 0) {
                if (completionHandler) {
                    completionHandler(YES, dict[@"receipt"]);
                } else {
                    completionHandler(NO, nil);
                }
            }
        }];
        [task resume];
    }
}

@end
