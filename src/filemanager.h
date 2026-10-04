#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariant>

class FileManager : public QObject {
    Q_OBJECT
public:
    explicit FileManager(QObject* parent = nullptr);

    Q_INVOKABLE QString homePath() const;
    Q_INVOKABLE void copyToClipboard(const QStringList& texts);
    Q_INVOKABLE QVariantList readDir(const QString& pathStr, const QString& sortBy = "name", bool sortAsc = true, bool showHidden = false);
    Q_INVOKABLE QString getFreeDiskSpace(const QString& pathStr);
    Q_INVOKABLE QString calculateDirSize(const QString& pathStr);
    
    Q_INVOKABLE void openFile(const QString& path);
    Q_INVOKABLE void editFile(const QString& path, const QString& customEditor = "");
    Q_INVOKABLE void runCommand(const QString& workingDir, const QString& command);
    Q_INVOKABLE bool createDirectory(const QString& basePath, const QString& dirName);
    Q_INVOKABLE bool deleteItems(const QStringList& paths);
    Q_INVOKABLE bool copyItems(const QStringList& paths, const QString& destDir);
    Q_INVOKABLE bool moveItems(const QStringList& paths, const QString& destDir);
    Q_INVOKABLE bool renameItems(const QVariantList& renamePairs);
    Q_INVOKABLE QVariantList searchFiles(const QString& startPath, const QString& nameQuery, const QString& textQuery);
    Q_INVOKABLE QString readFilePreview(const QString& path);

    Q_INVOKABLE void packArchive(const QStringList& paths, const QString& targetArchivePath, const QString& workingDir);
    Q_INVOKABLE void unpackArchive(const QString& archivePath, const QString& destDir);
    Q_INVOKABLE bool isArchiveFile(const QString& filename);

    // Настройки QSettings
    Q_INVOKABLE void saveSetting(const QString& key, const QVariant& value);
    Q_INVOKABLE QVariant getSetting(const QString& key, const QVariant& defaultValue = QVariant());

    // Системные шрифты
    Q_INVOKABLE QStringList getAvailableFonts();

    // SSH / SFTP монтирование
    Q_INVOKABLE void mountSsh(const QString& host, int port, const QString& user, const QString& password, const QString& remotePath = "/");
    Q_INVOKABLE bool unmountPath(const QString& mountPoint);
    Q_INVOKABLE bool isMountedPath(const QString& path);

signals:
    void commandFinished();
    void archiveOperationFinished();
    void sshMountFinished(bool success, const QString& mountPath, const QString& errorMessage);
};
