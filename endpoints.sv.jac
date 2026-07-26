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

import from datetime { datetime }

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
# SendMessage is now wired to a real LLM call and persists ConversationTurn
# history on the graph. Every other walker below is still a stub that
# returns realistic mock data. MedicationItem and MemoryFact mock records
# are seeded onto the shared root (see SeedDemoData and the `with entry`
# block at the bottom) so both tracks have real, queryable fixture data to
# build against instead of hardcoded literals.
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

sem ChatReply.reply = "Ember's spoken reply to the user - short, specific to what they actually said, and phrased the way a real person talks out loud, in her caring-companion voice. Never robotic or clinical, never jargon, and never a stock therapist line like 'it's okay to feel that way' or 'I'm here for you.'";
sem ChatReply.mood = "The emotional tone of the conversation so far, exactly one of: calm, cheerful, concerned.";

def generate_reply(tone: str, history: list[str], message: str) -> ChatReply by llm();
sem generate_reply = "Ember is a real companion talking to someone she knows, not a wellness app or a therapist. Write her natural, spoken reply to the user's latest message: react like an actual person would in conversation - pick up on a specific detail in what they said, and respond with genuine personality, maybe a small observation, a memory, or a real follow-up question, instead of a generic reassurance. Speak in the given persona tone and use the conversation history for context, but do not fall back on scripted comfort phrases ('it's okay to feel that way', 'I'm here for you', 'that sounds difficult', 'thank you for sharing that') - a real friend wouldn't talk like a hotline script. Then judge the overall mood of the conversation.";
sem generate_reply.tone = "Ember's persona - how she should sound, e.g. warm, patient, simple everyday language, never robotic or clinical, like a caring companion.";
sem generate_reply.history = "Recent conversation turns as 'speaker: text' lines, oldest first, ending with the user's latest message.";
sem generate_reply.message = "The user's latest message, which Ember is replying to.";

walker:pub SendMessage {
    """Generate Ember's reply with an LLM, grounded in her persona and recent history."""
    has text: str,
        reports: list[ChatReply] = [];

    can respond with Root entry {
        root spawn SeedDemoData();

        personas = [n for n in [-->] if isinstance(n, PersonaNode)];
        tone = personas[0].tone if len(personas) > 0 else "warm and caring";

        here ++> ConversationTurn(
            speaker="user",
            text=self.text,
            timestamp=datetime.now().isoformat()
        );

        turns = [n for n in [-->] if isinstance(n, ConversationTurn)];
        recent = turns[-8:];
        history = [f"{t.speaker}: {t.text}" for t in recent];

        chat = generate_reply(tone=tone, history=history, message=self.text);

        here ++> ConversationTurn(
            speaker="ember",
            text=chat.reply,
            timestamp=datetime.now().isoformat()
        );

        report chat;
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
        existing_persona = [n for n in [-->] if isinstance(n, PersonaNode)];
        if len(existing_persona) == 0 {
            here ++> PersonaNode(
                tone="warm, patient, uses simple everyday language - never robotic or clinical, speaks like a caring companion and avoids jargon"
            );
        }
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
