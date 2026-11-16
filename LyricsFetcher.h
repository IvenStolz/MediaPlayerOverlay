#pragma once

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QUrlQuery>
#include "LyricsUtils.h"

class LyricsFetcher : public QObject {
    Q_OBJECT

public:
    explicit LyricsFetcher(QObject *parent = nullptr)
        : QObject(parent), m_netManager(new QNetworkAccessManager(this)) {}

    void fetchLyrics(const QString& trackName, const QString& artistName,
                     const QString& lookupKey) {
        const quint64 requestId = ++m_latestRequestId;
        QUrl url("https://lrclib.net/api/search");
        QUrlQuery query;
        query.addQueryItem("track_name", trackName);
        query.addQueryItem("artist_name", artistName);
        url.setQuery(query);

        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::UserAgentHeader,
                          "MediaPlayerOverlay/1.0 (https://github.com/IvenStolz/MediaPlayerOverlay)");

        QNetworkReply *reply = m_netManager->get(request);
        connect(reply, &QNetworkReply::finished, this,
                [this, reply, trackName, artistName, lookupKey, requestId]() {
            handleNetworkReply(reply, trackName, artistName, lookupKey, requestId);
        });
    }

    void cancelPendingRequests() {
        ++m_latestRequestId;
    }

signals:
    void lyricsReady(const QString& lookupKey, const QString& lyrics, bool synced);
    void lyricsFailed(const QString& lookupKey, const QString& errorMsg);

private:
    QNetworkAccessManager *m_netManager;
    quint64 m_latestRequestId = 0;

    void handleNetworkReply(QNetworkReply *reply, const QString& trackName,
                            const QString& artistName, const QString& lookupKey,
                            quint64 requestId) {
        const auto networkError = reply->error();
        const QString networkErrorText = reply->errorString();
        const QByteArray responseData = reply->readAll();
        reply->deleteLater();

        if (requestId != m_latestRequestId) {
            return;
        }
        if (networkError != QNetworkReply::NoError) {
            emit lyricsFailed(lookupKey, "Lyrics-Suche fehlgeschlagen: " + networkErrorText);
            return;
        }

        QJsonParseError parseError;
        const QJsonDocument document = QJsonDocument::fromJson(responseData, &parseError);
        if (parseError.error != QJsonParseError::NoError || !document.isArray()) {
            emit lyricsFailed(lookupKey, "Ungültige Antwort von LRCLIB.");
            return;
        }

        const QJsonArray results = document.array();
        QJsonObject bestMatch;
        double bestScore = 0.0;
        for (const QJsonValue& value : results) {
            if (!value.isObject()) {
                continue;
            }
            const QJsonObject candidate = value.toObject();
            if (candidate.value("syncedLyrics").toString().trimmed().isEmpty()
                && candidate.value("plainLyrics").toString().trimmed().isEmpty()) {
                continue;
            }
            const double titleScore = LyricsUtils::similarity(
                trackName, candidate.value("trackName").toString());
            const double artistScore = LyricsUtils::similarity(
                artistName, candidate.value("artistName").toString());
            const double score = titleScore * 0.7 + artistScore * 0.3;
            if (titleScore > 0.0 && artistScore > 0.0 && score > bestScore) {
                bestScore = score;
                bestMatch = candidate;
            }
        }

        if (bestMatch.isEmpty()) {
            emit lyricsFailed(lookupKey, "Keine passenden Lyrics gefunden.");
            return;
        }

        const QString syncedLyrics = bestMatch.value("syncedLyrics").toString().trimmed();
        const QRegularExpression timestampRegex(R"(\[\d+:\d{2}(?:\.\d{1,3})?\]\s*\S)");
        if (timestampRegex.match(syncedLyrics).hasMatch()) {
            emit lyricsReady(lookupKey, syncedLyrics, true);
            return;
        }

        const QString plainLyrics = bestMatch.value("plainLyrics").toString().trimmed();
        if (!plainLyrics.isEmpty()) {
            emit lyricsReady(lookupKey, plainLyrics, false);
            return;
        }

        if (!syncedLyrics.isEmpty()) {
            emit lyricsReady(lookupKey, syncedLyrics, false);
            return;
        }

        emit lyricsFailed(lookupKey, "Der gefundene Eintrag enthält keine Lyrics.");
    }
};
