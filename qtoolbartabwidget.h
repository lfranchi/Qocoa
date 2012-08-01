#ifndef QTOOLBARTABWIDGET_H
#define QTOOLBARTABWIDGET_H

#include <QWidget>
#include <QScopedPointer>

class QToolbarTabWidgetPrivate;

class QAction;

class QToolbarTabWidget : public QWidget
{
    Q_OBJECT
public:
    explicit QToolbarTabWidget(QWidget *parent);
    virtual ~QToolbarTabWidget();

    void addTab(QWidget* page, const QIcon& icon, const QString& label, const QString& tooltip = QString());

public slots:
    void setCurrentIndex(int index);

private:
    const QScopedPointer<QToolbarTabWidgetPrivate> d_ptr;
    Q_DECLARE_PRIVATE(QToolbarTabWidget)

private slots:
    void actionTriggered(QAction*);
};

#endif // QTOOLBARTABWIDGET_H
