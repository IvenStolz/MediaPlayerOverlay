#pragma once

#include <QRegularExpression>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <algorithm>

namespace LyricsUtils {

inline QString normalized(const QString& value)
{
    QString result = value.normalized(QString::NormalizationForm_D).toCaseFolded();
    result.remove(QRegularExpression(R"(\p{M})"));
    result.remove(QRegularExpression(
        R"(\s*[\[(][^\])]*(?:official|vevo|music\s+video|lyrics?(?:\s+video)?|audio|visualizer|full\s+album|4k|hd)[^\])]*[\])])"));
    result.remove(QRegularExpression(
        R"((?:\s*[-|:]\s*|\s+)(?:official(?:\s+(?:music\s+)?video|\s+audio)?|music\s+video|lyrics?(?:\s+video)?|audio|visualizer|vevo|full\s+album|4k|hd)\s*$)"));
    result.remove(QRegularExpression(
        R"(\s*[\[(]?\s*(?:ft|feat|featuring)\.?\b.*$)"));
    result.remove(QRegularExpression(R"([^\p{L}\p{N}])"));
    return result;
}

inline double similarity(const QString& expected, const QString& actual)
{
    const QString left = normalized(expected);
    const QString right = normalized(actual);
    if (left.isEmpty() || right.isEmpty()) {
        return 0.0;
    }
    if (left == right) {
        return 1.0;
    }
    const int shorterLength = qMin(left.size(), right.size());
    const int longerLength = qMax(left.size(), right.size());
    if ((left.contains(right) || right.contains(left))
        && shorterLength * 4 >= longerLength * 3) {
        return 0.75;
    }
    return 0.0;
}

inline QString cleanTrackTitle(QString title)
{
    title.replace(QRegularExpression(
        R"((?i)\s*[\[(][^\])]*(?:official|vevo|music\s+video|lyrics?(?:\s+video)?|audio|visualizer|full\s+album|4k|hd)[^\])]*[\])])"), "");
    title.replace(QRegularExpression(
        R"((?i)(?:\s*[-|:]\s*|\s+)(?:official(?:\s+(?:music\s+)?video|\s+audio)?|music\s+video|lyrics?(?:\s+video)?|audio|visualizer|vevo|full\s+album|4k|hd)\s*$)"), "");
    title.replace(QRegularExpression(
        R"((?i)\s*[\[(]?\s*(?:ft|feat|featuring)\.?\b.*$)"), "");
    title = title.simplified();
    title.remove(QRegularExpression(R"(^[-|:\s]+|[-|:\s]+$)"));
    return title;
}

inline QString cleanArtistName(QString artist)
{
    artist.replace(QRegularExpression(
        R"((?i)\s*[\[(](?:official|vevo|videos?|topic|music\s+channel)[^\])]*[\])]\s*$)"), "");
    artist.replace(QRegularExpression(
        R"((?i)(?:\s*[-|:]\s*|\s+)(?:official(?:\s+(?:artist|music|video))?|videos?|topic|music\s+channel)\s*$)"), "");
    artist.replace(QRegularExpression(R"((?i)(?:\s*[-|:]\s*|\s+)vevo\s*$)"), "");
    artist = artist.simplified();
    artist.remove(QRegularExpression(R"(^[-|:\s]+|[-|:\s]+$)"));
    return artist;
}

struct ParsedLyrics {
    QVariantList lines;
    bool synced = false;
};

inline ParsedLyrics parse(const QString& lyricData, bool synced)
{
    ParsedLyrics result;
    const QRegularExpression timestampRegex(R"(\[(\d+):(\d{2})(?:\.(\d{1,3}))?\])");
    const QRegularExpression timestampRemovalRegex(R"(\[\d+:\d{2}(?:\.\d+)?\])");
    const QStringList lines = lyricData.split('\n', Qt::SkipEmptyParts);
    bool foundTimestamp = false;

    for (const QString& rawLine : lines) {
        const QString line = rawLine.trimmed();
        if (line.isEmpty()) {
            continue;
        }

        if (synced) {
            QRegularExpressionMatchIterator matches = timestampRegex.globalMatch(line);
            QList<int> timestamps;
            while (matches.hasNext()) {
                const QRegularExpressionMatch match = matches.next();
                foundTimestamp = true;
                int fractionMs = 0;
                if (!match.captured(3).isEmpty()) {
                    fractionMs = match.captured(3).toInt();
                    if (match.captured(3).length() == 1) {
                        fractionMs *= 100;
                    } else if (match.captured(3).length() == 2) {
                        fractionMs *= 10;
                    }
                }
                timestamps.append(match.captured(1).toInt() * 60000
                                  + match.captured(2).toInt() * 1000
                                  + fractionMs);
            }

            if (!timestamps.isEmpty()) {
                QString text = line;
                text.remove(timestampRegex);
                text = text.trimmed();
                if (!text.isEmpty()) {
                    for (const int timestamp : timestamps) {
                        QVariantMap lyricLine;
                        lyricLine["timeMs"] = timestamp;
                        lyricLine["text"] = text;
                        result.lines.append(lyricLine);
                    }
                }
            }
            continue;
        }

        QString text = line;
        text.remove(timestampRemovalRegex);
        text = text.trimmed();
        if (!text.isEmpty()) {
            QVariantMap lyricLine;
            lyricLine["timeMs"] = -1;
            lyricLine["text"] = text;
            result.lines.append(lyricLine);
        }
    }

    result.synced = synced && foundTimestamp;
    if (!result.synced && synced) {
        result.lines.clear();
        for (QString line : lines) {
            line = line.trimmed();
            line.remove(timestampRemovalRegex);
            line = line.trimmed();
            if (!line.isEmpty()) {
                QVariantMap lyricLine;
                lyricLine["timeMs"] = -1;
                lyricLine["text"] = line;
                result.lines.append(lyricLine);
            }
        }
    }

    if (result.synced) {
        std::stable_sort(result.lines.begin(), result.lines.end(),
                         [](const QVariant& left, const QVariant& right) {
            return left.toMap().value("timeMs").toInt()
                < right.toMap().value("timeMs").toInt();
        });
    }
    return result;
}

}
