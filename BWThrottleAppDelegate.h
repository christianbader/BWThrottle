//
//  BWThrottleAppDelegate.h
//  BWThrottle
//
//  Created by Christian Bader on 11/27/09.
//  Copyright 2009 Christian Bader. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BWThrottleAppDelegate : NSObject {
    IBOutlet NSWindow *window;
	
	IBOutlet NSButton *button;

    IBOutlet NSTextField *inputText;
    IBOutlet NSTextField *delayText;
    IBOutlet NSTextField *portText;
	
	NSString *helperToolPath;
	
	int bwidth;
	int port;
	int delay;
	
	AuthorizationRef authorizationRef;
	
	NSString *activeRule;
	
	BOOL limiterActive;
	
	BOOL authorized;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain)IBOutlet NSTextField *inputText;
@property (nonatomic, retain) IBOutlet NSTextField *delayText;
@property (nonatomic, retain) IBOutlet NSTextField *portText;
@property (nonatomic, copy) NSString *helperToolPath;
@property (nonatomic) int bwidth;
@property (nonatomic) int port;
@property (nonatomic) int delay;
@property (nonatomic, copy) NSString *activeRule;

- (IBAction)limitBandwidth:(id)sender;
- (NSString *)execute:(NSString *)command withArguments:(NSArray *)arguments;
- (void)updateUI;

@end
