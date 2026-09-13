#pragma once

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

class LyricsFetcher : public QObject {
    Q_OBJECT

public:
    explicit LyricsFetcher(QObject *parent = nullptr) : QObject(parent) {
        // Der Postbote wird einmalig erstellt
        m_netManager = new QNetworkAccessManager(this);
    }

    void fetchLyrics(const QString& trackName, const QString& artistName) {
        // 1. URL und Parameter zusammenbauen
        QUrl url("https://lrclib.net/api/get");
        QUrlQuery query;
        query.addQueryItem("track_name", trackName);
        query.addQueryItem("artist_name", artistName);
        url.setQuery(query);

        // 2. Den Request (Briefumschlag) erstellen
        QNetworkRequest request(url);
        
        // WICHTIG FÜR LRCLIB: Einen User-Agent setzen!
        // Die API blockiert generische Anfragen oft. Nenne einfach deinen App-Namen.
        request.setHeader(QNetworkRequest::UserAgentHeader, "SpotifyRemoteApp/1.0");

        // 3. Anfrage abschicken (GET)
        QNetworkReply *reply = m_netManager->get(request);

        // 4. Warten, bis die Antwort da ist (Asynchron via Signal/Slot)
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            handleNetworkReply(reply);
        });
    }

signals:
    // Signal, um das QML-UI später über die neuen Lyrics zu informieren
    void lyricsReady(const QString& syncedLyrics);
    void lyricsFailed(const QString& errorMsg);

private:
    QNetworkAccessManager *m_netManager;

    void handleNetworkReply(QNetworkReply *reply) {
        // Nach getaner Arbeit muss das Reply-Objekt gelöscht werden (Speicherleck verhindern!)
        reply->deleteLater();

        // Prüfen, ob das Internet weg ist oder der Server einen Fehler meldet (z.B. 404 Not Found)
        if (reply->error() != QNetworkReply::NoError) {
            emit lyricsFailed("Netzwerkfehler oder Song nicht gefunden: " + reply->errorString());
            return;
        }

        // JSON-Daten auslesen
        QByteArray responseData = reply->readAll();
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);

        if (!jsonDoc.isObject()) {
            emit lyricsFailed("Ungültiges JSON-Format erhalten.");
            return;
        }

        QJsonObject jsonObj = jsonDoc.object();

        // LRCLIB gibt uns plainLyrics (ohne Zeiten) und syncedLyrics (mit Zeiten)
        QString syncedLyrics = jsonObj.value("syncedLyrics").toString();
        
        if (syncedLyrics.isEmpty()) {
            emit lyricsFailed("Keine synchronisierten Lyrics für diesen Song gefunden.");
        } else {
            // Erfolg! Die Lyrics können ans UI gesendet werden.
            emit lyricsReady(syncedLyrics);
        }
    }
};