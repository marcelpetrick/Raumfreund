// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

/**
 * Bookkeeping of the single active level session. Only used on the main
 * thread.
 *
 * Besides the Dart session id every [begin] hands out a native token. Events
 * of a recorder are only delivered while both match, so a late event of an
 * old recorder is dropped even if Dart reuses a session id. (The Dart side
 * discards stale session ids, too.)
 */
class SessionTracker {
    private var nextToken = 0L
    private var activeToken: Long? = null

    /** Id of the running session, or null when idle. */
    var activeSessionId: Long? = null
        private set

    /** True if [sessionId] is the running session. */
    fun isActive(sessionId: Long): Boolean = activeSessionId == sessionId

    /** True if [sessionId] with [token] (from [begin]) is the running session. */
    fun isCurrent(
        sessionId: Long,
        token: Long,
    ): Boolean = isActive(sessionId) && activeToken == token

    /** Marks [sessionId] as running and returns its token. */
    fun begin(sessionId: Long): Long {
        nextToken += 1
        activeSessionId = sessionId
        activeToken = nextToken
        return nextToken
    }

    /** Ends the running session and returns its id, or null when idle. */
    fun end(): Long? {
        val ended = activeSessionId
        activeSessionId = null
        activeToken = null
        return ended
    }
}
