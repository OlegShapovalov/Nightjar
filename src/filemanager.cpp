#include "filemanager.h"
#include <QGuiApplication>
#include <QClipboard>
#include <QProcess>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QStorageInfo>
#include <QDir>
#include <QDebug>
#include <QSettings>
#include <QJSValue>
#include <QFontDatabase>
#include <QStandardPaths>
#include <QThread>
#include <QElapsedTimer>
#include <cstdlib>
#include <filesystem>
#include <algorithm>

namespace fs = std::filesystem;

FileManager::FileManager(QObject* parent) : QObject(parent) {
    QCoreApplication::setOrganizationName("Nightjar");
    QCoreApplication::setApplicationName("Nightjar");
}

QString FileManager::homePath() const {
    return QDir::homePath();
}

static QVariant normalizeJsValue(const QVariant& val) {
    if (val.userType() == qMetaTypeId<QJSValue>()) {
        QJSValue jsVal = val.value<QJSValue>();
        return jsVal.toVariant();
    }
    return val;
}

void FileManager::saveSetting(const QString& key, const QVariant& value) {
    QSettings settings;
    settings.setValue(key, normalizeJsValue(value));
}

QVariant FileManager::getSetting(const QString& key, const QVariant& defaultValue) {
    QSettings settings;
    if (!settings.contains(key)) {
        return defaultValue;
    }
    return normalizeJsValue(settings.value(key, defaultValue));
}

QStringList FileManager::getAvailableFonts() {
    QStringList fonts = QFontDatabase::families();
    fonts.sort(Qt::CaseInsensitive);

    QStringList result;
    result << "По умолчанию (System Monospace)";

    for (const auto& f : fonts) {
        if (QFontDatabase::isFixedPitch(f)) {
            result << f;
        }
    }

    if (result.size() <= 1) {
        for (const auto& f : fonts) {
            result << f;
        }
    }
    return result;
}

void FileManager::copyToClipboard(const QStringList& texts) {
    if (texts.isEmpty()) return;
    QClipboard* clipboard = QGuiApplication::clipboard();
    if (clipboard) {
        clipboard->setText(texts.join("\n"));
    }
}

QVariantList FileManager::readDir(const QString& pathStr, const QString& sortBy, bool sortAsc, bool showHidden) {
    QVariantList result;
    fs::path p(pathStr.toStdString());

    if (!fs::exists(p) || !fs::is_directory(p)) return result;

    if (p.has_parent_path() && p != p.parent_path()) {
        QVariantMap parentItem;
        parentItem["name"] = "..";
        parentItem["path"] = QString::fromStdString(p.parent_path().string());
        parentItem["isDir"] = true;
        parentItem["sizeBytes"] = 0;
        parentItem["size"] = "";
        parentItem["modified"] = "";
        parentItem["selected"] = false;
        result.append(parentItem);
    }

    struct ItemData {
        std::string name;
        std::string path;
        bool isDir;
        uintmax_t size;
        int64_t mtime;
    };

    std::vector<ItemData> entries;
    try {
        for (const auto& entry : fs::directory_iterator(p)) {
            std::string fname = entry.path().filename().string();
            
            if (!showHidden && !fname.empty() && fname[0] == '.') {
                continue;
            }

            ItemData item;
            item.name = fname;
            item.path = entry.path().string();
            item.isDir = entry.is_directory();
            item.size = 0;
            item.mtime = 0;

            try {
                if (!item.isDir) item.size = entry.file_size();
                auto ftime = entry.last_write_time();
                auto sctp = std::chrono::time_point_cast<std::chrono::system_clock::duration>(
                    ftime - fs::file_time_type::clock::now() + std::chrono::system_clock::now()
                );
                item.mtime = std::chrono::duration_cast<std::chrono::seconds>(sctp.time_since_epoch()).count();
            } catch (...) {}

            entries.push_back(item);
        }
    } catch (...) {
        return result;
    }

    std::sort(entries.begin(), entries.end(), [&](const ItemData& a, const ItemData& b) {
        if (a.isDir != b.isDir) return a.isDir > b.isDir;
        if (sortBy == "size") return sortAsc ? (a.size < b.size) : (a.size > b.size);
        if (sortBy == "date") return sortAsc ? (a.mtime < b.mtime) : (a.mtime > b.mtime);
        return sortAsc ? (a.name < b.name) : (a.name > b.name);
    });

    for (const auto& entry : entries) {
        QVariantMap item;
        item["name"] = QString::fromStdString(entry.name);
        item["path"] = QString::fromStdString(entry.path);
        item["isDir"] = entry.isDir;
        item["sizeBytes"] = static_cast<qulonglong>(entry.size);
        item["selected"] = false;

        if (entry.isDir) {
            item["size"] = "<DIR>";
        } else {
            if (entry.size < 1024) item["size"] = QString::number(entry.size) + " B";
            else if (entry.size < 1024 * 1024) item["size"] = QString::number(entry.size / 1024.0, 'f', 1) + " KB";
            else item["size"] = QString::number(entry.size / (1024.0 * 1024.0), 'f', 1) + " MB";
        }

        if (entry.mtime > 0) {
            QDateTime dt = QDateTime::fromSecsSinceEpoch(entry.mtime);
            item["modified"] = dt.toString("dd.MM.yyyy hh:mm");
        } else {
            item["modified"] = "";
        }
        result.append(item);
    }
    return result;
}

QString FileManager::getFreeDiskSpace(const QString& pathStr) {
    QStorageInfo storage(pathStr);
    if (storage.isValid() && storage.isReady()) {
        double freeGb = storage.bytesAvailable() / (1024.0 * 1024.0 * 1024.0);
        double totalGb = storage.bytesTotal() / (1024.0 * 1024.0 * 1024.0);
        return QString("%1 GB свободно из %2 GB").arg(freeGb, 0, 'f', 1).arg(totalGb, 0, 'f', 1);
    }
    return "";
}

QString FileManager::calculateDirSize(const QString& pathStr) {
    fs::path p(pathStr.toStdString());
    if (!fs::exists(p) || !fs::is_directory(p)) return "<DIR>";

    uintmax_t totalSize = 0;
    try {
        for (const auto& entry : fs::recursive_directory_iterator(p, fs::directory_options::skip_permission_denied)) {
            try {
                if (entry.is_regular_file() && !entry.is_symlink()) totalSize += entry.file_size();
            } catch (...) {}
        }
    } catch (...) {
        return "Ошибка";
    }

    if (totalSize < 1024) return QString::number(totalSize) + " B";
    if (totalSize < 1024 * 1024) return QString::number(totalSize / 1024.0, 'f', 1) + " KB";
    if (totalSize < 1024 * 1024 * 1024) return QString::number(totalSize / (1024.0 * 1024.0), 'f', 1) + " MB";
    return QString::number(totalSize / (1024.0 * 1024.0 * 1024.0), 'f', 2) + " GB";
}

void FileManager::openFile(const QString& path) {
    QProcess* proc = new QProcess(this);
    proc->setStandardOutputFile(QProcess::nullDevice());
    proc->setStandardErrorFile(QProcess::nullDevice());
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), proc, &QObject::deleteLater);
    proc->start("xdg-open", {path});
}

void FileManager::editFile(const QString& path, const QString& customEditor) {
    QString editorStr = customEditor.trimmed();
    if (editorStr.isEmpty()) {
        const char* editorEnv = std::getenv("VISUAL");
        if (!editorEnv || std::string(editorEnv).empty()) editorEnv = std::getenv("EDITOR");
        if (editorEnv && !std::string(editorEnv).empty()) {
            editorStr = QString::fromUtf8(editorEnv);
        }
    }

    if (!editorStr.isEmpty()) {
        if (editorStr.contains("vim") || editorStr.contains("nano") || editorStr.contains("vi")) {
            QProcess::startDetached("x-terminal-emulator", {"-e", editorStr, path});
            return;
        }
        QProcess* proc = new QProcess(this);
        proc->setStandardOutputFile(QProcess::nullDevice());
        proc->setStandardErrorFile(QProcess::nullDevice());
        connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), proc, &QObject::deleteLater);
        proc->start("/bin/sh", {"-c", QString("%1 \"%2\"").arg(editorStr, path)});
    } else {
        openFile(path);
    }
}

void FileManager::runCommand(const QString& workingDir, const QString& command) {
    if (command.trimmed().isEmpty()) return;
    QProcess* proc = new QProcess(this);
    proc->setWorkingDirectory(workingDir);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, proc](int, QProcess::ExitStatus) {
        emit commandFinished();
        proc->deleteLater();
    });
    proc->start("/bin/sh", {"-c", command});
}

bool FileManager::createDirectory(const QString& basePath, const QString& dirName) {
    try {
        return fs::create_directories(fs::path(basePath.toStdString()) / dirName.toStdString());
    } catch (...) { return false; }
}

bool FileManager::deleteItems(const QStringList& paths) {
    bool ok = true;
    for (const auto& path : paths) {
        try {
            if (fs::remove_all(fs::path(path.toStdString())) == 0) ok = false;
        } catch (...) { ok = false; }
    }
    return ok;
}

static QString formatSize(uintmax_t bytes) {
    if (bytes < 1024) return QString::number(bytes) + " B";
    if (bytes < 1024 * 1024) return QString::number(bytes / 1024.0, 'f', 1) + " KB";
    if (bytes < 1024 * 1024 * 1024) return QString::number(bytes / (1024.0 * 1024.0), 'f', 1) + " MB";
    return QString::number(bytes / (1024.0 * 1024.0 * 1024.0), 'f', 2) + " GB";
}

QStringList FileManager::getConflictingFiles(const QStringList& paths, const QString& destDir) {
    QStringList conflicts;
    fs::path dest(destDir.toStdString());
    for (const auto& pStr : paths) {
        fs::path p(pStr.toStdString());
        fs::path target = dest / p.filename();
        std::error_code ec;
        if (fs::exists(target, ec)) {
            conflicts.append(QString::fromStdString(p.filename().string()));
        }
    }
    return conflicts;
}

void FileManager::cancelCopy() {
    m_cancelRequested = true;
}

void FileManager::copyItems(const QStringList& paths, const QString& destDir, bool overwrite) {
    m_cancelRequested = false;

    // Запускаем процесс в фоновом потоке, не подвешивая UI
    QThread* workerThread = QThread::create([this, paths, destDir, overwrite]() {
        uintmax_t totalBytes = 0;
        std::vector<std::pair<fs::path, fs::path>> filePairs;
        fs::path targetBasePath(destDir.toStdString());

        // 1. Предварительный расчет общего веса для прогресс-бара
        for (const auto& pStr : paths) {
            if (m_cancelRequested) break;
            fs::path src(pStr.toStdString());
            std::error_code ec;
            if (!fs::exists(src, ec)) continue;

            if (fs::is_directory(src, ec)) {
                fs::path destFolder = targetBasePath / src.filename();
                fs::create_directories(destFolder, ec);
                for (const auto& entry : fs::recursive_directory_iterator(src, fs::directory_options::skip_permission_denied, ec)) {
                    if (m_cancelRequested) break;
                    auto rel = fs::relative(entry.path(), src, ec);
                    fs::path curDest = destFolder / rel;
                    if (entry.is_directory(ec)) {
                        fs::create_directories(curDest, ec);
                    } else if (entry.is_regular_file(ec)) {
                        uintmax_t sz = entry.file_size(ec);
                        totalBytes += sz;
                        filePairs.push_back({entry.path(), curDest});
                    }
                }
            } else {
                uintmax_t sz = fs::file_size(src, ec);
                totalBytes += sz;
                filePairs.push_back({src, targetBasePath / src.filename()});
            }
        }

        if (m_cancelRequested) {
            emit copyFinished(false, true);
            return;
        }

        // 2. Потоковое копирование кусками по 256 KB с замером времени и скорости
        uintmax_t copiedBytes = 0;
        QElapsedTimer timer;
        timer.start();
        qint64 lastUpdate = 0;

        bool allSuccess = true;
        char buffer[256 * 1024];

        for (const auto& pair : filePairs) {
            if (m_cancelRequested) {
                allSuccess = false;
                break;
            }

            fs::path src = pair.first;
            fs::path dst = pair.second;
            std::error_code ec;

            if (!overwrite && fs::exists(dst, ec)) {
                continue;
            }

            FILE* in = fopen(src.string().c_str(), "rb");
            if (!in) { allSuccess = false; continue; }

            FILE* out = fopen(dst.string().c_str(), "wb");
            if (!out) { fclose(in); allSuccess = false; continue; }

            QString currentFileName = QString::fromStdString(src.filename().string());

            while (!feof(in) && !m_cancelRequested) {
                size_t r = fread(buffer, 1, sizeof(buffer), in);
                if (r > 0) {
                    fwrite(buffer, 1, r, out);
                    copiedBytes += r;
                }

                qint64 elapsed = timer.elapsed();
                if (elapsed - lastUpdate > 80 || copiedBytes == totalBytes) { // Обновление каждые 80мс
                    lastUpdate = elapsed;
                    qreal progress = totalBytes > 0 ? (qreal)copiedBytes / totalBytes : 1.0;
                    
                    double speedBytesPerSec = elapsed > 0 ? (double)copiedBytes / (elapsed / 1000.0) : 0;
                    QString speedStr = formatSize((uintmax_t)speedBytesPerSec) + "/s";

                    QString etaStr = "Подсчет...";
                    if (speedBytesPerSec > 1024) {
                        uintmax_t remainingBytes = totalBytes > copiedBytes ? (totalBytes - copiedBytes) : 0;
                        int remSec = (int)(remainingBytes / speedBytesPerSec);
                        if (remSec < 60) etaStr = QString("%1 сек.").arg(remSec);
                        else etaStr = QString("%1 мин. %2 сек.").arg(remSec / 60).arg(remSec % 60);
                    }

                    emit copyProgress(progress, currentFileName, formatSize(copiedBytes), formatSize(totalBytes), speedStr, etaStr);
                }
            }

            fclose(in);
            fclose(out);
        }

        emit copyFinished(allSuccess && !m_cancelRequested, m_cancelRequested.load());
    });

    connect(workerThread, &QThread::finished, workerThread, &QObject::deleteLater);
    workerThread->start();
}

bool FileManager::moveItems(const QStringList& paths, const QString& destDir) {
    bool ok = true;
    for (const auto& path : paths) {
        try {
            fs::path srcPath(path.toStdString());
            fs::rename(srcPath, fs::path(destDir.toStdString()) / srcPath.filename());
        } catch (...) { ok = false; }
    }
    return ok;
}

bool FileManager::renameItems(const QVariantList& renamePairs) {
    bool allOk = true;
    for (const auto& itemVar : renamePairs) {
        QVariantMap map = itemVar.toMap();
        QString oldPath = map.value("oldPath").toString();
        QString newPath = map.value("newPath").toString();

        if (oldPath.isEmpty() || newPath.isEmpty() || oldPath == newPath) continue;

        try {
            fs::rename(fs::path(oldPath.toStdString()), fs::path(newPath.toStdString()));
        } catch (const std::exception& e) {
            qWarning() << "[Rename Error]:" << e.what() << oldPath << "->" << newPath;
            allOk = false;
        }
    }
    return allOk;
}

QVariantList FileManager::searchFiles(const QString& startPath, const QString& nameQuery, const QString& textQuery) {
    QVariantList result;
    fs::path root(startPath.toStdString());

    std::error_code ec;
    if (!fs::exists(root, ec) || !fs::is_directory(root, ec)) return result;

    QString nameQLower = nameQuery.trimmed().toLower();
    QString textQ = textQuery.trimmed();
    bool checkText = !textQ.isEmpty();

    auto opts = fs::directory_options::skip_permission_denied | fs::directory_options::follow_directory_symlink;
    fs::recursive_directory_iterator it(root, opts, ec);
    fs::recursive_directory_iterator end;

    while (it != end) {
        if (ec) {
            ec.clear();
            it.increment(ec);
            continue;
        }

        try {
            const auto& entry = *it;
            std::string filenameStr = entry.path().filename().string();
            QString qFilename = QString::fromStdString(filenameStr);

            bool isDirectory = false;
            std::error_code statusEc;
            if (entry.is_directory(statusEc)) {
                isDirectory = true;
            }

            bool nameMatches = true;
            if (!nameQLower.isEmpty()) {
                nameMatches = qFilename.toLower().contains(nameQLower);
            }

            bool textMatches = true;
            if (checkText) {
                if (isDirectory) {
                    textMatches = false;
                } else {
                    textMatches = false;
                    QFile file(QString::fromStdString(entry.path().string()));
                    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                        QByteArray content = file.read(512 * 1024);
                        if (QString::fromUtf8(content).contains(textQ, Qt::CaseInsensitive)) {
                            textMatches = true;
                        }
                    }
                }
            }

            if (nameMatches && textMatches) {
                QVariantMap item;
                item["name"] = qFilename;
                item["path"] = QString::fromStdString(entry.path().string());
                item["isDir"] = isDirectory;

                uintmax_t size = 0;
                if (!isDirectory) {
                    std::error_code sizeEc;
                    size = entry.file_size(sizeEc);
                }
                item["sizeBytes"] = static_cast<qulonglong>(size);

                if (isDirectory) {
                    item["size"] = "<DIR>";
                } else {
                    if (size < 1024) item["size"] = QString::number(size) + " B";
                    else if (size < 1024 * 1024) item["size"] = QString::number(size / 1024.0, 'f', 1) + " KB";
                    else item["size"] = QString::number(size / (1024.0 * 1024.0), 'f', 1) + " MB";
                }

                try {
                    auto ftime = entry.last_write_time();
                    auto sctp = std::chrono::time_point_cast<std::chrono::system_clock::duration>(
                        ftime - fs::file_time_type::clock::now() + std::chrono::system_clock::now()
                    );
                    int64_t mtime = std::chrono::duration_cast<std::chrono::seconds>(sctp.time_since_epoch()).count();
                    QDateTime dt = QDateTime::fromSecsSinceEpoch(mtime);
                    item["modified"] = dt.toString("dd.MM.yyyy hh:mm");
                } catch (...) {
                    item["modified"] = "";
                }

                result.append(item);
                if (result.size() >= 500) break;
            }
        } catch (...) {}

        it.increment(ec);
    }

    return result;
}

QString FileManager::readFilePreview(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return "Не удалось открыть файл для чтения.";
    return QString::fromUtf8(file.read(128 * 1024));
}

void FileManager::packArchive(const QStringList& paths, const QString& targetArchivePath, const QString& workingDir) {
    if (paths.isEmpty() || targetArchivePath.trimmed().isEmpty()) return;

    QStringList relativeNames;
    for (const auto& p : paths) relativeNames << QFileInfo(p).fileName();

    QProcess* proc = new QProcess(this);
    proc->setWorkingDirectory(workingDir);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, proc, targetArchivePath](int exitCode, QProcess::ExitStatus) {
        if (exitCode != 0) {
            qWarning() << "[Archive Error]:" << targetArchivePath << proc->readAllStandardError();
        } else {
            qDebug() << "[Archive OK]:" << targetArchivePath;
        }
        emit archiveOperationFinished();
        proc->deleteLater();
    });

    if (targetArchivePath.endsWith(".zip", Qt::CaseInsensitive)) {
        QStringList args;
        args << "-r" << targetArchivePath << relativeNames;
        proc->start("zip", args);
    } else {
        QStringList args;
        args << "-caf" << targetArchivePath << relativeNames;
        proc->start("tar", args);
    }
}

void FileManager::unpackArchive(const QString& archivePath, const QString& destDir) {
    if (archivePath.trimmed().isEmpty() || destDir.trimmed().isEmpty()) return;

    QString lower = archivePath.toLower();
    QProcess* proc = new QProcess(this);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, proc, archivePath](int exitCode, QProcess::ExitStatus) {
        if (exitCode != 0) {
            qWarning() << "[Archive Error]:" << archivePath << proc->readAllStandardError();
        } else {
            qDebug() << "[Archive OK]: распакован в" << archivePath;
        }
        emit archiveOperationFinished();
        proc->deleteLater();
    });

    if (lower.endsWith(".zip")) {
        proc->start("unzip", {"-o", archivePath, "-d", destDir});
    } else if (lower.endsWith(".7z")) {
        proc->start("7z", {"x", "-y", archivePath, QString("-o%1").arg(destDir)});
    } else {
        proc->start("tar", {"-xaf", archivePath, "-C", destDir});
    }
}

bool FileManager::isArchiveFile(const QString& filename) {
    QString lower = filename.toLower();
    return lower.endsWith(".zip") || lower.endsWith(".tar") ||
           lower.endsWith(".tar.gz") || lower.endsWith(".tgz") ||
           lower.endsWith(".tar.bz2") || lower.endsWith(".tar.xz") ||
           lower.endsWith(".7z");
}

void FileManager::mountSsh(const QString& host, int port, const QString& user, const QString& password, const QString& remotePath) {
    QString safeHost = host.trimmed();
    QString safeUser = user.trimmed();
    int safePort = port > 0 ? port : 22;
    QString rPath = remotePath.trimmed().isEmpty() ? "/" : remotePath.trimmed();

    QString mountDirName = QString("%1_%2_%3").arg(safeUser.isEmpty() ? "remote" : safeUser, safeHost, QString::number(safePort));
    QString baseMountPath = QDir::homePath() + "/.cache/nightjar/mounts/" + mountDirName;

    QDir().mkpath(baseMountPath);

    QString cmd;
    if (password.trimmed().isEmpty()) {
        cmd = QString("sshfs -p %1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %2@%3:%4 \"%5\"")
                  .arg(QString::number(safePort), safeUser, safeHost, rPath, baseMountPath);
    } else {
        cmd = QString("sshpass -p '%1' sshfs -p %2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %3@%4:%5 \"%6\"")
                  .arg(password, QString::number(safePort), safeUser, safeHost, rPath, baseMountPath);
    }

    QProcess* proc = new QProcess(this);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, proc, baseMountPath](int exitCode, QProcess::ExitStatus) {
        if (exitCode == 0) {
            emit sshMountFinished(true, baseMountPath, "");
        } else {
            QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
            if (err.isEmpty()) err = QString::fromUtf8(proc->readAllStandardOutput()).trimmed();
            if (err.isEmpty()) err = "Не удалось подключиться к серверу по SFTP.";
            emit sshMountFinished(false, "", err);
        }
        proc->deleteLater();
    });

    proc->start("/bin/sh", {"-c", cmd});
}

bool FileManager::unmountPath(const QString& mountPoint) {
    if (mountPoint.isEmpty()) return false;
    QProcess proc;
    proc.start("fusermount3", {"-u", mountPoint});
    if (!proc.waitForFinished(3000) || proc.exitCode() != 0) {
        proc.start("fusermount", {"-u", mountPoint});
        proc.waitForFinished(3000);
    }
    return proc.exitCode() == 0;
}

bool FileManager::isMountedPath(const QString& path) {
    return path.contains("/.cache/nightjar/mounts/");
}