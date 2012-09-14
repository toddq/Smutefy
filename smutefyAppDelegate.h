//
//  smutefyAppDelegate.h
//  smutefy
//
//  Created by Ignacio de Tomás on 16/05/10.
//

#import <Cocoa/Cocoa.h>
#import "Smutefy.h"

@interface smutefyAppDelegate : NSObject
{	
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSPopUpButton *devices;
	IBOutlet NSButton *checkUseCustomDevice;
	IBOutlet NSTextField *labelValid;
	IBOutlet NSTextView *regexTextView;
	IBOutlet NSMenuItem *muteAndAddMenu;
	IBOutlet NSMenuItem *unmuteMenu;
	NSString *defaultRegex;
    NSStatusItem *statusItem;

	IBOutlet NSWindow *preferences;
	
	Smutefy *app;
}

- (IBAction)visitHomepage:(id)sender;
- (IBAction)restoreDefaultsRegex:(id)sender;
- (IBAction)muteAndBlacklist:(id)sender;
- (IBAction)unmute:(id)sender;
- (IBAction)validateRegex:(id)sender;
- (IBAction)makePreferencesFront:(id)sender;
- (IBAction)makeAboutFront:(id)sender;

@end
