/*
 Copyright (C) 2012 by Leo Franchi <lfranchi@kde.org>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#include "QToolbarTabWidget.h"

#include "qocoa_mac.h"

#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSToolbar.h>

#include <QCoreApplication>
#include <QIcon>
#include <QMap>
#include <QUuid>
#include <QMacNativeWidget>

typedef struct {
    QPixmap icon;
    QString text, tooltip;
    QWidget* page;
} ItemData;

@interface ToolbarDelegate : NSObject<NSToolbarDelegate, NSWindowDelegate>
{
    QToolbarTabDialogPrivate *pimpl;
}
// Internal
-(void)setPrivate:(QToolbarTabDialogPrivate*)withPimpl;

// NSToolbarItem action
-(void)changePanes:(id)sender;

// NSToolbarDelegate
-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar;
-(NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar;
-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar;

// NSWindowDelegate
-(NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize;
@end

class QToolbarTabDialogPrivate {
public:
    QToolbarTabDialogPrivate() : currentPane(NULL), minimumWidthForToolbar(0) {}
    
    ~QToolbarTabDialogPrivate() {
        [toolBarDelegate release];
    }
    
    void calculateSize() {
        NSRect windowFrame = [prefsWindow frame];
        
        while ([[toolBar visibleItems] count] < [[toolBar items] count]) {
            //Each toolbar item is 32x32; we expand by one toolbar item width repeatedly until they all fit
            windowFrame.origin.x -= 16;
            windowFrame.size.width += 16;
            
            [prefsWindow setFrame:windowFrame display:NO];
            [prefsWindow setMinSize: windowFrame.size];
        }
        minimumWidthForToolbar = windowFrame.size.width;

        
    }
    
    void showPaneWithIdentifier(NSString* ident) {
//
//        if (currentPane) {
//            NSView* oldPane = [panes objectForKey:currentPane];
//            [oldPane removeFromSuperview];
//        }
//        
//        [prefsWindow makeFirstResponder:nil];
//        [[prefsWindow contentView] addSubview:[panes objectForKey:ident] positioned:NSWindowAbove relativeTo:nil];
//
        [prefsWindow setContentView: [panes objectForKey:ident]];
        currentPane = ident;
        
        resizeCurrentPageToSize([[prefsWindow contentView] frame].size);
    }
    
    void resizeCurrentPageToSize(NSSize frameSize) {
        
        [[panes objectForKey:currentPane] setFrameSize:frameSize];
        
        const QString curPane = toQString(currentPane);
        if (items.contains(curPane) && items[curPane].page) {
            items[curPane].page->resize(frameSize.width, frameSize.height);
        }
    }
    
    QMap<QString, ItemData> items;
    
    NSWindow* prefsWindow;
    ToolbarDelegate *toolBarDelegate;
    NSMutableDictionary *panes;
    NSToolbar *toolBar;
    NSString* currentPane;
    
    int minimumWidthForToolbar;
};


@implementation ToolbarDelegate

-(id) init {
    if( self = [super init] )
	{
		pimpl = nil;
	}
	
	return self;
}

-(void) setPrivate:(QToolbarTabDialogPrivate *)withPimpl
{
    pimpl = withPimpl;
}

-(void)changePanes:(id)sender
{
    if (!pimpl)
        return;
    
    pimpl->showPaneWithIdentifier([pimpl->toolBar selectedItemIdentifier]);
    //[pimpl->tabView selectTabViewItemAtIndex:[sender tag]];
	//[[pimpl->tabView window] setTitle:[baseWindowName stringByAppendingString: [sender label]]];
	
	//key = [NSString stringWithFormat: @"%@.prefspanel.recentpage", autosaveName];
	//[[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:key];

}

-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    if (!pimpl)
        return nil;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSToolbarItem   *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	const QString identQStr = toQString(itemIdent);
    if (pimpl->items.contains(identQStr))
    {
        ItemData data = pimpl->items[identQStr];
        NSString* label = fromQString(data.text);
        
        [toolbarItem setLabel:label];
        [toolbarItem setPaletteLabel:label];
        
        [toolbarItem setToolTip:fromQString(data.tooltip)];
        [toolbarItem setImage:fromQPixmap(data.icon)];
        
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(changePanes:)];

    } else {
        toolbarItem = nil;
    }
	
    [pool drain];
    return toolbarItem;
}

-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    if (!pimpl)
        return [NSArray array];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	NSMutableArray* allowedItems = [[NSMutableArray alloc] init];
    
    Q_FOREACH( const QString& identQStr, pimpl->items.keys())
        [allowedItems addObject:fromQString(identQStr)];
    
	[allowedItems addObjectsFromArray:[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
                                        NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,
                                        NSToolbarCustomizeToolbarItemIdentifier, nil] ];
	
    [pool drain];
    
	return allowedItems;
}


-(NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    if (!pimpl)
        return [NSArray array];
    
    return [[NSMutableArray alloc] initWithArray:[pimpl->panes allKeys]];

}


-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
    if (!pimpl)
        return [NSArray array];
    
    return [[NSMutableArray alloc] initWithArray:[pimpl->panes allKeys]];
}

-(NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    if (!pimpl)
        return frameSize;
    
    pimpl->resizeCurrentPageToSize(frameSize);
    
    return frameSize;
}
@end

QToolbarTabDialog::QToolbarTabDialog() :
    pimpl(new QToolbarTabDialogPrivate)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    pimpl->panes = [[NSMutableDictionary alloc] init];
    
    pimpl->prefsWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 350, 200)
                                           styleMask:NSClosableWindowMask | NSResizableWindowMask | NSTitledWindowMask
                                           backing:NSBackingStoreBuffered
                                           defer:NO];

    [pimpl->prefsWindow setReleasedWhenClosed:YES];
    [pimpl->prefsWindow setTitle:@"Preferences"]; // initial default title
    
    pimpl->toolBar = [[NSToolbar alloc] initWithIdentifier:[NSString stringWithFormat:@"%@.prefspanel.toolbar", fromQString(QCoreApplication::instance()->applicationName())]];
    [pimpl->toolBar setAllowsUserCustomization: NO];
    [pimpl->toolBar setAutosavesConfiguration: NO];
    [pimpl->toolBar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    
    pimpl->toolBarDelegate = [[ToolbarDelegate alloc] init];
    [pimpl->toolBarDelegate setPrivate:pimpl.data()];
    
    [pimpl->prefsWindow setDelegate:pimpl->toolBarDelegate];
    
    [pimpl->toolBar setDelegate:pimpl->toolBarDelegate];
    
    [pimpl->prefsWindow setToolbar:pimpl->toolBar];
    
    pimpl->calculateSize();
        
    // For testing only
//    NSTextView* textEdit = [[NSTextView alloc] initWithFrame:[[pimpl->prefsWindow contentView] frame]];
//    [textEdit setAutoresizesSubviews:YES];
//    [textEdit setVerticallyResizable:NO];
//    [textEdit setHorizontallyResizable:NO];
//    [textEdit setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
//    NSString* identifier = @"Text Cocoa";
//    [pimpl->panes setObject:textEdit forKey:identifier];
//    
//    ItemData data;
//    data.icon = QPixmap(":/bookmarks.png");
//    data.text = "Text Cocoa";
//    data.tooltip = "Text";
//    data.page = 0;
//    pimpl->items.insert("Text Cocoa", data);
//    [pimpl->toolBar insertItemWithItemIdentifier:identifier atIndex:[[pimpl->toolBar items] count]];
//    [pimpl->toolBar setSelectedItemIdentifier:identifier];
//    [[pimpl->prefsWindow contentView] addSubview:textEdit positioned:NSWindowAbove relativeTo:nil];
//    pimpl->currentPane = identifier;
//    
    [pimpl->prefsWindow makeKeyAndOrderFront:nil];

    [pool drain];
}

QToolbarTabDialog::~QToolbarTabDialog()
{
    
}

void QToolbarTabDialog::addTab(QWidget* page, const QPixmap& icon, const QString& label, const QString& tooltip)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString* identifier = fromQString(label);
    
    QMacNativeWidget* nativeWidget = new QMacNativeWidget;
    nativeWidget->move(0, 0);
    nativeWidget->setPalette(page->palette());
    nativeWidget->setAutoFillBackground(true);
    
    QVBoxLayout* l = new QVBoxLayout;
    l->setContentsMargins(2, 2, 2, 2);
    l->setSpacing(0);
    page->setAttribute(Qt::WA_LayoutUsesWidgetRect);
    l->addWidget(page);
    nativeWidget->setLayout(l);
    
    NSView *nativeView = reinterpret_cast<NSView*>(nativeWidget->winId());
    [nativeView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [nativeView setAutoresizesSubviews:YES];
    
    nativeWidget->show();
    
    ItemData data;
    data.icon = icon;
    data.text = label;
    data.tooltip = tooltip;
    data.page = nativeWidget;
    pimpl->items.insert(label, data);
    
    [pimpl->panes setObject:nativeView forKey:identifier];
    
    pimpl->showPaneWithIdentifier(identifier);
    
    [pimpl->toolBar insertItemWithItemIdentifier:identifier atIndex:[[pimpl->toolBar items] count]];
    [pimpl->toolBar setSelectedItemIdentifier:identifier];
    [[pimpl->prefsWindow standardWindowButton:NSWindowZoomButton] setEnabled:NO];
     
    pimpl->calculateSize();
    [pool drain];
}


void QToolbarTabDialog::setCurrentIndex(int index)
{
//    [pimpl->tabView selectTabViewItemAtIndex:index];
    
}

