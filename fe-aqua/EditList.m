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

#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/cfgfiles.h"

#import "EditList.h"
#import "SGAlert.h"

//////////////////////////////////////////////////////////////////////

@interface EditListItem : NSObject
{
	NSString	*name;
	NSString	*command;
}

@property (nonatomic, retain) NSString *name, *command;

@end

@implementation EditListItem
@synthesize name, command;

- (id) initWithName:(NSString *)aName command:(NSString *)aCommand
{
	self = [super init];
	
	self.name = aName;
	self.command = aCommand;
	
	return self;
}

- (void) dealloc
{
	self.name = nil;
	self.command = nil;
	
	[super dealloc];
}

- (NSComparisonResult) sort:(EditListItem *) other
{
	return [name compare:other->name];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation EditList

- (id) initWithList:(GSList **)aSlist filename:(NSString *)aFilename title:(NSString *)aTitle
{
	self = [super init];
	
	self->slist = aSlist;
	self->filename = [aFilename copy];
	self->title = [aTitle copy];
	self->listItems = [[NSMutableArray alloc] init];
	
	[NSBundle loadNibNamed:@"EditList" owner:self];
	
	return self;
}

- (void) dealloc
{
	[[commandTableView window] release];
	[filename release];
	[title release];
	[listItems release];
	
	[super dealloc];
}

- (void) awakeFromNib
{
	for (NSUInteger i = 0; i < [commandTableView numberOfColumns]; i ++)
		[[[commandTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInteger:i]];
	
	[commandTableView setDelegate:self];
	[commandTableView setDataSource:self];
	[[commandTableView window] setTitle:title];
	[[commandTableView window] center];
}

- (void) loadItems
{
	[listItems removeAllObjects];
	
	for (GSList *list = *slist; list; list = list->next)
	{
		struct popup *pop = (struct popup *) list->data;
		EditListItem *item = [[EditListItem alloc] initWithName:[NSString stringWithUTF8String:pop->name] command:[NSString stringWithUTF8String:pop->cmd]];
		[listItems addObject:item];
		[item release];
	}
	
	[commandTableView reloadData];
}

- (void) show
{
	[self loadItems];
	[[commandTableView window] makeKeyAndOrderFront:self];
}

- (void) doDelete:(id)sender
{
	[commandTableView abortEditing];
	NSInteger row = [commandTableView selectedRow];
	
	if (row < 0) return;
	
	[listItems removeObjectAtIndex:row];
	[commandTableView reloadData];
}

- (void) doDown:(id) sender
{
	NSInteger row = [commandTableView selectedRow];
	if (row < 0 || row >= (NSInteger)[listItems count] - 1) return;
	
	[listItems exchangeObjectAtIndex:row withObjectAtIndex:row+1];
	[commandTableView reloadData];
	[commandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row+1] byExtendingSelection:NO];
}

- (void) doHelp:(id) sender
{
	[SGAlert alertWithString:NSLocalizedStringFromTable(@"Not implemented (yet)", @"xchataqua", @"Alert message when a feature not implemented yet is tried") andWait:false];
}

- (void) doNew:(id) sender
{
	EditListItem *item = [[EditListItem alloc] initWithName:NSLocalizedStringFromTable(@"*NEW*", @"xchataqua", @"Default item name for EditList") command:NSLocalizedStringFromTable(@"EDIT ME", @"xchataqua", @"Default item name for EditList")];
	[listItems insertObject:item atIndex:0];
	[item release];
	[commandTableView reloadData];
	[commandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[commandTableView editColumn:0 row:0 withEvent:nil select:YES];
}

- (void) doSave:(id) sender
{
	[[sender window] makeFirstResponder:sender];
	
	NSString *buf = [NSString stringWithFormat:@"%s/%s", get_xdir_fs(), [filename UTF8String]];
	
	FILE *f = fopen ([buf UTF8String], "w");
	if (f == NULL) return;
	
	for (NSUInteger i = 0; i < [listItems count]; i ++)
	{
		EditListItem *item = [listItems objectAtIndex:i];
		fprintf (f, "NAME %s\ncommand %s\n\n", [[item name] UTF8String], [[item command] UTF8String]);
	}
	fclose (f);
	
	list_free(slist);
	list_loadconf((char *)[filename UTF8String], slist, 0);
	
	[[sender window] orderOut:sender];
}

- (void) doSort:(id) sender
{
	[listItems sortUsingSelector:@selector(sort:)];
	[commandTableView reloadData];
}

- (void) doUp:(id) sender
{
	NSInteger row = [commandTableView selectedRow];
	if (row < 1) return;
	
	[listItems exchangeObjectAtIndex:row withObjectAtIndex:row-1];
	[commandTableView reloadData];
	[commandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row-1] byExtendingSelection:NO];
}

#pragma mark -
#pragma mark table view protocols

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
	return [listItems count];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	EditListItem *item = [listItems objectAtIndex:rowIndex];
	
	switch ([[aTableColumn identifier] integerValue])
	{
		case 0: return [item name];
		case 1: return [item command];
	}
	
	return @"";
}

- (void) tableView:(NSTableView *) aTableView
	setObjectValue:(id) anObject
	forTableColumn:(NSTableColumn *) aTableColumn
			   row:(NSInteger)rowIndex
{
	EditListItem *item = [listItems objectAtIndex:rowIndex];
	
	switch ([[aTableColumn identifier] integerValue])
	{
		case 0: [item setName:anObject]; break;
		case 1: [item setCommand:anObject]; break;
	}
}

@end
