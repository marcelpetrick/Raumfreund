// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionTrackerTest {
    private val tracker = SessionTracker()

    @Test
    fun `idle tracker has no session`() {
        assertNull(tracker.activeSessionId)
        assertFalse(tracker.isActive(1))
        assertNull(tracker.end())
    }

    @Test
    fun `begin makes the session current`() {
        val token = tracker.begin(5)
        assertEquals(5L, tracker.activeSessionId)
        assertTrue(tracker.isActive(5))
        assertTrue(tracker.isCurrent(5, token))
        assertFalse(tracker.isCurrent(4, token))
    }

    @Test
    fun `a new session replaces the old one`() {
        val oldToken = tracker.begin(1)
        val newToken = tracker.begin(2)
        assertFalse(tracker.isActive(1))
        assertFalse(tracker.isCurrent(1, oldToken))
        assertTrue(tracker.isCurrent(2, newToken))
    }

    @Test
    fun `end returns the ended session once`() {
        val token = tracker.begin(3)
        assertEquals(3L, tracker.end())
        assertFalse(tracker.isCurrent(3, token))
        assertNull(tracker.end())
    }

    @Test
    fun `reused session id does not accept events of the old recorder`() {
        val oldToken = tracker.begin(9)
        tracker.end()
        val newToken = tracker.begin(9)
        assertNotEquals(oldToken, newToken)
        assertFalse(tracker.isCurrent(9, oldToken))
        assertTrue(tracker.isCurrent(9, newToken))
    }
}
