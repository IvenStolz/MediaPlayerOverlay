//
// Created by ivens on 12.09.2026.
//

#ifndef SPOTIFYREMOTE_MEDIAMANAGER_H
#define SPOTIFYREMOTE_MEDIAMANAGER_H
#include <QObject>
#include <QString>
#include <QList>
#include <QColor>
#include <QVariantList>
#include <QVariantMap>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.Control.h>
#include "LyricsFetcher.h"

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

    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void skipToTime(int ms);

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
    void parseLyricsString(const QString& lyricData);
    QString cleanTrackTitle(QString title);
    QString cleanArtistName(QString artist);

    QString m_title = "Waiting for Title...";
    QString m_artist = "- - -";
    QString m_coverURL = "";
    bool m_isPlaying = false;
    int m_songDurationMs = 0;
    int m_songPositionMs = 0;
    QList<QColor> m_accentColors = { QColor("#e3dc91"), QColor("#1f4026") };
    QVariantList m_parsedLyrics;
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