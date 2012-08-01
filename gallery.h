#ifndef GALLERY_H
#define GALLERY_H

#include <QWidget>

class Gallery : public QWidget
{
    Q_OBJECT

public:
    explicit Gallery(QWidget *parent = 0);

public slots:
    void showTabToolbarWidget();
};

#endif // WIDGET_H
