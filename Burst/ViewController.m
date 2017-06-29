//
//  ViewController.m
//  Burst
//
//  Created by Egor on 6/28/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "ViewController.h"
@import Photos;
@import PhotosUI;
@import AssetsLibrary;

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) NSArray<UIImage *> *images;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
        }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)openGalleryPressed:(id)sender {
    
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {}];
        return;
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    //imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    
    [self presentViewController:imagePickerController animated:true completion:nil];
}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:true completion:nil];
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSURL *imageURL = info[UIImagePickerControllerReferenceURL];
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.includeHiddenAssets = true;
    options.includeAllBurstAssets = true;
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[imageURL] options:options];
    PHAsset *asset = [fetchResult firstObject];
    
    if (!asset.representsBurst) {
        NSLog(@"What a shame! Selected photo is not a burst.");
        return;
    }
    PHFetchResult *burstPhotos = [PHAsset fetchAssetsWithBurstIdentifier:asset.burstIdentifier options:options];
    NSLog(@"Burst has %d photos in it!", (int)burstPhotos.count);
    
    [picker dismissViewControllerAnimated:true completion:nil];
    self.images = [self imagesFromFetchResult:burstPhotos];
    [self updateImageView];
}

-(NSArray *) imagesFromFetchResult:(PHFetchResult*)fetchResult{
    
    NSMutableArray *imagesMutableArray = [NSMutableArray arrayWithCapacity:fetchResult.count];
    
    PHAsset *asset = fetchResult.firstObject;
    CGSize imageSize = {asset.pixelWidth/2, asset.pixelHeight/2};
    
    for (PHAsset *asset in fetchResult) {
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:imageSize
                                                  contentMode:PHImageContentModeDefault
                                                      options:NULL
                                                resultHandler:^(UIImage * _Nullable result,
                                                                NSDictionary * _Nullable info) {
            if (result) {
                [imagesMutableArray addObject:result];
            }
        }];
    }
    NSLog(@"Finally, we got %d images in our array.", (int)imagesMutableArray.count);
    return [imagesMutableArray copy];
}

-(void) updateImageView{
    
    UIImage *image = self.images[arc4random_uniform((int)self.images.count)];
    CGSize size = image.size;
    
    float ratio = size.width > size.height ? (size.height / size.width) : (size.width / size.height);
    float heigth = floorf(self.view.frame.size.height);
    float width = floorf(heigth * ratio);
    
    CGRect frame = {{(int)(self.view.center.x - width/2), 20},{heigth,width}};
    self.imageView.frame = frame;
    
    self.imageView.image = image;
    
}



@end
