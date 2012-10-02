//
//  smutefyAppDelegate.m
//  smutefy
//
//  Created by Ignacio de Tomás on 16/05/10.
//

#import "smutefyAppDelegate.h"


@implementation smutefyAppDelegate

- (id)init
{
	self = [super init];

	BOOL iconInDock = [[NSUserDefaults standardUserDefaults] boolForKey:@"showInDock"];
	if (iconInDock)
	{
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		TransformProcessType(&psn, kProcessTransformToForegroundApplication);
	}


	defaultRegex = @".*https?://.*\n.*Spotify:track:.*\n.*Spotify:album:.*\n.*Spotify:user:.*\n.*spotify:track:.*\n.*spotify:album:.*\n.*spotify:album\.*\n.*spotify:user:.*\n.*Spotify:ad:.*\n.*Spotify:app:.*\n.*spotify:ad:.*\n.*spotify:ad\.*\n.*spotify:app:.*\n.*spotify:app\.*\n.*spotify\: spotify\.*\n.*Spotify\: spotify\.*";

	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:defaultRegex, @"customregex", nil]];



	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	app = [Smutefy new];

	[app setStatusItem:statusItem];
	[app setDevicesObject:devices];
	[app setcheckUseCustomDevice:checkUseCustomDevice];
	[app setRegex:regexTextView];
	[app setMuteAndAdd:muteAndAddMenu];
	[app setUnmute:unmuteMenu];
	[app setLabelValid:labelValid];

	[app setupGrowl];
	[app initializeVars];

	[app performSelectorInBackground:@selector(monitorGrowl) withObject:nil];
}


- (void)awakeFromNib
{
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setMenu:statusMenu];

	[statusItem setImage:[NSImage imageNamed:@"status_normal.png"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"status_click.png"]];

	[statusItem setHighlightMode:YES];


	[[regexTextView enclosingScrollView] setHasHorizontalScroller:YES];
	[regexTextView setHorizontallyResizable:YES];
	[regexTextView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[[regexTextView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[regexTextView textContainer] setWidthTracksTextView:NO];
	[regexTextView setFont:[NSFont systemFontOfSize:12]];

}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	// restore audio device
	[app changeAudioDevice:FALSE];

	return NSTerminateNow;
}

- (IBAction)visitHomepage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://smutefy.inacho.es"]];
}

- (IBAction)restoreDefaultsRegex:(id)sender
{
	[regexTextView setString:defaultRegex];
	[app syncRegexPreferences];
}

- (IBAction)muteAndBlacklist:(id)sender
{
	[app muteAndBlacklist];
}
- (IBAction)unmute:(id)sender
{
	[app unmute];
}

- (IBAction)validateRegex:(id)sender
{
	[app validateRegex];
}

- (IBAction)makePreferencesFront:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[preferences makeKeyAndOrderFront:sender];
}

- (IBAction)makeAboutFront:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:sender];
}

@end
