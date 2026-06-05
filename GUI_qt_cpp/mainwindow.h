#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QListView>
#include <QTreeWidget>
#include <QStringListModel>
#include <QProcess>
#include <QMap>
#include <QStringList>
#include <QRegularExpression>
#include <QFile>
QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();
private slots:
    void onItemClicked(QTreeWidgetItem *item, int column);
    void onScriptFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    Ui::MainWindow *ui;
    QTreeWidgetItem *os_information, *hardware_information, *software_information, *network_information;

    QTreeWidgetItem *distro, *kernel, *shell;

    QTreeWidgetItem *model_name ,*architecture ,*model_cpu, *cpu_cores_threads_sockets, *ram ,*disque;

    QTreeWidgetItem *paquet_count,*process_count;

    QTreeWidgetItem *hote_name,*network_name,*Ip4_address;
    QProcess *scriptProcess;
    QMap<QString, QStringList> infoData;
    QStringListModel *listModel;
    void showInfoGroup(const QStringList &keys);
    void showInfo(const QString &key);
};
#endif // MAINWINDOW_H
