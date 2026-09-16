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

using namespace winrt::Windows::Media::Control;

MediaManager::MediaManager(QObject* parent) : QObject(parent)
{
    QTimer* timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, [this]()
    {
        if (m_isPlaying && m_songPositionMs < m_songDurationMs)
        {
            m_songPositionMs += 1000;
            emit mediaChanged();
        }
    });
    timer->start(1000);

    connect(&m_lyricsFetcher, &LyricsFetcher::lyricsReady, this, &MediaManager::parseLyricsString);

    connect(&m_lyricsFetcher, &LyricsFetcher::lyricsFailed, this, [this](const QString& errorMsg) {
        qDebug() << "Lyrics Fehler:" << errorMsg;
        m_parsedLyrics.clear();
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
    }

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

        QString cleanTitle = cleanTrackTitle(m_title);

        QMetaObject::invokeMethod(this, [this, title = cleanTitle, artist = m_artist]()
        {
            m_lyricsFetcher.fetchLyrics(title, artist);
        });

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
        m_songDurationMs = timeline.EndTime().count() / 10000;
        m_songPositionMs = timeline.Position().count() / 10000;

        emit mediaChanged();
    }
    catch (...)
    {
    }
}

void MediaManager::updatePlaybackInfo()
{
    if (!m_currentSession) return;

    auto playbackInfo = m_currentSession.GetPlaybackInfo();
    m_isPlaying = (playbackInfo.PlaybackStatus() == GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing);

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

void MediaManager::parseLyricsString(const QString& lrcData)
{
    m_parsedLyrics.clear();
    // For Text: [mm:ss.xx]
    QRegularExpression regex(R"(\[(\d{2}):(\d{2})\.(\d{2,3})\](.*))");
    QStringList lines = lrcData.split('\n', Qt::SkipEmptyParts);
    for (const QString& line : lines)
    {
        QRegularExpressionMatch match = regex.match(line);
        if (match.hasMatch())
        {
            int minutes = match.captured(1).toInt();
            int seconds = match.captured(2).toInt();
            int milliseconds = match.captured(3).toInt();
            if (match.captured(3).length() == 2) {
                milliseconds *= 10;
            }
            int totalMs = (minutes * 60000) + (seconds * 1000) + (milliseconds);
            QString text = match.captured(4).trimmed();

            QVariantMap lyricLine;
            lyricLine["timeMs"] = totalMs;
            lyricLine["text"] = text;

            m_parsedLyrics.append(lyricLine);
        }
    }
    emit lyricsChanged();
}

QString MediaManager::cleanTrackTitle(QString title) {
    QRegularExpression fluffRegex(R"((?i)[\[\(](official|music|lyric|video|audio|visualizer|live|studio|version|animated|amv|hd|4k).*?[\]\)])");
    title.replace(fluffRegex, "");

    QRegularExpression featRegex(R"((?i)(ft\.|feat\.|featuring).*$)");
    title.replace(featRegex, "");

    return title.trimmed();
}

QString MediaManager::cleanArtistName(QString artist)
{
    QRegularExpression fluffRegex(R"((?i)(official|vevo|videos))");
    artist.replace(fluffRegex, "");

    return artist.trimmed();
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
        int64_t ticks = static_cast<int64_t>(ms) * 10000;

        m_currentSession.TryChangePlaybackPositionAsync(ticks);
    }
}
