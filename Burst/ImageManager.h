//
//  ImageManager.h
//  Burst
//
//  Created by user on 6/29/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@import Photos;


@interface ImageManager : NSObject


+ (NSData *)webPDataWithImages:(NSArray *)images duration:(CGFloat)duration;
+ (void)imagesFromFetchResult:(PHFetchResult*)fetchResult completion:(void(^)(BOOL success, NSArray *imgs)) completion progress:( void(^ _Nullable)(float progress, int counter))progress;
+(NSArray<UIImage *> *)decodedImageFromData:(NSData *)data;
+ (NSString *)pathForGIFDataWithImages:(NSArray *)images duration:(CGFloat)duration;
@end
