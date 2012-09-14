//
//  Smutefy.h
//  smutefy
//
//  Created by Ignacio de Tomás on 16/05/10.
//

#import <Cocoa/Cocoa.h>


@interface Smutefy : NSObject
{
	NSStatusItem *statusItem;
	NSString *defaultOutput;
	NSString *pathToSwitchAudio;
	NSString *latestNotification;
	
	NSPopUpButton *devices;
	NSButton *checkUseCustomDevice;
	
	NSTextView *regex;
	NSTextField *labelValid;
	NSMenuItem *muteAndAddMenu;
	NSMenuItem *unmuteMenu;
}

- (void)refreshSaveddevices;
- (void)monitorGrowl;
- (BOOL)isAd:(NSString *)message;
- (void)changeAudioDevice:(BOOL)mute;
- (void)setStatusItem:(NSStatusItem *)item;
- (void)setDevicesObject:(NSPopUpButton *)item;
- (void)setupGrowl;
- (void)initializeVars;
- (void)setcheckUseCustomDevice:(NSButton *)item;
- (NSMutableArray *)systemOutputDevices;
- (void)setRegex:(NSTextView *)item;
- (void)setMuteAndAdd:(NSMenuItem *)item;
- (void)setUnmute:(NSMenuItem *)item;
- (void)changeMuteAndAddStatus:(BOOL)enabled;
- (void)muteAndBlacklist;
- (void)unmute;
- (NSString *)escapeRegex:(NSString *)rule;
- (void)syncRegexPreferences;
- (void)setLabelValid:(NSTextField *)item;
- (void)validateRegex;

@end
