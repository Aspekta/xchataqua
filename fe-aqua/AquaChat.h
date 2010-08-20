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
/* AquaChat */

#include <glib/gslist.h>

#include "../common/xchat.h"
#include "../common/fe.h"

#import <Growl/GrowlApplicationBridge.h>

@class PrefsController;
@class ColorPalette;
@class ServerList;
@class ChannelListWin;
@class ChatWindow;
@class EditList;
@class EditEvents;
@class DccSendWin;
@class DccRecvWin;
@class DccChatWin;
@class RawLogWin;
@class UrlGrabberWin;
@class FriendListWin;
@class IgnoreListWin;
@class BanListWin;
@class AsciiWin;
@class PluginList;
@class PrefsController;
@class LogViewer;

struct session;

struct session_gui
{
    ChatWindow     	*cw;
    BanListWin		*ban_list;
};

struct server_gui
{
    ChannelListWin	*clc;
    RawLogWin		*rawlog;
    int				tab_group;
};

struct event_info
{
	int	growl;
	int show;
	int bounce;
};

extern struct event_info text_event_info[];

@interface AquaChat : NSObject <GrowlApplicationBridgeDelegate>
{
  @public
    IBOutlet NSMenuItem *awayMenuItem;
    IBOutlet NSMenuItem *invisibleMenuItem;
    IBOutlet NSMenuItem *newChannelTabMenuItem;
    IBOutlet NSMenuItem *newServerTabMenuItem;
    IBOutlet NSMenuItem *nextWindowMenuItem;
    IBOutlet NSMenuItem *previousWindowMenuItem;
    IBOutlet NSMenuItem *receiveNoticesMenuItem;
    IBOutlet NSMenuItem *receiveWallopsMenuItem;
    IBOutlet NSMenu *user_menu;
   
    NSString	*search_string;
    
    PrefsController *acprefs;
    ColorPalette *palette;
    
    NSFont	*font;
    NSFont	*boldFont;

    ServerList	*server_list;
    
    EditList	*user_commands;
    EditList	*ctcp_replies;
    EditList	*userlist_buttons;
    EditList	*userlist_popup;
    EditList	*dialog_buttons;
    EditList	*replace_popup;
    EditList	*url_handlers;
    EditList	*user_menus;
    EditEvents	*edit_events;
    
    DccSendWin	*dcc_send_window;
    DccRecvWin	*dcc_recv_window;
    DccChatWin	*dcc_chat_window;
    UrlGrabberWin *url_grabber;
    FriendListWin *notify_list;
    IgnoreListWin *ignore_window;
    AsciiWin	*ascii_window;
    PluginList	*plugin_list_win;
    PrefsController *prefs_controller;
    LogViewer       *log_viewer;
	
    NSMutableDictionary *sound_cache;
}

@property (nonatomic, readonly) NSFont *font, *boldFont;
@property (nonatomic, retain) ColorPalette *palette;

+ (AquaChat *) sharedAquaChat;

+ (void) forEachSessionOnServer:(struct server *)serv performSelector:(SEL)sel;
+ (void) forEachSessionOnServer:(struct server *)serv performSelector:(SEL)sel withObject:(id) obj;

- (void) preferencesChanged;

- (void) post_init;
- (void) cleanup;
- (void) set_away:(bool) is_away;
- (void) usermenu_update;
- (void) dcc_update:(struct DCC *) dcc;
- (void) dcc_add:(struct DCC *) dcc;
- (void) dcc_remove:(struct DCC *) dcc;
- (int) dcc_open_send_win:(bool) passive;
- (int) dcc_open_recv_win:(bool) passive;
- (int) dcc_open_chat_win:(bool) passive;
- (void) add_url:(const char *) url;
- (void) open_serverlist_for:(session *) sess;
- (void) notify_list_update;
- (void) ignore_update:(int) level;
- (void) pluginlist_update;
- (void) do_load_plugin:(id) sender;
- (void) play_wave:(const char *) fname;
- (void) event:(int) event args:(char **) args session:(session *) sess;
- (void) ctrl_gui:(session *) sess action:(int) action arg:(int) arg;
- (void) server_event:(server *)server event_type:(int)type arg:(int)arg;
- (void) growl:(const char *)text title:(const char *)title;
- (void) growl:(const char *)text;
@end
