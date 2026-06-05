#include "mainwindow.h"
#include "./ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    os_information =new QTreeWidgetItem();
    hardware_information =new QTreeWidgetItem();
    software_information =new QTreeWidgetItem();
    network_information =new QTreeWidgetItem();

    distro =new QTreeWidgetItem(os_information);
    kernel =new QTreeWidgetItem(os_information);
    shell =new QTreeWidgetItem(os_information);

    model_name =new QTreeWidgetItem(hardware_information);
    architecture =new QTreeWidgetItem(hardware_information);
    model_cpu =new QTreeWidgetItem(hardware_information);
    cpu_cores_threads_sockets =new QTreeWidgetItem(hardware_information);
    ram =new QTreeWidgetItem(hardware_information);
    disque =new QTreeWidgetItem(hardware_information);

    paquet_count=new QTreeWidgetItem(software_information);
    process_count =new QTreeWidgetItem(software_information);

    hote_name =new QTreeWidgetItem(network_information);
    network_name =new QTreeWidgetItem(network_information);
    Ip4_address =new QTreeWidgetItem(network_information);


    os_information->setText(0, "OS INFORMATION");
    hardware_information->setText(0, "HARDWARE INFORMATION");
    software_information->setText(0, "SOFTWARE INFORMATION");
    network_information->setText(0, "NETWORK INFORMATION");
    distro->setText(0,"Distribution Linux");
    kernel->setText(0,"Kernel Linux");
    shell->setText(0,"Shell courant");
    model_name->setText(0,"Nom du modele");
    architecture->setText(0,"Architecture");
    model_cpu->setText(0,"Modele cpu");
    cpu_cores_threads_sockets->setText(0,"CPU core/thread/socket");
    ram->setText(0,"RAM");
    disque->setText(0,"Disque");
    paquet_count->setText(0,"Nombre de paquets installés");
    process_count->setText(0,"Nombre de processus en cours");
    hote_name->setText(0,"Nom d'hote");
    network_name->setText(0,"Nom du reseau");
    Ip4_address->setText(0,"Adresse Ipv4");

    ui->tree_information->addTopLevelItem(os_information);
    ui->tree_information->addTopLevelItem(hardware_information);
    ui->tree_information->addTopLevelItem(software_information);
    ui->tree_information->addTopLevelItem(network_information);
    connect(ui->tree_information, &QTreeWidget::itemClicked,this, &MainWindow::onItemClicked);
    listModel=new QStringListModel(this);
    ui->list_per_tree->setModel(listModel);
    scriptProcess = new QProcess(this);
    connect(scriptProcess, &QProcess::finished,this, &MainWindow::onScriptFinished);
    scriptProcess->setStandardErrorFile("/dev/null");
    scriptProcess->setProgram("bash");
    scriptProcess->setArguments({ QCoreApplication::applicationDirPath() + "/getinfo.sh"});
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("PATH", env.value("PATH") + ":/sbin:/usr/sbin:/usr/local/sbin");

    scriptProcess->setProcessEnvironment(env);
    scriptProcess->start();
}
void MainWindow::onItemClicked(QTreeWidgetItem *item, int column)
{
     Q_UNUSED(column);
    if(item == os_information)
    {
        showInfoGroup({"distro", "kernel", "shell"});
    }
    else if(item == hardware_information)
    {
        showInfoGroup({"model_name", "architecture", "model_cpu","cpu", "ram", "disque"});
    }
    else if(item == software_information)
    {
        showInfoGroup({"paquets", "processus"});
    }
    else if(item == network_information)
    {
        showInfoGroup({"hote", "ssid", "ipv4", "mac"});
    }
    else if(item == distro)
    {
        showInfo("distro");
    }
    else if(item == kernel)
    {
        showInfo("kernel");
    }
    else if(item == shell)
    {
        showInfo("shell");
    }
    else if(item == model_name)
    {
        showInfo("model_name");
    }
    else if(item == architecture)
    {
        showInfo("architecture");
    }
    else if(item == model_cpu)
    {
        showInfo("model_cpu");
    }
    else if(item == cpu_cores_threads_sockets)
    {
        showInfo("cpu");
    }
    else if(item == ram)
    {
        showInfo("ram");
    }
    else if(item == disque)
    {
        showInfo("disque");
    }
    else if(item == paquet_count)
    {
        showInfo("paquets");
    }
    else if(item == process_count)
    {
        showInfo("processus");
    }
    else if(item == hote_name)
    {
        showInfo("hote");
    }
    else if(item == network_name)
    {
        showInfo("ssid");
    }
    else if(item == Ip4_address)
    {
        showInfo("ipv4");
    }
}
void MainWindow::onScriptFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    if (exitStatus == QProcess::CrashExit || exitCode != 0)
    {
        listModel->setStringList({"Erreur : le script ne s'est pas terminé correctement."});
        return;
    }
    QByteArray rawOutput = scriptProcess->readAllStandardOutput();

    // Conversion en QString UTF-8
    QString output = QString::fromUtf8(rawOutput);

    //Nettoyage des codes couleur ANSI
    output.remove(QRegularExpression("\x1B\\[[0-9;]*m"));

    //Parsing ligne par ligne
    QString currentKey;

    QStringList lines = output.split('\n');
    for (QString &rawLine : lines)
    {
        if(rawLine.trimmed().isEmpty()) continue;

        bool isIndented = rawLine.startsWith(' ') || rawLine.startsWith('\t');

        if(isIndented && !currentKey.isEmpty())
        {
            QString subLine = rawLine.trimmed();
            if (subLine.isEmpty())
            {
                continue;
            }
            if (!subLine.contains('=') == false && subLine.replace('=', "").trimmed().isEmpty())
            {
                continue;
            }
            if (!subLine.contains(':') &&(subLine.contains("===") || subLine == subLine.toUpper()))
            {
                continue;
            }
            int sep = subLine.indexOf(':');
            if(sep != -1)
            {
                QString subKey = subLine.left(sep).trimmed();
                QString subVal = subLine.mid(sep + 1).trimmed();
                infoData[currentKey].append(subKey + " : " + subVal);
            }
            else
            {
                infoData[currentKey].append(subLine);
            }
        }
        else
        {
            //Ligne principale : "Clé: valeur"
            int sep = rawLine.indexOf(':');
            if (sep == -1) continue;

            QString key = rawLine.left(sep).trimmed().toLower();
            QString val = rawLine.mid(sep + 1).trimmed();

            if(key.contains("distribution"))
            {
                currentKey = "distro";
            }
            else if(key.contains("kernel") || key.contains("noyau"))
            {
                currentKey = "kernel";
            }
            else if(key == "interpreteur de commande (chemin)")
            {
                currentKey = "shell";
            }
            else if(key.contains("modèle machine") || key.contains("modele du machine"))
            {
                currentKey = "model_name";
            }
            else if(key == "architecture")
            {
                currentKey = "architecture";
            }
            else if(key.contains("modèle cpu") || key.contains("modele cpu"))
            {
                currentKey = "model_cpu";
            }
            else if(key.contains("socket"))
            {
                currentKey = "cpu";
            }
            else if(key == "ram")
            {
                currentKey = "ram";
            }
            else if(key.contains("disque"))
            {
                currentKey = "disque";
            }
            else if(key.contains("paquet"))
            {
                currentKey = "paquets";
            }
            else if(key.contains("processus"))
            {
                currentKey = "processus";
            }
            else if(key.contains("hote") || key.contains("nom de la machine"))
            {
                currentKey = "hote";
            }
            else if(key.contains("reseau"))
            {
                currentKey = "ssid";
            }
            else if(key.contains("adresse ipv4"))
            {
                currentKey = "ipv4";
            }
            else if(key.contains("mac"))
            {
                currentKey = "mac";
            }
            else
            {
                currentKey = key;
            }
            if (!val.isEmpty())
            {
                infoData[currentKey].append(val);
            }
        }
    }
    qDebug() << "[infoData] Clés parsées :" << infoData.keys();
}

void MainWindow::showInfo(const QString &key)
{
    if (infoData.contains(key))
    {
        listModel->setStringList(infoData.value(key));
    }
    else
    {
        listModel->setStringList({"Données non disponibles (script en cours…)"});
    }
}

void MainWindow::showInfoGroup(const QStringList &keys)
{
    QStringList all;
    for (const QString &k : keys)
    {
        if (infoData.contains(k))
        {
            all.append("── " + k.toUpper() + " ──");
            all.append(infoData.value(k));
        }
    }
    if (all.isEmpty())
    {
        all.append("Données non disponibles (script en cours…)");
    }
    listModel->setStringList(all);
}

MainWindow::~MainWindow()
{
    if (scriptProcess->state() != QProcess::NotRunning)
    {
        scriptProcess->terminate();
        scriptProcess->waitForFinished(2000);
    }
    delete ui;
}
