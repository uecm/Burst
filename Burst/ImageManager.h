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

@class PHFetchResult;


@interface ImageManager : NSObject


+ (NSData *)webPDataWithImages:(NSArray *)images duration:(CGFloat)duration fileName:(NSString *)fileName;
+ (void)imagesFromFetchResult:(PHFetchResult*)fetchResult completion:(void(^)(BOOL success, NSArray *imgs)) completion;

@end
