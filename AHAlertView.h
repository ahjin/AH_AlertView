//
//  CustomAlertView.h
//  CustomAlertView
//
//  Created by Richard on 29/12/2013.
//
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    AlertViewMode_Normal = 0,
    AlertViewMode_CheckBox,
    AlertViewMode_RadioBox
} AlertViewMode;


@protocol AHAlertViewDelegate
@optional
- (void)customdialogButtonTouchUpInside:(id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface AHAlertView : UIView<AHAlertViewDelegate>

@property (nonatomic, assign) id<AHAlertViewDelegate> delegate;

/**
 ** Setting Button color
 */
@property (nonatomic, strong) UIColor *buttonColor;

/**
 ** Setting Cancel Button color
 */
@property (nonatomic, strong) UIColor *cancelButtonColor;


#pragma mark -- init
- (id)initWithTitle:(NSString*)title andMessage:(NSString*)message andCancelButtonTitle:(NSString*)cancelTitle;

#pragma mark -- delegate
- (void)addButtonTitle:(NSArray*)titles;

#pragma mark -- alertView event
- (void)show;
- (void)close;

- (IBAction)customdialogButtonTouchUpInside:(id)sender;
- (void)setOnButtonTouchUpInside:(void (^)(AHAlertView *alertView, int buttonIndex))onButtonTouchUpInside;

- (void)deviceOrientationDidChange: (NSNotification *)notification;

@end
