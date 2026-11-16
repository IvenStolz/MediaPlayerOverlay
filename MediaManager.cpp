#include "MediaManager.h"
#include "MediaManager.h"
#include <thread>
#include <QDebug>
#include <QTimer>
#include <QImage>
#include <QColor>
#include <QMap>
#include <vector>
#include <algorithm>
#include <QRegularExpression>
#include <winrt/Windows.Storage.Streams.h>
#include "LyricsUtils.h"

using namespace winrt::Windows::Media::Control;

MediaManager::MediaManager(QObject* parent) : QObject(parent)
{
    m_positionTimer.setInterval(100);
    connect(&m_positionTimer, &QTimer::timeout, this, [this]()
    {
        const int elapsedMs = m_playbackClock.isValid()
            ? static_cast<int>(m_playbackClock.elapsed())
            : 0;
        const int nextPosition = PlaybackTimeline::advancePosition(
            m_positionAnchorMs, m_songDurationMs, elapsedMs, m_isPlaying);
        if (nextPosition != m_songPositionMs) {
            m_songPositionMs = nextPosition;
            emit mediaChanged();
        }
    });
    m_positionTimer.start();

    m_seekTimeoutTimer.setSingleShot(true);
    connect(&m_seekTimeoutTimer, &QTimer::timeout, this, [this]()
    {
        m_pendingSeekFromMs = -1;
        m_pendingSeekToMs = -1;
        updateTimelineProperties();
    });

    connect(&m_lyricsFetcher, &LyricsFetcher::lyricsReady, this,
            [this](const QString& lookupKey, const QString& lyrics, bool synced) {
        if (lookupKey != m_lastLyricsLookup) {
            return;
        }
        m_lyricsLoading = false;
        m_lyricsError.clear();
        if (!lookupKey.isEmpty()) {
            if (!m_lyricsCache.contains(lookupKey)) {
                m_lyricsCacheOrder.append(lookupKey);
            } else {
                m_lyricsCacheOrder.removeAll(lookupKey);
                m_lyricsCacheOrder.append(lookupKey);
            }
            m_lyricsCache.insert(lookupKey, {lyrics, synced});
            while (m_lyricsCacheOrder.size() > MaxLyricsCacheEntries) {
                m_lyricsCache.remove(m_lyricsCacheOrder.takeFirst());
            }
        }
        parseLyricsString(lyrics, synced);
    });

    connect(&m_lyricsFetcher, &LyricsFetcher::lyricsFailed, this,
            [this](const QString& lookupKey, const QString& errorMsg) {
        if (lookupKey != m_lastLyricsLookup) {
            return;
        }
        qDebug() << "Lyrics Fehler:" << errorMsg;
        m_parsedLyrics.clear();
        m_lyricsSynced = false;
        m_lyricsLoading = false;
        m_lyricsError = errorMsg;
        emit lyricsChanged();
    });

    setupWinRT();
}

MediaManager::~MediaManager()
{
    if (m_manager)
    {
        m_manager.CurrentSessionChanged(m_sessionChangedToken);
    }
    if (m_currentSession)
    {
        m_currentSession.MediaPropertiesChanged(m_mediaPropertiesChangedToken);
        m_currentSession.PlaybackInfoChanged(m_playbackInfoChangedToken);
        m_currentSession.TimelinePropertiesChanged(m_timelinePropertiesChangedToken);
    }
}

void MediaManager::setupWinRT()
{
    try
    {
        auto asyncOp = GlobalSystemMediaTransportControlsSessionManager::RequestAsync();

        asyncOp.Completed([this](auto&& sender, winrt::Windows::Foundation::AsyncStatus status)
        {
            if (status == winrt::Windows::Foundation::AsyncStatus::Completed)
            {
                m_manager = sender.GetResults();

                if (m_manager)
                {
                    m_sessionChangedToken = m_manager.CurrentSessionChanged(
                        [this](auto const&, auto const&)
                        {
                            try { updateSession(); }
                            catch (...)
                            {
                            }
                        }
                    );
                    updateSession();
                }
            }
        });
    }
    catch (winrt::hresult_error const& ex)
    {
        qWarning() << "WinRT Fehler beim Setup:" << QString::fromStdWString(ex.message().c_str());
    }
}

void MediaManager::updateSession()
{
    if (m_currentSession)
    {
        m_currentSession.MediaPropertiesChanged(m_mediaPropertiesChangedToken);
        m_currentSession.PlaybackInfoChanged(m_playbackInfoChangedToken);
        m_currentSession.TimelinePropertiesChanged(m_timelinePropertiesChangedToken);
    }

    m_songPositionMs = 0;
    m_songDurationMs = 0;
    m_timelineStartMs = 0;
    m_positionAnchorMs = 0;
    m_playbackClock.invalidate();
    m_isPlaying = false;
    m_pendingSeekFromMs = -1;
    m_pendingSeekToMs = -1;
    m_seekTimeoutTimer.stop();
    m_currentSession = m_manager.GetCurrentSession();

    if (m_currentSession)
    {
        m_mediaPropertiesChangedToken = m_currentSession.MediaPropertiesChanged(
            [this](auto const&, auto const&)
            {
                updateMediaProperties();
            }
        );

        m_playbackInfoChangedToken = m_currentSession.PlaybackInfoChanged(
            [this](auto const&, auto const&)
            {
                updatePlaybackInfo();
            }
        );

        m_timelinePropertiesChangedToken = m_currentSession.TimelinePropertiesChanged(
            [this](auto const&, auto const&)
            {
                try { updateTimelineProperties(); }
                catch (...)
                {
                }
            }
        );

        updateMediaProperties();
        updatePlaybackInfo();
        updateTimelineProperties();
    } else {
        m_songPositionMs = 0;
        m_songDurationMs = 0;
        m_timelineStartMs = 0;
        m_isPlaying = false;
        emit mediaChanged();
    }
}

void MediaManager::updateMediaProperties()
{
    if (!m_currentSession) return;

    try
    {
        auto properties = m_currentSession.TryGetMediaPropertiesAsync().get();

        m_title = QString::fromStdWString(properties.Title().c_str());
        m_artist = QString::fromStdWString(properties.Artist().c_str());

        QString cleanTitle = LyricsUtils::cleanTrackTitle(m_title);
        const QString cleanArtist = LyricsUtils::cleanArtistName(m_artist);
        const QString artistPrefix = QRegularExpression::escape(cleanArtist);
        cleanTitle.remove(QRegularExpression(
            QString(R"(^\s*%1\s*[-|:]\s*)").arg(artistPrefix),
            QRegularExpression::CaseInsensitiveOption));
        const QString lookupKey = cleanTitle + QChar(0x1f) + cleanArtist;

        if (cleanTitle.isEmpty() || cleanArtist.isEmpty()) {
            m_lastLyricsLookup.clear();
            m_lyricsLookupTitle.clear();
            m_lyricsLookupArtist.clear();
            m_parsedLyrics.clear();
            m_lyricsSynced = false;
            m_lyricsLoading = false;
            m_lyricsError.clear();
            emit lyricsChanged();
            QMetaObject::invokeMethod(this, [this]()
            {
                m_lyricsFetcher.cancelPendingRequests();
            });
        } else if (lookupKey != m_lastLyricsLookup) {
            m_lastLyricsLookup = lookupKey;
            m_lyricsLookupTitle = cleanTitle;
            m_lyricsLookupArtist = cleanArtist;
            m_songPositionMs = 0;
            m_songDurationMs = 0;
            m_parsedLyrics.clear();
            m_lyricsSynced = false;
            m_lyricsError.clear();
            m_lyricsLoading = false;
            emit lyricsChanged();
            emit mediaChanged();
            requestLyrics(cleanTitle, cleanArtist, lookupKey);
        }

        auto thumbnail = properties.Thumbnail();

        if (thumbnail)
        {
            try
            {
                auto stream = thumbnail.OpenReadAsync().get();
                uint32_t size = static_cast<uint32_t>(stream.Size());

                winrt::Windows::Storage::Streams::DataReader reader(stream.GetInputStreamAt(0));
                reader.LoadAsync(size).get();

                QByteArray imageBytes;
                imageBytes.resize(size);

                winrt::array_view<uint8_t> view(reinterpret_cast<uint8_t*>(imageBytes.data()), size);
                reader.ReadBytes(view);

                m_coverURL = "data:image/jpeg;base64," + imageBytes.toBase64();

                m_accentColors = getAccentColorsFromImage(imageBytes);
            }
            catch (...)
            {
                m_coverURL = "";
            }
        }
        else
        {
            m_coverURL = "";
        }
    }
    catch (...)
    {
    }
    emit mediaChanged();
}

void MediaManager::updateTimelineProperties()
{
    if (!m_currentSession) return;

    try
    {
        auto timeline = m_currentSession.GetTimelineProperties();
        const qint64 startTicks = timeline.StartTime().count();
        const int startMs = PlaybackTimeline::millisecondsFromTicks(startTicks);
        const int durationMs = PlaybackTimeline::durationMilliseconds(
            startTicks, timeline.EndTime().count());
        const int positionMs = PlaybackTimeline::positionMilliseconds(
            startTicks, timeline.Position().count());

        m_timelineStartMs = startMs;
        if (durationMs > 0 || !m_isPlaying) {
            m_songDurationMs = qMax(0, durationMs);
        }
        if (m_pendingSeekToMs >= 0) {
            if (PlaybackTimeline::shouldIgnoreSeekUpdate(
                    m_pendingSeekFromMs, m_pendingSeekToMs, positionMs)) {
                emit mediaChanged();
                return;
            }
            m_songPositionMs = PlaybackTimeline::clampPosition(
                positionMs, m_songDurationMs);
            m_positionAnchorMs = m_songPositionMs;
            if (m_isPlaying) {
                m_playbackClock.restart();
            }
            m_pendingSeekFromMs = -1;
            m_pendingSeekToMs = -1;
            m_seekTimeoutTimer.stop();
            emit mediaChanged();
            return;
        }
        if (positionMs >= 0 && PlaybackTimeline::shouldRebasePosition(
                m_songPositionMs, positionMs, m_isPlaying)) {
            m_songPositionMs = PlaybackTimeline::clampPosition(
                positionMs, m_songDurationMs);
            m_positionAnchorMs = m_songPositionMs;
            if (m_isPlaying) {
                m_playbackClock.restart();
            }
        }

        emit mediaChanged();
    }
    catch (...)
    {
    }
}

void MediaManager::requestLyrics(const QString& title, const QString& artist,
                                 const QString& lookupKey)
{
    const auto cached = m_lyricsCache.constFind(lookupKey);
    if (cached != m_lyricsCache.cend()) {
        m_lyricsCacheOrder.removeAll(lookupKey);
        m_lyricsCacheOrder.append(lookupKey);
        m_lyricsLoading = false;
        m_lyricsError.clear();
        parseLyricsString(cached->text, cached->synced);
        QMetaObject::invokeMethod(this, [this]()
        {
            m_lyricsFetcher.cancelPendingRequests();
        });
        return;
    }

    m_lyricsLoading = true;
    m_lyricsError.clear();
    emit lyricsChanged();
    QMetaObject::invokeMethod(this, [this, title, artist, lookupKey]()
    {
        m_lyricsFetcher.fetchLyrics(title, artist, lookupKey);
    });
}

void MediaManager::retryLyrics()
{
    if (m_lastLyricsLookup.isEmpty() || m_lyricsLookupTitle.isEmpty()
        || m_lyricsLookupArtist.isEmpty() || m_lyricsLoading) {
        return;
    }
    m_lyricsLoading = true;
    m_lyricsError.clear();
    m_parsedLyrics.clear();
    m_lyricsSynced = false;
    emit lyricsChanged();
    const QString lookupKey = m_lastLyricsLookup;
    QMetaObject::invokeMethod(this, [this, lookupKey]()
    {
        m_lyricsFetcher.fetchLyrics(m_lyricsLookupTitle, m_lyricsLookupArtist, lookupKey);
    });
}

void MediaManager::updatePlaybackInfo()
{
    if (!m_currentSession) return;

    auto playbackInfo = m_currentSession.GetPlaybackInfo();
    const bool wasPlaying = m_isPlaying;
    m_isPlaying = (playbackInfo.PlaybackStatus() == GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing);
    if (m_isPlaying != wasPlaying) {
        if (m_isPlaying) {
            m_positionAnchorMs = m_songPositionMs;
            m_playbackClock.start();
        } else if (m_playbackClock.isValid()) {
            m_songPositionMs = PlaybackTimeline::advancePosition(
                m_positionAnchorMs, m_songDurationMs,
                static_cast<int>(m_playbackClock.elapsed()), true);
            m_positionAnchorMs = m_songPositionMs;
            m_playbackClock.invalidate();
        }
    }

    updateTimelineProperties();
    emit mediaChanged();
}

QList<QColor> MediaManager::getAccentColorsFromImage(const QByteArray& imageBytes)
{
    QList<QColor> fallback = {QColor("#e3dc91"), QColor("#1f4026")};
    QImage image;
    if (!image.loadFromData(imageBytes))
    {
        return fallback;
    }

    QImage downscaledImg = image.scaled(48, 48, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);

    QMap<QRgb, int> colorCounts;

    for (int y = 0; y < downscaledImg.height(); ++y)
    {
        for (int x = 0; x < downscaledImg.width(); ++x)
        {
            QColor color = downscaledImg.pixelColor(x, y);

            // Sort greys out
            if (color.saturation() < 30 || color.lightness() < 60 || color.lightness() > 235)
            {
                continue;
            }

            //quantize
            int r = (color.red() / 16) * 16;
            int g = (color.green() / 16) * 16;
            int b = (color.blue() / 16) * 16;

            QRgb roundedColor = qRgb(r, g, b);
            colorCounts[roundedColor]++;
        }
    }
    if (colorCounts.isEmpty()) return fallback;

    std::vector<std::pair<QRgb, int>> sortedColors(
        colorCounts.keyValueBegin(),
        colorCounts.keyValueEnd()
    );
    std::sort(sortedColors.begin(), sortedColors.end(), [](const auto& a, const auto& b)
    {
        return a.second > b.second;
    });

    QColor primaryColor(sortedColors[0].first);
    QColor secondaryColor = primaryColor.lighter(170);

    for (size_t i = 1; i < sortedColors.size(); ++i)
    {
        QColor candidate(sortedColors[i].first);
        if (qAbs(primaryColor.hue() - candidate.hue()) > 30)
        {
            secondaryColor = candidate;
            break;
        }
    }
    if (secondaryColor.lightness() > primaryColor.lightness())
    {
        return {secondaryColor, primaryColor};
    }
    return {primaryColor, secondaryColor};
}

void MediaManager::parseLyricsString(const QString& lyricData, bool synced)
{
    const LyricsUtils::ParsedLyrics parsed = LyricsUtils::parse(lyricData, synced);
    m_parsedLyrics = parsed.lines;
    m_lyricsSynced = parsed.synced;
    emit lyricsChanged();
}

void MediaManager::togglePlayPause()
{
    if (m_currentSession)
    {
        m_currentSession.TryTogglePlayPauseAsync();
    }
}

void MediaManager::next()
{
    if (m_currentSession)
    {
        m_currentSession.TrySkipNextAsync();
    }
}

void MediaManager::previous()
{
    if (m_currentSession)
    {
        m_currentSession.TrySkipPreviousAsync();
    }
}

void MediaManager::skipToTime(int ms)
{
    if (m_currentSession) {
        const int clampedMs = PlaybackTimeline::clampPosition(ms, m_songDurationMs);
        m_pendingSeekFromMs = m_songPositionMs;
        m_pendingSeekToMs = clampedMs;
        m_songPositionMs = clampedMs;
        m_positionAnchorMs = clampedMs;
        if (m_isPlaying) {
            m_playbackClock.restart();
        }
        m_seekTimeoutTimer.start(2500);
        emit mediaChanged();

        int64_t ticks = static_cast<int64_t>(clampedMs + m_timelineStartMs) * 10000;

        m_currentSession.TryChangePlaybackPositionAsync(ticks);
    }
}
