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

#include "qtoolbartabwidget.h"

#include "qocoa_mac.h"

#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSTabView.h>

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

@interface ToolbarDelegate : NSObject<NSToolbarDelegate>
{
    QToolbarTabWidgetPrivate *pimpl;
}
// Internal
-(void)setPrivate:(QToolbarTabWidgetPrivate*)withPimpl;

// NSToolbarItem action
-(void)changePanes:(id)sender;

// NSToolbarDelegate
-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar;
-(NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar;
-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar;
@end

class QToolbarTabWidgetPrivate {
public:
    QToolbarTabWidgetPrivate() {}
    
    ~QToolbarTabWidgetPrivate() {
        [toolBarDelegate release];
    }
    
    QMap<QString, ItemData> items;
    
    ToolbarDelegate *toolBarDelegate;
    NSTabView *tabView;
    NSToolbar *toolBar;
};


@implementation ToolbarDelegate

-(id) init {
    if( self = [super init] )
	{
		pimpl = nil;
	}
	
	return self;
}

-(void) setPrivate:(QToolbarTabWidgetPrivate *)withPimpl
{
    pimpl = withPimpl;
}

-(void)changePanes:(id)sender
{
    if (!pimpl)
        return;
    
    [pimpl->tabView selectTabViewItemAtIndex:[sender tag]];
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
        [toolbarItem setTag:[pimpl->tabView indexOfTabViewItemWithIdentifier:itemIdent]];
        
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
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableArray* defaultItems = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [pimpl->tabView numberOfTabViewItems]; i++) {
        [defaultItems addObject:[[pimpl->tabView tabViewItemAtIndex:i] identifier]];
    }
    
    [pool drain];
	return defaultItems;
}


-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
    if (!pimpl)
        return [NSArray array];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableArray* selectableItems = [[NSMutableArray alloc] init];
    
    Q_FOREACH( const QString& identQStr, pimpl->items.keys())
        [selectableItems addObject:fromQString(identQStr)];
    
    [pool drain];
    return selectableItems;
}

@end

QToolbarTabWidget::QToolbarTabWidget(QWidget *parent) :
    QWidget(parent),
    d_ptr(new QToolbarTabWidgetPrivate)
{
    Q_D(QToolbarTabWidget);
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    d->tabView = [[NSTabView alloc] init];
    [d->tabView setTabViewType:NSNoTabsNoBorder];
    
    d->toolBar = [[NSToolbar alloc] initWithIdentifier:[NSString stringWithFormat:@"%@.prefspanel.toolbar", fromQString(QCoreApplication::instance()->applicationName())]];
    [d->toolBar setAllowsUserCustomization: NO];
    [d->toolBar setAutosavesConfiguration: NO];
    [d->toolBar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    
    d->toolBarDelegate = [[ToolbarDelegate alloc] init];
    [d->toolBarDelegate setPrivate:d_ptr.data()];
    
    [d->toolBar setDelegate:d->toolBarDelegate];
    
    setupLayout(d->tabView, this);
    
    [[d->tabView window] setToolbar:d->toolBar];
    
    [pool drain];
}

QToolbarTabWidget::~QToolbarTabWidget()
{
    
}

void QToolbarTabWidget::addTab(QWidget* page, const QPixmap& icon, const QString& label, const QString& tooltip)
{
    Q_D(QToolbarTabWidget);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSTabViewItem* tabItem = [[NSTabViewItem alloc] initWithIdentifier:fromQString(label)];
    
    //NSView* view = reinterpret_cast<NSView*>(page->winId());
    page->setAttribute(Qt::WA_PaintOnScreen);
    
    
    QMacNativeWidget* nativeWidget = new QMacNativeWidget;
    nativeWidget->move(0, 0);
    nativeWidget->setPalette(page->palette());
    nativeWidget->setAutoFillBackground(true);
    QVBoxLayout* l = new QVBoxLayout;
    page->setAttribute(Qt::WA_LayoutUsesWidgetRect);
    l->addWidget(page);
    nativeWidget->setLayout(l);
    
    NSView *nativeView = reinterpret_cast<NSView*>(nativeWidget->winId());
    [d->tabView setAutoresizesSubviews:YES];
    
    
    [nativeView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
 
    [nativeView setFrameOrigin:NSZeroPoint];
    [nativeView setAutoresizesSubviews:YES];
    //[native setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    [d->tabView addSubview:nativeView positioned:NSWindowAbove relativeTo:nil];
    [tabItem setView:nativeView];
    nativeWidget->show();
    page->show();
    
    [d->tabView addTabViewItem:tabItem];
    [d->tabView selectTabViewItem:tabItem];
    
    ItemData data;
    data.icon = icon;
    data.text = label;
    data.tooltip = tooltip;
    data.page = page;
    d->items.insert(label, data);
    
    [d->toolBar insertItemWithItemIdentifier:[tabItem identifier] atIndex:[[d->toolBar items] count]];
    [d->toolBar setSelectedItemIdentifier:[tabItem identifier]];
    
    [pool drain];
}


void QToolbarTabWidget::actionTriggered(QAction* action)
{
    Q_D(QToolbarTabWidget);
    
}


void QToolbarTabWidget::setCurrentIndex(int index)
{
    Q_D(QToolbarTabWidget);
    
    [d->tabView selectTabViewItemAtIndex:index];
    
}

QSize QToolbarTabWidget::sizeHint() const
{
    Q_D(const QToolbarTabWidget);
    
    QSize hint;
//    hint.setWidth([[d->toolBar vie frame].size.width);
    const ItemData data = d->items.value(toQString([d->toolBar selectedItemIdentifier]));
    
    hint.setHeight(data.page->sizeHint().height());
    NSLog(@"Returning sizehint height: %f", data.page->sizeHint().height());
    return hint;
}
