/* X-Chat Aqua
 * Copyright (C) 2002 Steve Green
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA */

#import "AquaChat.h"
#import "PrefsController.h"
#import "ColorPalette.h"
#import "ChatWindow.h"

#include "../common/text.h"
#include "../common/xchatc.h"
#undef TYPE_BOOL
#include "../common/cfgfiles.h"

extern char *sound_files[];
extern struct text_event te[];
extern struct event_info text_event_info[];

//////////////////////////////////////////////////////////////////////

//@interface TriStateButtonCell : NSButtonCell

//////////////////////////////////////////////////////////////////////

@interface PrefLeaf : NSObject
{
  @public
	NSString	*label;
	int			pane;
}
@end

@implementation PrefLeaf
@end

PrefLeaf *leaf (NSString *label, int pane)
{
	PrefLeaf *l = [[PrefLeaf alloc] init];
	l->label = label;
	l->pane = pane;
	return l;
}

static NSArray *root_items;

//////////////////////////////////////////////////////////////////////

@interface SoundEvent : NSObject
{
  @public
	NSString	 *name;
	NSNumber	 *sound;
	NSNumber	 *growl;
	NSNumber	 *show;
	NSNumber	 *bounce;
}
@end

@implementation SoundEvent

- (id) initWithEvent:(int) event
			  sounds:(NSArray *) sounds
{
	self = [super init];
	
	name = [[NSString stringWithUTF8String:te[event].name] retain];
	
	int xx = 0;
	
	if (sound_files && sound_files [event])
	{
		for (NSUInteger i = 1; i < [sounds count]; i ++)
		{
			if (strcasecmp (sound_files [event], [[sounds objectAtIndex:i] UTF8String]) == 0)
			{
				xx = i;
				break;
			}
		}
	}
	
	struct event_info *info = &text_event_info[event];

	sound = [[NSNumber numberWithInt:xx] retain];
	growl = [[NSNumber numberWithInt:info->growl] retain];
	show = [[NSNumber numberWithInt:info->show] retain];
	bounce = [[NSNumber numberWithInt:info->bounce] retain];
		
	return self;
}

- (void) dealloc
{
	[name release];
	[sound release];
	[growl release];
	[bounce release];
	[show release];
	[super dealloc];
}

@end

//////////////////////////////////////////////////////////////////////

@interface MyButtonCell : NSButtonCell

@end

@implementation MyButtonCell

- (void) drawWithFrame:(NSRect) cellFrame 
				inView:(NSView *) controlView
{
	NSSize sz = [self cellSize];
	cellFrame.origin.x += (cellFrame.size.width - sz.width) / 2;
	[super drawWithFrame:cellFrame inView:controlView];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation PrefsController

- (id) init
{
	self = [super init];
	
	[NSBundle loadNibNamed:@"Prefs" owner:self];

	return self;
}

- (void) dealloc
{
	[sounds release];
	[sound_events release];
	[super dealloc];
}

- (void) populate
{
	NSUInteger n = sizeof (my_prefs) / sizeof (my_prefs [0]);

	for (NSUInteger i = 0; i < n; i ++)
	{
		switch (my_prefs[i].type)
		{
			case MYPREF_INT:
				[my_prefs[i].item setIntValue: * (int *) my_prefs [i].pref];
				break;
				
			case MYPREF_STRING:
			{
				const char *v = (const char *) my_prefs[i].pref;
				if (!v) v = "";
				NSString *tmp = [NSString stringWithUTF8String:v];
				[my_prefs[i].item setStringValue:tmp];	
				break;
			}
				
			case MYPREF_MENU:
				[my_prefs [i].item selectItemAtIndex: * (int *) my_prefs [i].pref];
				break;
		}
	}
	
	#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
	KeyCombo left_combo = { prefs.tab_left_modifiers, prefs.tab_left_key };
	[tabLeftRecorderCell setKeyCombo:left_combo];

	KeyCombo right_combo = { prefs.tab_right_modifiers, prefs.tab_right_key };
	[tabRightRecorderCell setKeyCombo:right_combo];
	#endif
	
	ColorPalette *palette = [[AquaChat sharedAquaChat] palette];
	
	if ([palette numberOfColors] != (sizeof(colors)/sizeof(colors[0])))
		NSLog(@"COLOR MAP OUT OF SYNC\n");
	
	for (NSUInteger i = 0; i < [palette numberOfColors]; i ++)
		[colors [i] setColor:[palette getColor:i]];
}

- (void) set
{
	NSUInteger n = sizeof (my_prefs) / sizeof (my_prefs [0]);
	
	for (NSUInteger i = 0; i < n; i ++)
	{
		switch (my_prefs[i].type)
		{
			case MYPREF_INT:
				* (int *) my_prefs [i].pref = [my_prefs [i].item intValue];
				break;
				
			case MYPREF_STRING:
			{
				NSString *s = [my_prefs [i].item stringValue];	
				strcpy ((char *) my_prefs [i].pref, [s UTF8String]);
				break;
			}

			case MYPREF_MENU:
				* (int *) my_prefs [i].pref = [my_prefs [i].item indexOfSelectedItem];
				break;
		}
	}

	#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
	KeyCombo left_combo = [tabLeftRecorderCell keyCombo];
	prefs.tab_left_modifiers = left_combo.flags;
	prefs.tab_left_key = left_combo.code;

	KeyCombo right_combo = [tabRightRecorderCell keyCombo];
	prefs.tab_right_modifiers = right_combo.flags;
	prefs.tab_right_key = right_combo.code;
	#endif

	ColorPalette *palette = [[[ColorPalette alloc] init] autorelease];
	for (NSUInteger i = 0; i < [palette numberOfColors]; i ++)
		[palette setColor:i color:[colors[i] color]];
	[[AquaChat sharedAquaChat] setPalette:palette];
	
	[[AquaChat sharedAquaChat] preferencesChanged];
}

- (void) find_colors
{
	// TBD: Magic number here!!!! '5'
	
	NSTabViewItem *color_pane = [tabView tabViewItemAtIndex:5];
	NSView *pane_view = [color_pane view];
	NSArray *subviews = [pane_view subviews];
	
	for (NSUInteger i = 0; i < [subviews count]; i ++)
	{
		NSView *view = (NSView *) [subviews objectAtIndex:i];
		
		if ([view isKindOfClass:[NSColorWell class]])
		{
			NSInteger color_index = [view tag];
			colors[color_index] = (NSColorWell *)view;
		}
	}
}

- (void) load_sounds
{
	sounds = [[NSMutableArray arrayWithCapacity:0] retain];
	
	[sounds addObject:NSLocalizedStringFromTable(@"<none>", @"xchat", @"")];
	
	NSString *bundle = [[NSBundle mainBundle] bundlePath];
	NSString *dir_name = [NSString stringWithFormat:@"%@/../Sounds", bundle];
	NSFileManager *manager = [NSFileManager defaultManager];
	#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
	NSArray *files = [manager contentsOfDirectoryAtPath:dir_name error:NULL];
	#else
	NSArray *files = [manager directoryContentsAtPath:dir_name];
	#endif
	
	for (NSUInteger i = 0; i < [files count]; i ++)
	{
		NSString *sound = (NSString *) [files objectAtIndex:i];
		NSString *full_path = [dir_name stringByAppendingFormat:@"/%@", sound];
		BOOL isDir;
		if ([manager fileExistsAtPath:full_path isDirectory:&isDir] && !isDir)
			[sounds addObject:sound];
	}

	NSArray *system_sounds = [SGSoundUtil systemSounds];
	
	for (NSUInteger i = 0; i < [system_sounds count]; i ++)
	{
		NSString *sound = (NSString *) [system_sounds objectAtIndex:i];
		[sounds addObject:sound];
	}
}

- (void) make_sound_menu
{
	NSPopUpButtonCell *cell = [[[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:false] autorelease];
	[cell setBordered:false];
	for (NSUInteger i = 0; i < [sounds count]; i ++)
	{
		NSString *sound = (NSString *) [sounds objectAtIndex:i];
		NSRange r = [sound rangeOfString:@"/" options:NSBackwardsSearch];
		if (r.location != NSNotFound)
			sound = [sound substringFromIndex:r.location + 1];
		[cell addItemWithTitle:sound];
	}
	[[[sounds_table tableColumns] objectAtIndex:1] setDataCell:cell];
}

- (void) get_sound_events
{
	sound_events = [[NSMutableArray arrayWithCapacity:0] retain];
	
	for (NSUInteger i = 0; i < NUM_XP; i ++)					  
	{
		SoundEvent *item = [[[SoundEvent alloc] initWithEvent:i sounds:sounds] autorelease];
		[sound_events addObject:item];
	}
	
	[sounds_table reloadData];
}

- (void) awakeFromNib
{
	struct my_pref xx [] = 
	{
		{ announce_away_check, &prefs.show_away_message, MYPREF_INT },
		{ auto_open_dcc_chat_list_check, &prefs.autoopendccchatwindow, MYPREF_INT },
		{ auto_open_dcc_receive_list_check, &prefs.autoopendccrecvwindow, MYPREF_INT },
		{ auto_open_dcc_send_list_check, &prefs.autoopendccsendwindow, MYPREF_INT },
		{ auto_reconnect_delay_text, &prefs.recon_delay, MYPREF_INT },
		{ auto_unmark_away_check, &prefs.auto_unmark_away, MYPREF_INT },
		{ tab_complete_check, &prefs.tab_completion, MYPREF_INT },
		{ away_message_text, &prefs.awayreason, MYPREF_STRING },
		{ beep_on_channel_messages_check, &prefs.input_beep_chans, MYPREF_INT },
		{ beep_on_private_check, &prefs.input_beep_priv, MYPREF_INT },
		{ bind_address_text, &prefs.hostname, MYPREF_STRING },
		{ channel_command_text, &prefs.channelcommand, MYPREF_STRING },
		{ colored_nicks_check, &prefs.colorednicks, MYPREF_INT },
		{ convert_spaces_check, &prefs.dcc_send_fillspaces, MYPREF_INT },
		{ dcc_address_text, &prefs.dcc_ip_str, MYPREF_STRING },
		{ doubleclick_command_text, &prefs.doubleclickuser, MYPREF_STRING },
		{ down_dir_text, &prefs.dccdir, MYPREF_STRING },
		{ enable_logging_check, &prefs.logging, MYPREF_INT },
		{ extra_highlight_words_text, &prefs.irc_extra_hilight, MYPREF_STRING },
		{ first_dcc_send_port_text, &prefs.first_dcc_send_port, MYPREF_INT },
		{ font_text, &prefs.font_normal, MYPREF_STRING },
		{ get_my_ip_check, &prefs.ip_from_server, MYPREF_INT },
		{ indent_nicks_check, &prefs.indent_nicks, MYPREF_INT },
		{ interpret_nnn_check, &prefs.perc_ascii, MYPREF_INT },
		{ interpret_percent_color, &prefs.perc_color, MYPREF_INT },
		{ last_dcc_send_port_text, &prefs.last_dcc_send_port, MYPREF_INT },
		{ log_filename_mask_text, &prefs.logmask, MYPREF_STRING },
		{ log_timestamp_format_text, &prefs.timestamp_log_format, MYPREF_STRING },
		{ insert_timestamps_check, &prefs.timestamp_logs, MYPREF_INT },
		{ notices_tab_check, &prefs.notices_tabs, MYPREF_INT },
		{ nick_command_text, &prefs.nickcommand, MYPREF_STRING },
		{ nick_completion_text, &prefs.nick_suffix, MYPREF_STRING },
		{ open_channels_in_menu, &prefs.tabchannels, MYPREF_MENU },
		{ open_dialogs_in_menu, &prefs.privmsgtab, MYPREF_MENU },
		{ open_utilities_in_menu, &prefs.windows_as_tabs, MYPREF_MENU },
		{ part_on_sleep_check, &prefs.partonsleep, MYPREF_INT },
		{ part_message_text, &prefs.partreason, MYPREF_STRING },
		{ pop_new_tabs_check, &prefs.newtabstofront, MYPREF_INT },
		{ proxy_port_text, &prefs.proxy_port, MYPREF_INT },
		{ proxy_server_text, &prefs.proxy_host, MYPREF_STRING },
		{ proxy_type_menu, &prefs.proxy_type, MYPREF_MENU },
		{ quit_message_text, &prefs.quitreason, MYPREF_STRING },
		{ raw_modes_check, &prefs.raw_modes, MYPREF_INT },
		{ server_tab_check, &prefs.use_server_tab, MYPREF_INT },
		{ show_away_once_check, &prefs.show_away_once, MYPREF_INT },
		{ show_channel_mode_buttons_check, &prefs.chanmodebuttons, MYPREF_INT },
		{ show_hostnames_check, &prefs.showhostname_in_userlist, MYPREF_INT },
		{ show_tab_at_menu, &prefs._tabs_position, MYPREF_MENU },
		{ spell_check_check, &prefs.spell_check, MYPREF_INT },
		{ strip_mirc_color_check, &prefs.stripcolor, MYPREF_INT },
		{ use_text_box_font_check, &prefs.style_inputbox, MYPREF_INT },
		{ time_stamp_format_text, &prefs.stamp_format, MYPREF_STRING },
		{ time_stamp_text_check, &prefs.timestamp, MYPREF_INT },
		{ hide_tab_close_check, &prefs.hide_tab_close_buttons, MYPREF_INT },
		{ show_separator_check, &prefs.show_separator, MYPREF_INT },
		{ url_command_text, &prefs.urlcommand, MYPREF_STRING },
		{ userlist_buttons_enabled_check, &prefs.userlistbuttons, MYPREF_INT },
		{ userlist_sort_menu, &prefs.userlist_sort, MYPREF_MENU },
		{ trans_slider, &prefs.tint_red, MYPREF_INT },
		{ trans_check, &prefs.transparent, MYPREF_INT },
		{ bounce_check, &prefs.bounce_private, MYPREF_INT },
		{ bounce_other_check, &prefs.bounce_other, MYPREF_INT },
		{ badge_private_check, &prefs.badge_private, MYPREF_INT },
		{ badge_other_check, &prefs.badge_other, MYPREF_INT },
		{ whois_on_notify_check, &prefs.whois_on_notifyonline, MYPREF_INT },
		{ hide_join_part_check, &prefs.confmode, MYPREF_INT },
		{ identd_check, &prefs.identd, MYPREF_INT },
		{ dcc_send_menu, &prefs.autodccsend, MYPREF_MENU },
		{ dcc_chat_menu, &prefs.autodccchat, MYPREF_MENU },
		{ auto_rejoin_check, &prefs.autorejoin, MYPREF_INT },
		{ never_give_up_check, &prefs.autoreconnectonfail, MYPREF_INT },
		{ auto_reconnect_check, &prefs.autoreconnect, MYPREF_INT },
		{ auto_dialog_check, &prefs.autodialog, MYPREF_INT },
		{ hide_userlist_check, &prefs.hideuserlist, MYPREF_INT },
		{ suffix_completion_check, &prefs.nickcompletion, MYPREF_INT },
		{ checkvers_check, &prefs.checkvers, MYPREF_INT },
		{ sleep_message_text, &prefs.sleepmessage, MYPREF_STRING },
		{ gui_metal_check, &prefs.guimetal, MYPREF_INT },
		{ scrolling_completion_check, &prefs.scrolling_completion, MYPREF_INT },
		{ charset_text, &prefs.default_charset, MYPREF_STRING },
		{ completed_downloads_text, &prefs.dcc_completed_dir, MYPREF_STRING },
		{ max_lines_text, &prefs.max_lines, MYPREF_INT },
		{ auto_away_text, &prefs.auto_away_delay, MYPREF_INT },
		{ auto_away_check, &prefs.auto_away, MYPREF_INT },
		{ save_nicknames_check, &prefs.dccwithnick, MYPREF_INT },
		{ nick_complete_sort_menu, &prefs.completion_sort, MYPREF_MENU },
	};
	
	// I was using #assert totally wrong.. this is the next best thing
	// to get a compile time error if the array sizes are different.
	// Credit where credit is due:
	//	http://www.jaggersoft.com/pubs/CVu11_3.html
	switch (0) { case 0: case (sizeof (xx) == sizeof (my_prefs)):; };
	
	for (NSUInteger i = 0; i < sizeof (xx) / sizeof (xx [0]); i ++)
	{
		my_prefs [i] = xx [i];
	}

	NSArray *interface= [NSArray arrayWithObjects:NSLocalizedStringFromTable(@"Interface", @"xchat", @""),
						 leaf (NSLocalizedStringFromTable(@"Text box", @"xchat", @""), 0),
						 leaf (NSLocalizedStringFromTable(@"Input box", @"xchat", @""), 1),
						 leaf (NSLocalizedStringFromTable(@"User list", @"xchat", @""), 2),
						 leaf (NSLocalizedStringFromTable(@"Tabs", @"xchat", @""), 3),
						 leaf (NSLocalizedStringFromTable(@"Other", @"xchataqua", @""), 4),
						 leaf (NSLocalizedStringFromTable(@"Colors", @"xchat", @""), 5),
						 nil];
	NSArray *chatting = [NSArray arrayWithObjects:NSLocalizedStringFromTable(@"Chatting", @"xchat", @""),
						 leaf (NSLocalizedStringFromTable(@"General", @"xchat", @""), 6),
						 leaf (NSLocalizedStringFromTable(@"Logging", @"xchat", @""), 7),
						 leaf (NSLocalizedStringFromTable(@"Events/Sounds", @"xchataqua", @""), 8),
						 nil];
	NSArray  *network = [NSArray arrayWithObjects:NSLocalizedStringFromTable(@"Network", @"xchat", @""),
						 leaf (NSLocalizedStringFromTable(@"Network setup", @"xchat", @""), 9),
						 leaf (NSLocalizedStringFromTable(@"DCC Settings", @"xchataqua", @""), 10),
						 nil];
	root_items = [[NSArray arrayWithObjects:interface, chatting, network, nil] retain];

	[category_list setDataSource:self];
	[category_list setDelegate:self];
	[category_list setIndentationPerLevel:15];

	[category_list expandItem:interface expandChildren:true];
	[category_list expandItem:chatting expandChildren:true];
	[category_list expandItem:network expandChildren:true];

	[sounds_table setDataSource:self];
	for (NSUInteger i = 0; i < [sounds_table numberOfColumns]; i ++)
		[[[sounds_table tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

	[self find_colors];
	[self load_sounds];
	[self make_sound_menu];
	[self get_sound_events];

	NSButtonCell *bcell = [[MyButtonCell alloc] initTextCell:@""];
	[bcell setButtonType:NSSwitchButton];
	[bcell setControlSize:NSMiniControlSize];
	[bcell setAllowsMixedState:YES];
	[[[sounds_table tableColumns] objectAtIndex:2] setDataCell:bcell];
	[[[sounds_table tableColumns] objectAtIndex:3] setDataCell:bcell];
	[bcell release];

	bcell = [[MyButtonCell alloc] initTextCell:@""];
	[bcell setButtonType:NSSwitchButton];
	[bcell setControlSize:NSMiniControlSize];
	[[[sounds_table tableColumns] objectAtIndex:4] setDataCell:bcell];
	[bcell release];

	[perform_always_check setIntValue:-1];

	[preferencesWindow setDelegate:self];
	[preferencesWindow center];
}

- (void) outlineViewSelectionDidChange:(NSNotification *) notification
{
	NSInteger row = [category_list selectedRow];
	id item = [category_list itemAtRow:row];
	
	if ([item isKindOfClass:[PrefLeaf class]])
	{
		PrefLeaf *l = (PrefLeaf *) item;
		
		[content_box setTitle:l->label];
		[tabView selectTabViewItemAtIndex:l->pane];
	}
}

- (void) do_trans:(id) sender
{
	[TabOrWindowView setTransparency:[trans_check intValue] ? [trans_slider intValue] : 255];
}

- (void) do_show_prefs:(id) sender
{
	NSString *s = [NSString stringWithFormat:@"file://%s", get_xdir_fs ()];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:s]];
}

- (void) do_apply:(id) sender
{
	[self set];
}

- (void) do_ok:(id) sender
{
	[self do_apply:sender];
	[preferencesWindow close];
}

- (void) do_cancel:(id) sender
{
	[TabOrWindowView setTransparency:prefs.transparent ? prefs.tint_red : 255];
	[preferencesWindow close];
}

- (void) do_font:(id) sender
{
	[preferencesWindow makeFirstResponder:preferencesWindow];
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager orderFrontFontPanel:self];
}

- (void) changeFont:(id) fontManager
{
	NSFont *font = [fontManager convertFont:[[AquaChat sharedAquaChat] font]];
	sprintf (prefs.font_normal, "%s %.1f", [[font fontName] UTF8String], [font pointSize]);
	[font_text setStringValue:[NSString stringWithUTF8String:prefs.font_normal]];
}

- (void) show
{
	[[NSFontManager sharedFontManager] setDelegate:self];
	[self populate];
	[preferencesWindow makeKeyAndOrderFront:self];
}

/////////////////////

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	id xx = item ? [item objectAtIndex:index + 1] : [root_items objectAtIndex:index];
	return xx;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return item ? [item isKindOfClass:[NSArray class]] ? true : false : true;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return item ? [item count] - 1 : [root_items count];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return [item isKindOfClass:[NSArray class]] ? 
		[item objectAtIndex:0] : ((PrefLeaf *)item)->label;
}

////////////
// Sounds Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [sound_events count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	SoundEvent *item = [sound_events objectAtIndex:row];

	switch ([[tableColumn identifier] integerValue])
	{
		case 0: return item->name;
		case 1: return item->sound;
		case 2: return item->growl;
		case 3: return item->bounce;
		case 4: return item->show;
	}

	return @"";
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	SoundEvent *item = [sound_events objectAtIndex:row];

	switch ([[tableColumn identifier] integerValue])
	{
		case 1:
		{
			[item->sound release];
			item->sound = [object retain];
							
			if (sound_files [row])
			{
				free (sound_files [row]);
				sound_files [row] = NULL;
			}
				
			NSInteger num = [object integerValue];
			if (num)
			{
				sound_files [row] = strdup ([[sounds objectAtIndex:num] UTF8String]);
				[[AquaChat sharedAquaChat] play_wave:sound_files [row]];
			}
				
			break;
		}
		
		case 2:
			[item->growl release];
			item->growl = [object retain];
			text_event_info[row].growl = [item->growl intValue];
			break;
				
		case 3:
			[item->bounce release];
			item->bounce = [object retain];
			text_event_info[row].bounce = [item->bounce intValue];
			break;

		case 4:
			[item->show release];
			item->show = [object retain];
			text_event_info[row].show = [item->show intValue];
			break;
	}
}

#pragma mark -
#pragma mark window delegate

- (BOOL)windowShouldClose:(id)sender
{
	[self do_ok:sender];
	return NO;
}

@end
