//
//  ViewController.m
//  Burst
//
//  Created by Egor on 6/28/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ImageManager.h"


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
        NSLog(@"Selected photo is not a burst.");
        return;
    }
    PHFetchResult *burstPhotos = [PHAsset fetchAssetsWithBurstIdentifier:asset.burstIdentifier options:options];
    NSLog(@"Burst has %d photos in it.", (int)burstPhotos.count);
    
    [picker dismissViewControllerAnimated:true completion:nil];
    [ImageManager imagesFromFetchResult:burstPhotos completion:^(BOOL success, NSArray *imgs) {
        if (success) {
            self.images = imgs;
            NSLog(@"Fetched photos array has %d photos in it.",(int)imgs.count);
            
            [self updateImageView];
        }
    }];
}

-(void) updateImageView{
    
    UIImage *image = self.images.firstObject;
    CGSize size = image.size;
    
    float ratio = size.width > size.height ? (size.height / size.width) : (size.width / size.height);
    float heigth = floorf(self.view.frame.size.height);
    float width = floorf(heigth * ratio);
    
    CGRect frame = {{(int)(self.view.center.x - width/2), 20},{heigth,width}};
    self.imageView.frame = frame;
    
    self.imageView.image = image;
    
}



@end
