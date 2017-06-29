//
//  ImageManager.m
//  Burst
//
//  Created by user on 6/29/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "ImageManager.h"
#import <YYImage.h>
#import <MobileCoreServices/MobileCoreServices.h>

@import PhotosUI;
@import AssetsLibrary;

@implementation ImageManager


+ (NSData *)webPDataWithImages:(NSArray *)images duration:(CGFloat)duration {
    YYImageEncoder *webpEncoder = [[YYImageEncoder alloc] initWithType:YYImageTypeWebP];
    webpEncoder.loopCount = 1;
    
    float frameDuration = duration / images.count;
    for (UIImage *image in images) {
        [webpEncoder addImage:image duration:frameDuration];
    }
    
    NSData *webpData = [webpEncoder encode];
    return webpData;
}


+ (void)imagesFromFetchResult:(PHFetchResult*)fetchResult completion:(void(^)(BOOL success, NSArray *imgs)) completion{
    
    
    NSMutableArray *fetchResultArray = [[NSMutableArray alloc] init];
    [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [fetchResultArray addObject:obj];
    }];
    
    NSArray *sortedFetchResult = [[fetchResultArray copy] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [((PHAsset*)obj1).creationDate compare:((PHAsset*)obj2).creationDate];
    }];
    
    NSMutableArray *imagesMutableArray = [NSMutableArray arrayWithCapacity:fetchResult.count];
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.synchronous = true;
    
    __block int counter = 0;
    for (PHAsset *asset in sortedFetchResult) {
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:size
                                                  contentMode:PHImageContentModeDefault
                                                      options:options
                                                resultHandler:^(UIImage * _Nullable result,
                                                                NSDictionary * _Nullable info) {
                                                    if (result) {
                                                        [imagesMutableArray addObject:result];
                                                        counter++;
                                    
                                                        if (counter == fetchResult.count) {
                                                            NSArray *images = [imagesMutableArray copy];
                                                            completion(true, images);
                                                        }
                                                    }
                                                }];
    }
}

+(NSArray<UIImage *> *)decodedImageFromData:(NSData *)data{

    YYImageDecoder *imageDecoder = [YYImageDecoder decoderWithData:data scale:1.f];
    
    NSUInteger frameCount = imageDecoder.frameCount;
    NSMutableArray *frames = [[NSMutableArray alloc] initWithCapacity:frameCount];
    
    for (int i = 0; i < frameCount; i++) {
        YYImageFrame *imageFrame = [imageDecoder frameAtIndex:i decodeForDisplay:true];
        [frames addObject:imageFrame];
    }
    return [frames copy];
}

+(NSString *)pathForGIFDataWithImages:(NSArray *)images duration:(CGFloat)duration{
    
    CGFloat frameDuration = duration / images.count;
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"animation.gif"];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path],
                                                                        kUTTypeGIF,
                                                                        images.count - 1,
                                                                        NULL);
    
    NSDictionary *frameProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:@(frameDuration) forKey:(NSString *)kCGImagePropertyGIFDelayTime]
                                                                forKey:(NSString *)kCGImagePropertyGIFDictionary];
    NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount]
                                                              forKey:(NSString *)kCGImagePropertyGIFDictionary];
    
    for (UIImage *image in images) {
        CGImageDestinationAddImage(destination, image.CGImage, (CFDictionaryRef)frameProperties);
    }
    CGImageDestinationSetProperties(destination, (CFDictionaryRef)gifProperties);
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    NSLog(@"animated GIF file created at %@", path);
    
    return path;
}

@end
