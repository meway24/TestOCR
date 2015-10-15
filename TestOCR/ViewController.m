//
//  ViewController.m
//  TestOCR
//
//  Created by memebox on 15/10/14.
//  Copyright © 2015年 yeapoo. All rights reserved.
//

#import "ViewController.h"
#import <TesseractOCR/TesseractOCR.h>
#import <TesseractOCR/UIImage+G8FixOrientation.h>

@interface ViewController ()
<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIActionSheetDelegate,G8TesseractDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *mImageView;

@property (weak, nonatomic) IBOutlet UITextView *mTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Event
- (IBAction)selectImageButtonClicked:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"取消"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"拍照",@"从相册选取", nil];
    [actionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self shootPicture];
    } else {
        [self selectExistingPicture];
    }
}

//拍照
-(void)shootPicture {
    [self getPictureFromSource:UIImagePickerControllerSourceTypeCamera];
}

//从相册选择照片
- (void)selectExistingPicture {
    [self getPictureFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
}

//创建和配置图像选取器，使用传入的sourceType确定调出照相机还是媒体库
- (void)getPictureFromSource:(UIImagePickerControllerSourceType)sourceType {
    NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    
    if ([UIImagePickerController isSourceTypeAvailable:sourceType] && [mediaTypes count] > 0) {
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
        UIImagePickerController *picker = [[UIImagePickerController alloc]init];
        picker.mediaTypes = mediaTypes;
        picker.delegate = self;
        picker.allowsEditing = NO;
        picker.sourceType = sourceType;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"设备不支持!" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.mImageView.image = image;
    [self recognition:image];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)recognition:(UIImage *)image {
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void) {
        // Languages are used for recognition (e.g. eng, ita, etc.). Tesseract engine
        // will search for the .traineddata language file in the tessdata directory.
        // For example, specifying "eng+ita" will search for "eng.traineddata" and
        // "ita.traineddata". Cube engine will search for "eng.cube.*" files.
        // See https://code.google.com/p/tesseract-ocr/downloads/list.
        
        // Create your G8Tesseract object using the initWithLanguage method:
        G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
        
        // Optionaly: You could specify engine to recognize with.
        // G8OCREngineModeTesseractOnly by default. It provides more features and faster
        // than Cube engine. See G8Constants.h for more information.
        tesseract.engineMode = G8OCREngineModeTesseractOnly;
        
        // Set up the delegate to receive Tesseract's callbacks.
        // self should respond to TesseractDelegate and implement a
        // "- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract"
        // method to receive a callback to decide whether or not to interrupt
        // Tesseract before it finishes a recognition.
        tesseract.delegate = self;
        
        // Optional: Limit the character set Tesseract should try to recognize from
        //    tesseract.charWhitelist = @"0123456789";
        tesseract.charWhitelist = @"@.(){}/\\!*&#0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        
        // This is wrapper for common Tesseract variable kG8ParamTesseditCharWhitelist:
        // [tesseract setVariableValue:@"0123456789" forKey:kG8ParamTesseditCharBlacklist];
        // See G8TesseractParameters.h for a complete list of Tesseract variables
        
        // Optional: Limit the character set Tesseract should not try to recognize from
        //tesseract.charBlacklist = @"OoZzBbSs";
        
        // Specify the image Tesseract should recognize on
        tesseract.image = [[image fixOrientation] g8_blackAndWhite];
        
        // Optional: Limit the area of the image Tesseract should recognize on to a rectangle
        //    tesseract.rect = CGRectMake(20, 20, 100, 100);
        
        // Optional: Limit recognition time with a few seconds
        tesseract.maximumRecognitionTime = 2.0;
        
        // Start the recognition
        [tesseract recognize];
        
        // Retrieve the recognized text
        NSLog(@"%@", [tesseract recognizedText]);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.mTextView.text = [tesseract recognizedText];
        });

        // You could retrieve more information about recognized text with that methods:
        NSArray *characterBoxes = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelSymbol];
        NSArray *paragraphs = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelParagraph];
        
        NSLog(@"characterBoxes = %@ \n paragraphs = %@ \n", characterBoxes,paragraphs);
    });
}

@end
