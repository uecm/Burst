//
//  ViewController.m
//  Burst
//
//  Created by Egor on 6/28/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "ViewController.h"
#import "ImageManager.h"
#import <YYAnimatedImageView.h>
#import <YYImage.h>

#import <HTPressableButton.h>
#import <UIColor+HTColor.h>
#import <MRProgress.h>

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet YYAnimatedImageView *imageView;

@property (weak, nonatomic) IBOutlet HTPressableButton *openGalleryButton;
@property (weak, nonatomic) IBOutlet HTPressableButton *makeGifButton;
@property (weak, nonatomic) IBOutlet HTPressableButton *playGifButton;

@property (weak, nonatomic) IBOutlet UISlider *slider;

@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondsLabel;

@property (strong, nonatomic) NSArray<UIImage *> *images;
@property (strong, nonatomic) YYImage *animationImage;

@property (strong, nonatomic) MRProgressOverlayView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
        }];
    }
    
    self.makeGifButton.alpha = 0;
    self.playGifButton.alpha = 0;
    self.slider.alpha = 0;
    self.fpsLabel.alpha = 0;
    self.secondsLabel.alpha = 0;
    
    self.imageView.autoPlayAnimatedImage = false;
    
    // Setup buttons
    [self setupButton:self.openGalleryButton withColor:[UIColor ht_aquaColor] shadowColor:[UIColor ht_aquaDarkColor]];
    [self setupButton:self.makeGifButton withColor:[UIColor ht_aquaColor] shadowColor:[UIColor ht_aquaDarkColor]];
    [self setupButton:self.playGifButton withColor:[UIColor ht_mintColor] shadowColor:[UIColor ht_mintDarkColor]];
    
    // Setup progress view
}

-(MRProgressOverlayView *)progressView{
    if (_progressView) {
        return _progressView;
    }
    
    MRProgressOverlayView *view = [MRProgressOverlayView showOverlayAddedTo:self.view title:@"" mode:MRProgressOverlayViewModeDeterminateCircular animated:true];
    view.tintColor = [UIColor ht_aquaColor];
    
    return _progressView = view;
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
    
    [picker dismissViewControllerAnimated:true completion:^{
        self.progressView.progress = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self handleImageMediaInfo:info];
        });
    }];
}



-(void) handleImageMediaInfo:(NSDictionary<NSString *,id> *)info {
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [ImageManager imagesFromFetchResult:burstPhotos completion:^(BOOL success, NSArray *imgs) {
            if (success) {
                self.images = imgs;
                NSLog(@"Fetched photos array has %d photos in it.",(int)imgs.count);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateImageView];
                    [self.progressView dismiss:true completion:^{
                        self.progressView = nil;
                    }];
                    [self updateFpsLabel];
                });
            }
        } progress:^(float progress, int counter) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.progressView) {
                    self.progressView.progress = progress;
                }
            });
        }];
    });
}



-(void) updateImageView{
    
    UIImage *image = self.images.firstObject;
    CGSize size = image.size;
    
    float ratio = size.width > size.height ? (size.height / size.width) : (size.width / size.height);
    float heigth = floorf(self.view.frame.size.height);
    float width = floorf(heigth * ratio);
    
    CGRect frame = {{(self.view.center.x - width/2), 20},{heigth,width}};
    self.imageView.frame = frame;
    self.imageView.image = image;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.makeGifButton.alpha = 1;
        self.fpsLabel.alpha = 1;
        self.slider.alpha = 1;
        self.secondsLabel.alpha = 1;
    }];
}



- (IBAction)makeGifPressed:(id)sender {
    if (!self.images) {
        return;
    }
    
    self.progressView.progress = 0;
    self.progressView.mode = MRProgressOverlayViewModeIndeterminate;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *webPData = [ImageManager webPDataWithImages:self.images duration:[self durationForAnimation]];
        self.animationImage = [YYImage imageWithData:webPData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                self.playGifButton.alpha = 1;
            }];
            [self.playGifButton setTitle:@"Play a gif" forState:UIControlStateNormal];
        
            self.imageView.image = self.animationImage;
            
            [self.progressView dismiss:true completion:^{
                self.progressView = nil;
            }];
        });
    });
    
}



- (IBAction)playGifPressed:(id)sender {
    
    BOOL isPlayState = [self.playGifButton.titleLabel.text isEqualToString:@"Play a gif"];
    
    BOOL ended = self.imageView.currentAnimatedImageIndex == self.images.count-1;
    
    if (ended) {
        self.imageView.currentAnimatedImageIndex = 0;
        isPlayState = false;
    }
    
    if (isPlayState) {
        
        if (!self.imageView.currentIsPlayingAnimation) {
            [self.imageView startAnimating];
        }
        
        [self.playGifButton setTitle:@"Stop playing" forState:UIControlStateNormal];
        [self setupButton:self.playGifButton withColor:[UIColor ht_alizarinColor] shadowColor:[UIColor ht_pomegranateColor]];
    }
    else {
        
        if (self.imageView.currentIsPlayingAnimation) {
            [self.imageView stopAnimating];
        }
        [self.playGifButton setTitle:@"Play a gif" forState:UIControlStateNormal];
        [self setupButton:self.playGifButton withColor:[UIColor ht_mintColor] shadowColor:[UIColor ht_mintDarkColor]];
    }
}



- (IBAction)sliderValueChanged:(id)sender {
    
    [self updateFpsLabel];
}



-(float) durationForAnimation {
    
    float value = self.slider.value;
    
    float currentDuration = value * 30;
    if (currentDuration < 1) {
        currentDuration = 1;
    }
    return currentDuration;
}



-(void) updateFpsLabel{
    
    float duration = [self durationForAnimation];
    float fps = self.images.count / duration;
    
    NSString *fpsText = [NSString stringWithFormat:@"%.02f frames per second", fps];
    self.fpsLabel.text = fpsText;
    
    NSString *durationText = [NSString stringWithFormat:@"%02.02f seconds", duration];
    self.secondsLabel.text = durationText;
}



- (IBAction)sharePressed:(id)sender {
    if(!self.animationImage) return;
    
    NSString *gifPath = [ImageManager pathForGIFDataWithImages:self.images duration:[self durationForAnimation]];
    NSData *imgData = [NSData dataWithContentsOfFile:gifPath];
    
    UIActivityViewController *shareVC = [[UIActivityViewController alloc] initWithActivityItems:@[imgData] applicationActivities:nil];
    [self presentViewController:shareVC animated:true completion:nil];
}



-(void) setupButton:(HTPressableButton*)button withColor:(UIColor*)color shadowColor:(UIColor*)shadowColor{
    CGRect frame = {[button convertPoint:button.frame.origin toView:self.view], {130, 40}};
    button.frame = frame;
    button.style = HTPressableButtonStyleRounded;
    button.buttonColor = color;
    button.shadowHeight = (int)(40 * 0.17);
    button.shadowColor = shadowColor;
    //[button createButton];
}


@end
