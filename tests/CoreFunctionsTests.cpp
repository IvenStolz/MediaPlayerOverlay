#include <QtTest>

#include "LyricsUtils.h"
#include "PlaybackTimeline.h"

class CoreFunctionsTests : public QObject
{
    Q_OBJECT

private slots:
    void timelineConvertsTicksRelativeToStart()
    {
        constexpr qint64 ticksPerMs = 10000;
        const qint64 start = 2500 * ticksPerMs;
        QCOMPARE(PlaybackTimeline::millisecondsFromTicks(start), 2500);
        QCOMPARE(PlaybackTimeline::durationMilliseconds(start, 102500 * ticksPerMs), 100000);
        QCOMPARE(PlaybackTimeline::positionMilliseconds(start, 12750 * ticksPerMs), 10250);
    }

    void timelineClampsSeekPosition()
    {
        QCOMPARE(PlaybackTimeline::clampPosition(-50, 90000), 0);
        QCOMPARE(PlaybackTimeline::clampPosition(95000, 90000), 90000);
        QCOMPARE(PlaybackTimeline::clampPosition(12000, 0), 12000);
    }

    void playbackPositionAdvancesEverySecondOnlyWhilePlaying()
    {
        QCOMPARE(PlaybackTimeline::advancePosition(12000, 90000, 1000, true), 13000);
        QCOMPARE(PlaybackTimeline::advancePosition(12000, 90000, 1000, false), 12000);
        QCOMPARE(PlaybackTimeline::advancePosition(89500, 90000, 1000, true), 90000);
    }

    void timelineDoesNotRebaseOnSmallJitter()
    {
        QVERIFY(!PlaybackTimeline::shouldRebasePosition(20000, 19500, true));
        QVERIFY(!PlaybackTimeline::shouldRebasePosition(20000, 21000, true));
        QVERIFY(PlaybackTimeline::shouldRebasePosition(20000, 18000, true));
        QVERIFY(PlaybackTimeline::shouldRebasePosition(20000, 19500, false));
    }

    void seekGuardRejectsStaleTimelineInBothDirections()
    {
        QVERIFY(PlaybackTimeline::shouldIgnoreSeekUpdate(10000, 70000, 10000));
        QVERIFY(!PlaybackTimeline::shouldIgnoreSeekUpdate(10000, 70000, 69000));
        QVERIFY(PlaybackTimeline::shouldIgnoreSeekUpdate(70000, 10000, 70000));
        QVERIFY(!PlaybackTimeline::shouldIgnoreSeekUpdate(70000, 10000, 11000));
    }

    void seekGuardAllowsSmallSeekDifferences()
    {
        QVERIFY(!PlaybackTimeline::shouldIgnoreSeekUpdate(10000, 11000, 10000));
        QVERIFY(!PlaybackTimeline::shouldIgnoreSeekUpdate(10000, 9000, 10000));
    }

    void titleAndArtistCleanupRemovesVideoMetadata()
    {
        QCOMPARE(LyricsUtils::cleanTrackTitle(
                     "Artist - Song (Official Music Video) feat. Guest"),
                 QString("Artist - Song"));
        QCOMPARE(LyricsUtils::cleanArtistName("Artist Topic"), QString("Artist"));
        QCOMPARE(LyricsUtils::similarity("Beyoncé (Official Audio)", "BEYONCE"), 1.0);
    }

    void syncedLyricsParseAndSortMultipleTimestamps()
    {
        const LyricsUtils::ParsedLyrics parsed = LyricsUtils::parse(
            "[00:02.50][00:01.2]Line\n[01:03]Next", true);
        QVERIFY(parsed.synced);
        QCOMPARE(parsed.lines.size(), 3);
        QCOMPARE(parsed.lines.at(0).toMap().value("timeMs").toInt(), 1200);
        QCOMPARE(parsed.lines.at(1).toMap().value("text").toString(), QString("Line"));
        QCOMPARE(parsed.lines.at(2).toMap().value("timeMs").toInt(), 63000);
    }

    void plainLyricsRemoveAccidentalTimestamps()
    {
        const LyricsUtils::ParsedLyrics parsed = LyricsUtils::parse(
            "[00:01.20]First line\nSecond line", false);
        QVERIFY(!parsed.synced);
        QCOMPARE(parsed.lines.size(), 2);
        QCOMPARE(parsed.lines.at(0).toMap().value("text").toString(), QString("First line"));
        QCOMPARE(parsed.lines.at(0).toMap().value("timeMs").toInt(), -1);
    }

    void timestampFreeSyncedPayloadFallsBackToPlainText()
    {
        const LyricsUtils::ParsedLyrics parsed = LyricsUtils::parse(
            "[ar:Artist]\nLyrics without timestamps", true);
        QVERIFY(!parsed.synced);
        QCOMPARE(parsed.lines.size(), 2);
        QCOMPARE(parsed.lines.at(0).toMap().value("text").toString(), QString("[ar:Artist]"));
        QCOMPARE(parsed.lines.at(1).toMap().value("timeMs").toInt(), -1);
    }
};

QTEST_APPLESS_MAIN(CoreFunctionsTests)
#include "CoreFunctionsTests.moc"
