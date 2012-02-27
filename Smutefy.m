//
//  Smutefy.m
//  smutefy
//
//  Created by Ignacio de Tomás on 16/05/10.
//

#import "Smutefy.h"


@implementation Smutefy



- (void)refreshSaveddevices
{
	int index = [devices indexOfSelectedItem];
	NSMutableArray *realDevices = [self systemOutputDevices];
	
	[devices removeAllItems];
	[devices addItemsWithTitles:realDevices];
	
	if(index < [realDevices count])
	{
		[devices selectItemAtIndex:index];
	}
	
}

- (NSString *)systemCurrentDevice
{
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: pathToSwitchAudio];
	
	NSArray *arguments;
	arguments = [NSArray arrayWithObjects: @"-c", nil];
	[task setArguments: arguments];
	
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	[task setStandardInput:[NSPipe pipe]];
	
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data;
	data = [file readDataToEndOfFile];
	
	NSString *string;
	string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

	string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];

	return string;
}

- (NSMutableArray *)systemOutputDevices
{
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: pathToSwitchAudio];
	
	NSArray *arguments;
	arguments = [NSArray arrayWithObjects: @"-a", @"-t", @"output", nil];
	[task setArguments: arguments];
	
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	[task setStandardInput:[NSPipe pipe]];
	
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data;
	data = [file readDataToEndOfFile];
	
	NSString *string;
	string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	
	
	string = [string stringByReplacingOccurrencesOfString:@" (output)\n" withString:@"\n"];
	string = [string stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
	
	NSMutableArray *arrayDevices = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
	
	if([arrayDevices count] > 1)
	{
		[arrayDevices removeLastObject];
	}
	
	[arrayDevices sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	
	return arrayDevices;
}

- (void)setupGrowl
{
	BOOL enabledLog = FALSE;
	
	char resC[2];
	NSString *res;
	FILE *fp = popen("defaults read com.Growl.GrowlHelperApp GrowlLoggingEnabled", "r");
	if (fp)
	{
		fgets(resC, sizeof resC, fp);		
		res = [NSString stringWithUTF8String:resC];
		
		if([res isEqualToString:@"1"])
		{
			enabledLog = TRUE;
		}
		
		pclose(fp);
	}
	
	
	if(! enabledLog)
	{
		system("defaults write com.Growl.GrowlHelperApp GrowlLoggingEnabled -int 1; killall GrowlHelperApp; open -a GrowlHelperApp.app");
	}
}

- (void)monitorGrowl
{
	char lineC[2048];
	//FILE *fp = popen("syslog -F '$(Message)' -w 1 -E none -d -k Sender GrowlHelperApp", "r");
	//FILE *fp = popen("syslog -F '$(Message)' -w 1 -E none -d", "r");
	FILE *fp = popen("syslog -F '$(Message)' -w 1 -E none", "r");
	
	NSString *buffer = nil;
	NSString *line;
	NSString *firstChars;
	
	if(fp)
	{
		while(fgets(lineC, sizeof lineC, fp))
		{
			line = [NSString stringWithUTF8String:lineC];
			
			if ([line length] >= 8)
			{
				firstChars = [line substringToIndex:8];
				
				if([firstChars isEqualToString:@"Spotify:"])
				{
					buffer = [NSString stringWithString:line];
					buffer = [buffer stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
				}
				else if(buffer != nil)
				{
					//[buffer appendString:line];
					buffer = [NSString stringWithFormat:@"%@ %@", buffer, line];
					
					latestNotification = [NSString stringWithString:buffer];
					
					if([self isAd:buffer])
					{
						[self changeAudioDevice:TRUE];
						[self changeMuteAndAddStatus:FALSE];
					}
					else
					{
						[self changeAudioDevice:FALSE];
						[self changeMuteAndAddStatus:TRUE];
					}
					
					
					buffer = nil;
				}
			}
			
		}
		pclose(fp);
	}

}

- (void)muteAndBlacklist
{
	[self changeAudioDevice:TRUE];
	[self changeMuteAndAddStatus:FALSE];
	
	if(latestNotification == nil)
		return;
	
	// escape the new rule
	NSString *rule = [NSString stringWithString:latestNotification];
	rule = [rule stringByReplacingOccurrencesOfString:@" - Priority 0" withString:@""];
	rule = [rule stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	rule = [self escapeRegex:rule];
	
	
	// add to nstextview
	NSString *regexString = [regex string];
	regexString = [regexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	regexString = [NSString stringWithFormat:@"%@\n%@.*", regexString, rule];
	[regex setString:regexString];
	
	// sync preferences
	[self syncRegexPreferences];

}

- (NSString *)escapeRegex:(NSString *)rule
{	
	rule = [rule stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];

	rule = [rule stringByReplacingOccurrencesOfString:@":" withString:@"\\:"];
	rule = [rule stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
	rule = [rule stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
	rule = [rule stringByReplacingOccurrencesOfString:@"{" withString:@"\\{"];
	rule = [rule stringByReplacingOccurrencesOfString:@"}" withString:@"\\}"];
	rule = [rule stringByReplacingOccurrencesOfString:@"^" withString:@"\\^"];
	rule = [rule stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
	rule = [rule stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
	rule = [rule stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
	rule = [rule stringByReplacingOccurrencesOfString:@"?" withString:@"\\?"];
	rule = [rule stringByReplacingOccurrencesOfString:@"*" withString:@"\\*"];
	rule = [rule stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"];
	rule = [rule stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
	rule = [rule stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
	
	return rule;
}

- (void)syncRegexPreferences
{
	[[NSUserDefaults standardUserDefaults] setObject:[regex string] forKey:@"customregex"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)initializeVars
{	
	// get path to switchaudio binary
	pathToSwitchAudio = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], @"Contents/Resources/SwitchAudioSource"];
	
	// get current device
	defaultOutput = [self systemCurrentDevice];
	
	// popup button with devices, etc
	[self refreshSaveddevices];
	
}

- (NSString *)adOutput
{
	NSString *adOutput;
	
	// get the ad output based in user preferences
	if([checkUseCustomDevice state] == 1) // checked
	{
		adOutput = [devices titleOfSelectedItem];
		
		if([adOutput isEqualToString:@""])
			adOutput = @"Soundflower (2ch)";
	}
	else
	{
		adOutput = @"Soundflower (2ch)";
	}
	
	return adOutput;
}

- (void)changeAudioDevice:(BOOL)mute
{
	NSString *command;
	
	if(mute)
	{
		[statusItem setImage:[NSImage imageNamed:@"status_active.png"]];
		command = [NSString stringWithFormat:@"%@ -t output -s '%@'", pathToSwitchAudio, [self adOutput]];
	}
	else
	{
		[statusItem setImage:[NSImage imageNamed:@"status_normal.png"]];
		command = [NSString stringWithFormat:@"%@ -t output -s '%@'", pathToSwitchAudio, defaultOutput];
	}
	
	system([command UTF8String]);
}

- (void)changeMuteAndAddStatus:(BOOL)enabled
{
	[muteAndAddMenu setEnabled:enabled];
}

- (BOOL)isAd:(NSString *)message
{
	NSString *regexString = [regex string];
	regexString = [regexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
	if([regexString isEqualToString:@""])
		return FALSE;
	
	NSArray *regexArray = [regexString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
	BOOL isAd = FALSE;
	NSPredicate *regextest;
	
	for(int i=0; i < [regexArray count] && isAd == FALSE; i++)
	{		
		@try {
			regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [regexArray objectAtIndex:i]];
			isAd = [regextest evaluateWithObject:message];
		}
		@catch (NSException * e) {

		}

	}
	
	return isAd;
}

- (void)validateRegex
{
	BOOL valid = TRUE;
	
	
	NSString *message = @"a";
	
	NSString *regexString = [regex string];
	regexString = [regexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
	if([regexString isEqualToString:@""])
		return;
	
	NSArray *regexArray = [regexString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	NSPredicate *regextest;
	
	for(int i=0; i < [regexArray count] && valid == TRUE; i++)
	{		
		@try {
			regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [regexArray objectAtIndex:i]];
			[regextest evaluateWithObject:message];
		}
		@catch (NSException * e) {
			valid = FALSE;
		}
		
	}
	
	if(valid)
	{
		[labelValid setTextColor:[NSColor colorWithCalibratedRed:0 green:0.6 blue:0 alpha:1]];
		[labelValid setStringValue:@"Valid!"];
	}
	else
	{
		[labelValid setTextColor:[NSColor colorWithCalibratedRed:0.6 green:0 blue:0 alpha:1]];
		[labelValid setStringValue:@"Not valid!"];
	}
	
}


- (void)setStatusItem:(NSStatusItem *)item
{
	statusItem = item;
}

- (void)setDevicesObject:(NSPopUpButton *)item
{
	devices = item;
}

- (void)setcheckUseCustomDevice:(NSButton *)item
{
	checkUseCustomDevice = item;
}

- (void)setRegex:(NSTextView *)item
{
	regex = item;
}

- (void)setMuteAndAdd:(NSMenuItem *)item
{
	muteAndAddMenu = item;
}

- (void)setLabelValid:(NSTextField *)item
{
	labelValid = item;
}

@end
