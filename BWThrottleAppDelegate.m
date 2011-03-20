//
//  BWThrottleAppDelegate.m
//  BWThrottle
//
//  Created by Christian Bader on 11/27/09.
//  Copyright 2009 Christian Bader. All rights reserved.
//

#import "BWThrottleAppDelegate.h"

@interface BWThrottleAppDelegate (PrivateMethods)

- (void)authorize;

@end

@implementation BWThrottleAppDelegate

@synthesize window;
@synthesize inputText;
@synthesize delayText;
@synthesize portText;
@synthesize helperToolPath;
@synthesize bwidth;
@synthesize port;
@synthesize delay;
@synthesize activeRule;

- (void)awakeFromNib
{
	//Path to the limiter script
	NSString *rootPath = [[NSBundle mainBundle] resourcePath];
	self.helperToolPath = [rootPath stringByAppendingString:@"/limiter"];

	//User Preferences
	NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
	
	[inputText becomeFirstResponder];
	
	self.bwidth = [[prefs objectForKey:@"bandwidth"] intValue];
	self.delay = [[prefs objectForKey:@"delay"] intValue];
	self.port = [[prefs objectForKey:@"port"] intValue];
	self.activeRule = [prefs objectForKey:@"activeRule"];
	
	// Check for active rules
	if (activeRule == nil || [activeRule intValue] == 0) {
		limiterActive = NO;
	} else {
		limiterActive = YES;
	}
	
	[self updateUI];
}

- (void)saveSettings {
	
	// Save the user settings to the preferences
	NSMutableDictionary *preferences = [NSMutableDictionary dictionary];
	
	[preferences setObject:[NSNumber numberWithInt:bwidth] forKey:@"bandwidth"];
	[preferences setObject:[NSNumber numberWithInt:port] forKey:@"port"];
	[preferences setObject:[NSNumber numberWithInt:delay] forKey:@"delay"];
	[preferences setObject:activeRule forKey:@"activeRule"];
		
	[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:preferences forName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];	
}

- (void)updateUI
{
	//Update the user interface
	inputText.stringValue = [NSString stringWithFormat:@"%i", self.bwidth];
	portText.stringValue = [NSString stringWithFormat:@"%i", self.port];
	delayText.stringValue = [NSString stringWithFormat:@"%i", self.delay];
	
	//Enable or disable the UI elements
	if (limiterActive) {
		[inputText setEnabled:NO];
		[portText setEnabled:NO];
		[delayText setEnabled:NO];
	} else {
		[inputText setEnabled:YES];
		[portText setEnabled:YES];
		[delayText setEnabled:YES];
	}
}

- (NSString *)execute:(NSString *)command withArguments:(NSArray *)arguments {
	
	char *args[[arguments count] + 3];
	
	args[0] = (char *)[command cStringUsingEncoding:NSUTF8StringEncoding];
	
	int i = 1;
	for (NSString *argument in arguments) {
		args[i ++] = (char *)[argument cStringUsingEncoding:NSUTF8StringEncoding];
	}
	args[i] = NULL;
	
	FILE *pipe;
	OSStatus status;
	NSString *string;
	
	status = AuthorizationExecuteWithPrivileges(authorizationRef, [helperToolPath fileSystemRepresentation], kAuthorizationFlagDefaults, args, &pipe);
	
	if (status != errAuthorizationSuccess) {
		NSLog(@"Error: %d", status);
        return nil;
	} else {
		NSFileHandle *handle = [[NSFileHandle alloc] initWithFileDescriptor:fileno(pipe)];
		string = [[[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
		[handle release];
	}
		
	return [NSString stringWithFormat:@"%d", [string intValue]];
}

- (void)releaseAuthorization {
	if (authorizationRef != NULL) {
		AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);	
		authorizationRef = NULL;
	}
}

#pragma mark -
#pragma mark action handling

- (IBAction)limitBandwidth:(id)sender
{
	if (!authorized) {
		[self authorize];
	}
	
	if (authorized) {
		
		if (limiterActive) {
			//Delete the actual rules
			self.activeRule = [self execute:@"stop" withArguments:[NSArray arrayWithObject:self.activeRule]];
			limiterActive = NO;
			
		} else {
			
			//Bandwidth
			if ([inputText intValue] < 0) {
				bwidth = 0;
			} else {
				bwidth = [inputText intValue];
			}
			
			//Port
			if ([portText intValue] > 65536) {
				port = 65536;
			} else if ([portText intValue] < 1) {
				port = 1;
			} else {
				port = [portText intValue];
			}
			
			//Delay
			if ([delayText intValue] >= 10000) {
				delay = 9999;
			} else if ([delayText intValue] < 0) {
				delay = 0;
			} else {
				delay = [delayText intValue];
			}		
			
			NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%i", bwidth], [NSString stringWithFormat:@"%i", delay], [NSString stringWithFormat:@"%i", port], nil];
            
			self.activeRule = [self execute:@"start" withArguments:arguments];
            if (activeRule) {
                limiterActive = YES; 
            }
		}
		[self updateUI];
	}
}

#pragma mark -
#pragma mark termination handling

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSNotification *)aNotification
{	
	if (limiterActive) {
        [self limitBandwidth:nil];
        
        [self releaseAuthorization];
        
        //Save the current user settings
        [self saveSettings];
	}
    
    return NSTerminateNow;
}

#pragma mark -
#pragma mark Authorization handling

- (void)authorize {
	
	//Authorization
	
	OSStatus status;
	
	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
	
	if (status != errAuthorizationSuccess) {
		NSLog(@"Error %d", status);
		authorized = NO;
	} else {
		authorized = YES;
	}
	
	AuthorizationItem right = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &right};
	AuthorizationFlags flags = kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
	
	AuthorizationCopyRights(authorizationRef, &rights, NULL, flags, NULL);
}

@end

