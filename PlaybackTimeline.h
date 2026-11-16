#pragma once

#include <QtGlobal>
#include <cstdlib>

namespace PlaybackTimeline {

inline int millisecondsFromTicks(qint64 ticks)
{
    return static_cast<int>(ticks / 10000);
}

inline int durationMilliseconds(qint64 startTicks, qint64 endTicks)
{
    return qMax(0, millisecondsFromTicks(endTicks - startTicks));
}

inline int positionMilliseconds(qint64 startTicks, qint64 positionTicks)
{
    return qMax(0, millisecondsFromTicks(positionTicks - startTicks));
}

inline int clampPosition(int positionMs, int durationMs)
{
    return qBound(0, positionMs, durationMs > 0 ? durationMs : qMax(0, positionMs));
}

inline int advancePosition(int positionMs, int durationMs, int elapsedMs, bool isPlaying)
{
    if (!isPlaying || elapsedMs <= 0) {
        return positionMs;
    }
    return clampPosition(positionMs + elapsedMs, durationMs);
}

inline bool shouldRebasePosition(int estimatedPositionMs, int reportedPositionMs,
                                 bool isPlaying, int toleranceMs = 1500)
{
    return !isPlaying || qAbs(estimatedPositionMs - reportedPositionMs) > toleranceMs;
}

inline bool shouldIgnoreSeekUpdate(int seekFromMs, int seekToMs, int reportedPositionMs,
                                   int toleranceMs = 1500)
{
    if (seekToMs >= seekFromMs) {
        return reportedPositionMs < seekToMs - toleranceMs;
    }
    return reportedPositionMs > seekToMs + toleranceMs;
}

}
