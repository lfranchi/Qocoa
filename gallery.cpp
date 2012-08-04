#include "gallery.h"

#include <QVBoxLayout>
#include <QDialog>
#include <QDialogButtonBox>
#include <QIcon>
#include <QTextEdit>

#include "qsearchfield.h"
#include "qbutton.h"
#include "qprogressindicatorspinning.h"
#include "qtoolbartabwidget.h"

Gallery::Gallery(QWidget *parent) : QWidget(parent)
{
    setWindowTitle("Qocoa Gallery");
    QVBoxLayout *layout = new QVBoxLayout(this);

    QSearchField *searchField = new QSearchField(this);
    layout->addWidget(searchField);

    QSearchField *searchFieldPlaceholder = new QSearchField(this);
    searchFieldPlaceholder->setPlaceholderText("Placeholder text");
    layout->addWidget(searchFieldPlaceholder);

    QButton *roundedButton = new QButton(this, QButton::Rounded);
    roundedButton->setText("Button");
    layout->addWidget(roundedButton);

    QButton *regularSquareButton = new QButton(this, QButton::RegularSquare);
    regularSquareButton->setText("Button");
    layout->addWidget(regularSquareButton);

    QButton *disclosureButton = new QButton(this, QButton::Disclosure);
    layout->addWidget(disclosureButton);

    QButton *shadowlessSquareButton = new QButton(this, QButton::ShadowlessSquare);
    shadowlessSquareButton->setText("Button");
    layout->addWidget(shadowlessSquareButton);

    QButton *circularButton = new QButton(this, QButton::Circular);
    layout->addWidget(circularButton);

    QButton *textureSquareButton = new QButton(this, QButton::TexturedSquare);
    textureSquareButton->setText("Textured Button");
    layout->addWidget(textureSquareButton);

    QButton *helpButton = new QButton(this, QButton::HelpButton);
    layout->addWidget(helpButton);

    QButton *smallSquareButton = new QButton(this, QButton::SmallSquare);
    smallSquareButton->setText("Gradient Button");
    layout->addWidget(smallSquareButton);

    QButton *texturedRoundedButton = new QButton(this, QButton::TexturedRounded);
    texturedRoundedButton->setText("Round Textured");
    layout->addWidget(texturedRoundedButton);

    QButton *roundedRectangleButton = new QButton(this, QButton::RoundRect);
    roundedRectangleButton->setText("Rounded Rect Button");
    layout->addWidget(roundedRectangleButton);

    QButton *recessedButton = new QButton(this, QButton::Recessed);
    recessedButton->setText("Recessed Button");
    layout->addWidget(recessedButton);

    QButton *roundedDisclosureButton = new QButton(this, QButton::RoundedDisclosure);
    layout->addWidget(roundedDisclosureButton);

#ifdef __MAC_10_7
    QButton *inlineButton = new QButton(this, QButton::Inline);
    inlineButton->setText("Inline Button");
    layout->addWidget(inlineButton);
#endif

    QProgressIndicatorSpinning *progressIndicatorSpinning = new QProgressIndicatorSpinning(this);
    progressIndicatorSpinning->animate();
    layout->addWidget(progressIndicatorSpinning);

    QButton *openTabWidget = new QButton(this, QButton::Rounded);
    openTabWidget->setText("Toolbar Tab Widget");
    connect(openTabWidget, SIGNAL(clicked(bool)), this, SLOT(showTabToolbarWidget()));
    layout->addWidget(openTabWidget);
}

void Gallery::showTabToolbarWidget() {
//    QDialog *dialog = new QDialog;
//    dialog->setLayout(new QVBoxLayout);
//
//#ifdef Q_OS_MAC
//    dialog->layout()->setContentsMargins(0, 0, 0, 0);
//    dialog->layout()->setSpacing(0);
//
//#endif
    
    QToolbarTabDialog* toolbarTabDialog = new QToolbarTabDialog();

    QSearchField *searchField = new QSearchField(0);
    toolbarTabDialog->addTab(searchField, QPixmap( ":/user-home.png" ), "Home", "Go Home");

    QButton *b1 = new QButton(0, QButton::Recessed);
    b1->setText("You've reached the trash");
    toolbarTabDialog->addTab(b1, QPixmap( ":/user-trash.png" ), "Trash", "Trash it. Try me.");

    QButton *b2 = new QButton(0, QButton::RegularSquare);
    b2->setText("Search is futile");
    toolbarTabDialog->addTab(b2, QPixmap( ":/bookmarks.png" ), "Bookmarks", "Look for some bookmarks");

    QTextEdit* textEdit = new QTextEdit;
    textEdit->setText("This is some text!");
    toolbarTabDialog->addTab(textEdit, QPixmap( ":/bookmarks.png" ), "Text", "Some text editing eh?");
    
    
    /*
    dialog->layout()->addWidget(toolbarTabWidget);
    QDialogButtonBox *box = new QDialogButtonBox(QDialogButtonBox::Ok, Qt::Horizontal, dialog);
    connect(box, SIGNAL(accepted()), dialog, SLOT(accept()));
    dialog->layout()->addWidget(box);

    QWeakPointer<QDialog> that(dialog);
    dialog->setModal(true);
    dialog->exec();

    if (!that.isNull())
        delete dialog;
     */
}
