"""ember - Server-Side Data Layer.

Messages are stored as `Message` nodes on the graph and persist across
restarts. The walkers below are the API the client calls with `root spawn`.

They are `:pub`, so they need no login: `root` is the shared global graph and
every visitor reads and writes the same guestbook. Switch a walker to `:priv`
to require authentication and give each user their own isolated `root`.

The walkers report `Message` nodes directly. Typing `reports` as
`list[Message]` makes `(spawn W).reports` a typed `list[Message]` on the client,
so the UI gets `.author` / `.text` dot access instead of untyped dict keys.
"""

node Message {
    has author: str,
        text: str;
}

walker:pub PostMessage {
    """Append a new message and report the created node."""
    has author: str,
        text: str,
        reports: list[Message] = [];

    can post with Root entry {
        report here ++> Message(author=self.author, text=self.text);
    }
}

walker:pub ListMessages {
    """Report every message in the guestbook, one report per node."""
    has reports: list[Message] = [];

    can collect with Root entry {
        visit [-->];
    }

    can gather with Message entry {
        report here;
    }
}


# ---------------------------------------------------------------------------
# Ember care-companion domain - shared foundation for the voice + avatar
# tracks. These node types and walker signatures are the seam between the
# two tracks: don't change them later without both people agreeing first.
#
# Every walker below is a stub that returns realistic mock data - no real
# LLM calls and no real persistence/mutation logic yet. MedicationItem and
# MemoryFact mock records are seeded onto the shared root (see SeedDemoData
# and the `with entry` block at the bottom) so both tracks have real,
# queryable fixture data to build against instead of hardcoded literals.
# ---------------------------------------------------------------------------

node PersonaNode {
    has tone: str;
}

node ConversationTurn {
    has speaker: str,
        text: str,
        timestamp: str;
}

node MedicationItem {
    has name: str,
        dosage: str,
        schedule_time: str,
        last_taken: str,
        is_due: bool;
}

node MemoryFact {
    has category: str,
        fact: str,
        created_at: str;
}

obj ChatReply {
    has reply: str,
        mood: str;
}

obj ActionResult {
    has success: bool,
        message: str;
}

obj CheckInResult {
    has check_in_id: str,
        alert_raised: bool;
}

walker:pub SendMessage {
    """Mock conversational reply. Real LLM wiring is future track work."""
    has text: str,
        reports: list[ChatReply] = [];

    can respond with Root entry {
        report ChatReply(
            reply=f"(mock) Got it - you said: \"{self.text}\". I'm still a stub!",
            mood="content"
        );
    }
}

walker:pub GetDueMedications {
    """Report the seeded MedicationItem nodes that are currently due.

    Calls SeedDemoData defensively first: module-level `with entry` seeding
    doesn't reliably fire for every way this module can get loaded (e.g.
    when it's only reached via import, as under `jac dev`/`jac start`), so
    this walker guarantees its own fixture data exists before querying.
    """
    has reports: list[MedicationItem] = [];

    can collect with Root entry {
        root spawn SeedDemoData();
        visit [-->];
    }

    can gather with MedicationItem entry {
        if here.is_due {
            report here;
        }
    }
}

walker:pub LogMedicationTaken {
    """Mock acknowledgement. Real persistence/mutation is future track work."""
    has med_id: str,
        reports: list[ActionResult] = [];

    can log with Root entry {
        report ActionResult(
            success=True,
            message=f"(mock) Logged medication '{self.med_id}' as taken."
        );
    }
}

walker:pub LogCheckIn {
    """Mock wellness check-in. Real alerting logic is future track work."""
    has mood_score: int,
        snippet: str,
        reports: list[CheckInResult] = [];

    can log with Root entry {
        report CheckInResult(
            check_in_id="mock-checkin-0001",
            alert_raised=(self.mood_score <= 2)
        );
    }
}


walker SeedDemoData {
    """Idempotently seed demo MedicationItem / MemoryFact fixtures onto root."""
    can seed with Root entry {
        existing_meds = [n for n in [-->] if isinstance(n, MedicationItem)];
        if len(existing_meds) == 0 {
            here ++> MedicationItem(
                name="Lispro Insulin",
                dosage="10 units",
                schedule_time="9:00 AM",
                last_taken="",
                is_due=True
            );
            here ++> MedicationItem(
                name="Blood Pressure Medication",
                dosage="1 tablet",
                schedule_time="8:00 PM",
                last_taken="2026-07-25",
                is_due=False
            );
        }
        existing_memories = [n for n in [-->] if isinstance(n, MemoryFact)];
        if len(existing_memories) == 0 {
            here ++> MemoryFact(
                category="preference",
                fact="Prefers chamomile tea after breakfast",
                created_at="2026-07-20"
            );
            here ++> MemoryFact(
                category="family",
                fact="Granddaughter Emma's birthday is on Friday",
                created_at="2026-07-20"
            );
        }
    }
}

with entry {
    root spawn SeedDemoData();
}
