#include "qtoolbartabwidget.h"

#include <QToolBar>
#include <QStackedWidget>
#include <QAction>
#include <QVBoxLayout>

class QToolbarTabWidgetPrivate {
public:
    QToolbarTabWidgetPrivate() {}

    QVBoxLayout* layout;
    QWeakPointer<QToolBar> toolbar;
    QWeakPointer<QStackedWidget> stack;
    QWeakPointer<QFrame> separator;
    QActionGroup* actionGroup;
};

QToolbarTabWidget::QToolbarTabWidget(QWidget *parent) :
    QWidget(parent),
    d_ptr(new QToolbarTabWidgetPrivate)
{
    Q_D(QToolbarTabWidget);

    d->toolbar = QWeakPointer<QToolBar>(new QToolBar(this));
    d->toolbar.data()->setToolButtonStyle(Qt::ToolButtonTextUnderIcon);

    d->stack = QWeakPointer<QStackedWidget>(new QStackedWidget(this));

    d->separator = QWeakPointer<QFrame>(new QFrame(this));
    d->separator.data()->setFrameShape(QFrame::HLine);
    d->separator.data()->setFrameShadow(QFrame::Sunken);

    d->actionGroup = new QActionGroup(this);

    connect(d->toolbar.data(), SIGNAL(actionTriggered(QAction*)), this, SLOT(actionTriggered(QAction*)));

    d->layout = new QVBoxLayout;
    d->layout->addWidget(d->toolbar.data());
    d->layout->addWidget(d->separator.data());
    d->layout->addWidget(d->stack.data());
    setLayout(d->layout);
}

QToolbarTabWidget::~QToolbarTabWidget()
{

}

void QToolbarTabWidget::addTab(QWidget* page, const QPixmap& icon, const QString& label, const QString& tooltip)
{
    Q_D(QToolbarTabWidget);
    if (d->toolbar.isNull() || d->stack.isNull())
        return;

    QAction* action = new QAction(icon, label, d->toolbar.data());
    action->setCheckable(true);
    action->setToolTip(tooltip);

    d->actionGroup->addAction(action);

    d->toolbar.data()->addAction(action);
    d->stack.data()->addWidget(page);
}


void QToolbarTabWidget::actionTriggered(QAction* action)
{
    Q_D(QToolbarTabWidget);
    if (d->toolbar.isNull() || d->stack.isNull())
        return;

    const int idx = d->toolbar.data()->actions().indexOf(action);
    Q_ASSERT(idx > -1);
    if (idx < 0)
        return;

    d->stack.data()->setCurrentIndex(idx);
}


void QToolbarTabWidget::setCurrentIndex(int index)
{
    Q_D(QToolbarTabWidget);
    if (d->toolbar.isNull() || d->stack.isNull())
        return;

    Q_ASSERT(index < d->toolbar.data()->actions().length());
    Q_ASSERT(index < d->stack.data()->count());
    if (index < 0 || index > d->toolbar.data()->actions().length())
        return;
    if (index > d->stack.data()->count())
        return;

    if (d->stack.data()->currentIndex() != index)
        d->stack.data()->setCurrentIndex(index);
}
