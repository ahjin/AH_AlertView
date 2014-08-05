AH_AlertView
============
support iOS6 or newest.

Introduction:

This is customer alertView for iOS

1. can use checkBox item

2. can use redobox item

3. can use multiple item



![my image](https://github.com/ahjin/AH_AlertView/blob/master/screenshot/Screenshot%202014.08.05%2017.13.50.png)
  ![my image](https://github.com/ahjin/AH_AlertView/blob/master/screenshot/Screenshot%202014.08.05%2017.05.16.png)  
![my image](https://github.com/ahjin/AH_AlertView/blob/master/screenshot/Screenshot%202014.08.05%2017.12.31.png)
  ![my image](https://github.com/ahjin/AH_AlertView/blob/master/screenshot/Screenshot%202014.08.05%2017.13.12.png)

Usage:



\#import "AHAlertView.h"

    AHAlertView *alertView = [[AHAlertView alloc] initWithTitle:@"Alert Tip" 
                          andMessage: @"This is Test." 
                          andCancelButtonTitle: @"OK"
                         ];

    [alertView addButtonTitle:@[@"Item1", @"Item2", @"Item3", @"Item4"]];

    [alertView setCancelButtonColor:[UIColor redColor]];

    [alertView setOnButtonTouchUpInside:^(AHAlertView *alertView, int buttonIndex) {  

        NSLog(@"tap = %i", buttonIndex);  
        if (buttonIndex > 0){ 
  
            //insert your code......  
          
            [alertView close];
        }  
    }];

    [alertView show];
    
    
