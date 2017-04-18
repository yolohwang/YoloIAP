//
//  ViewController.m
//  YoloIAP
//
//  Created by YoloHwang on 17/4/12.
//  Copyright © 2017年 Yolo. All rights reserved.
//

#import "ViewController.h"
#import "YoloPurchase.h"

#define productidentifiers (@[@"com.gaeamobile.cn.xja2.t1g60",@"com.gaeamobile.cn.xja2.t60g6480"])

@interface ViewController ()<YoloPurchaseDelegate>

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
 
    
    [YoloPurchase shareManager].delegate = self;
}

- (IBAction)requestProductsButton:(id)sender {
    [[YoloPurchase shareManager] requestAllProductIdentifiers:productidentifiers validateProducts:^(NSArray<SKProduct *> *products) {
        [products enumerateObjectsUsingBlock:^(SKProduct * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"valid product identifiers = %@ , localizedDescription = %@",obj.productIdentifier,obj.localizedDescription);
            
        }];
        
    } invalidateProducts:^(NSArray *products) {
        [products enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"invalid product identifiers = %@",obj);
        }];
        
    } requestError:^(NSString *message) {
        NSLog(@"error msg = %@",message);
    }];
}

- (IBAction)purchaseProductButton:(id)sender {
    [[YoloPurchase shareManager] purchaseWithProductIdentifier:@"com.gaeamobile.cn.xja2.t60g6480"];
}

#pragma mark - YoloPurchaseDelegate

- (void)successPurchaseWithTransaction:(SKPaymentTransaction *)transaction
{
    //处理success

    NSData *receiptData = [[YoloPurchase shareManager] getReceiptWithTransaction:transaction];
    [[YoloPurchase shareManager] verifyReceipt:receiptData completion:^(BOOL success, NSDictionary *receiptInfo) {
        if (success) {
            NSLog(@"purchase receipt verify success, finish transaction");
            //最后finish
            [[YoloPurchase shareManager] finishTransaction:transaction];
        }
    }];
}
- (void)unfinishTransaction:(SKPaymentTransaction *)transaction
{
    //处理unfinish
    
    NSData *receiptData = [[YoloPurchase shareManager] getReceiptWithTransaction:transaction];
    [[YoloPurchase shareManager] verifyReceipt:receiptData completion:^(BOOL success, NSDictionary *receiptInfo) {
        if (success) {
            NSLog(@"unfinish receipt verify success, finish transaction");
            //最后finish
            [[YoloPurchase shareManager] finishTransaction:transaction];
        }
    }];
}
- (void)failPurchaseWithMessage:(NSString *)message transaction:(SKPaymentTransaction *)transaction
{
    //处理fail
        
}

@end
