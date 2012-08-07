#ifndef GALLERY_H
#define GALLERY_H

#include <QWidget>

class QToolbarTabDialog;

class Gallery : public QWidget
{
    Q_OBJECT

public:
    explicit Gallery(QWidget *parent = 0);

public slots:
    void showTabToolbarWidget();
    void tabToolbarWidgetHidden();

private:
    QToolbarTabDialog* m_toolbarTabDialog;
};

#endif // WIDGET_H
