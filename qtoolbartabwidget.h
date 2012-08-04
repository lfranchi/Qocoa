#ifndef QTOOLBARTABWIDGET_H
#define QTOOLBARTABWIDGET_H

#include <QScopedPointer>
#include <QWidget>
#include <QScopedPointer>

class QToolbarTabDialogPrivate;

class QAction;

class QToolbarTabDialog
{
public:
    QToolbarTabDialog();
    virtual ~QToolbarTabDialog();

    void addTab(QWidget* page, const QPixmap& icon, const QString& label, const QString& tooltip = QString());

//    QSize sizeHint() const;
    void setCurrentIndex(int index);

private:
    QScopedPointer<QToolbarTabDialogPrivate> pimpl;
};

#endif // QTOOLBARTABWIDGET_H
