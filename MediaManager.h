//
// Created by ivens on 12.09.2026.
//

#ifndef SPOTIFYREMOTE_MEDIAMANAGER_H
#define SPOTIFYREMOTE_MEDIAMANAGER_H
#include <QObject>
#include <QString>
#include <QList>
#include <QColor>
#include <QHash>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>
#include <QElapsedTimer>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.Control.h>
#include "LyricsFetcher.h"
#include "PlaybackTimeline.h"

class MediaManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString title READ title NOTIFY mediaChanged)
    Q_PROPERTY(QString artist READ artist NOTIFY mediaChanged)
    Q_PROPERTY(QString coverURL READ coverURL NOTIFY mediaChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY mediaChanged)
    Q_PROPERTY(int songDurationMs READ duration NOTIFY mediaChanged)
    Q_PROPERTY(int songPositionMs READ position NOTIFY mediaChanged)
    Q_PROPERTY(QList<QColor> accentColors READ accentColors NOTIFY mediaChanged)
    Q_PROPERTY(QVariantList parsedLyrics READ parsedLyrics NOTIFY lyricsChanged)
    Q_PROPERTY(bool lyricsSynced READ lyricsSynced NOTIFY lyricsChanged)
    Q_PROPERTY(bool lyricsLoading READ lyricsLoading NOTIFY lyricsChanged)
    Q_PROPERTY(QString lyricsError READ lyricsError NOTIFY lyricsChanged)

    public:
    explicit MediaManager(QObject *parent = nullptr);
    ~MediaManager();

    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    QString coverURL() const { return m_coverURL; }
    bool isPlaying() const { return m_isPlaying; }
    int duration() const { return m_songDurationMs; }
    int position() const { return m_songPositionMs; }
    QList<QColor> accentColors() const { return m_accentColors; }
    QVariantList parsedLyrics() const { return m_parsedLyrics; }
    bool lyricsSynced() const { return m_lyricsSynced; }
    bool lyricsLoading() const { return m_lyricsLoading; }
    QString lyricsError() const { return m_lyricsError; }

    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void skipToTime(int ms);
    Q_INVOKABLE void retryLyrics();

    signals:
    void mediaChanged();
    void lyricsChanged();

private:
    void setupWinRT();
    void updateSession();
    void updateMediaProperties();
    void updatePlaybackInfo();
    void updateTimelineProperties();
    QList<QColor> getAccentColorsFromImage(const QByteArray& imageBytes);
    void parseLyricsString(const QString& lyricData, bool synced);
    void requestLyrics(const QString& title, const QString& artist, const QString& lookupKey);

    struct CachedLyrics {
        QString text;
        bool synced = false;
    };

    static constexpr int MaxLyricsCacheEntries = 50;

    QString m_title = "Waiting for Title...";
    QString m_artist = "- - -";
    QString m_coverURL = "";
    bool m_isPlaying = false;
    int m_songDurationMs = 0;
    int m_songPositionMs = 0;
    QList<QColor> m_accentColors = { QColor("#e3dc91"), QColor("#1f4026") };
    QVariantList m_parsedLyrics;
    bool m_lyricsSynced = false;
    bool m_lyricsLoading = false;
    QString m_lyricsError;
    QString m_lastLyricsLookup;
    QString m_lyricsLookupTitle;
    QString m_lyricsLookupArtist;
    QHash<QString, CachedLyrics> m_lyricsCache;
    QStringList m_lyricsCacheOrder;
    int m_timelineStartMs = 0;
    int m_pendingSeekFromMs = -1;
    int m_pendingSeekToMs = -1;
    int m_positionAnchorMs = 0;
    QElapsedTimer m_playbackClock;
    QTimer m_positionTimer;
    QTimer m_seekTimeoutTimer;
    LyricsFetcher m_lyricsFetcher;

    winrt::Windows::Media::Control::GlobalSystemMediaTransportControlsSessionManager m_manager{ nullptr };
    winrt::Windows::Media::Control::GlobalSystemMediaTransportControlsSession m_currentSession{ nullptr };

    // Tokens
    winrt::event_token m_sessionChangedToken;
    winrt::event_token m_mediaPropertiesChangedToken;
    winrt::event_token m_playbackInfoChangedToken;
    winrt::event_token m_timelinePropertiesChangedToken;
};

#endif //SPOTIFYREMOTE_MEDIAMANAGER_H