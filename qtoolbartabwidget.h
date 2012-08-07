#ifndef QTOOLBARTABWIDGET_H
#define QTOOLBARTABWIDGET_H

#include <QObject>
#include <QScopedPointer>
#include <QPixmap>

class QToolbarTabDialogPrivate;

class QAction;

/**
 Dialog with a toolbar that behaves like a tab widget.

 Note that on OS X there are no OK/Cancel dialogs, every setting should be applied immediately.
 The accepted() signal will be emitted on close/hide regardless.
 */
class QToolbarTabDialog : public QObject
{
    Q_OBJECT
public:
    QToolbarTabDialog();
    virtual ~QToolbarTabDialog();

    void addTab(QWidget* page, const QPixmap& icon, const QString& label, const QString& tooltip = QString());

    void setCurrentIndex(int index);

    void show();
    void hide();

Q_SIGNALS:
    void accepted();
    void rejected();

private:
    QScopedPointer<QToolbarTabDialogPrivate> pimpl;

    friend class ::QToolbarTabDialogPrivate;
};

#endif // QTOOLBARTABWIDGET_H
