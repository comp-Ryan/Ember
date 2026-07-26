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

node ReminderLog {
    has medication_name: str,
        timestamp: str;
}

node CheckIn {
    has mood_score: int,
        snippet: str,
        timestamp: str;
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

obj EmberTurn {
    has reply: str,
        mood: str,
        confirmed_medication: str,
        checkin_mood_score: int,
        checkin_snippet: str,
        mentioned_reminder: bool;
}

sem EmberTurn.reply = "Ember's spoken reply to the user - short, specific to what they actually said, and phrased the way a real person talks out loud, in her caring-companion voice. Never robotic or clinical, never jargon, never a stock therapist line like 'it's okay to feel that way' or 'I'm here for you.' ONLY if may_remind is True and due_medications lists something, naturally work a mention into the reply - casual, like a companion who happens to remember, e.g. 'Before we chat more, don't forget your morning insulin - have you taken it yet?' - never a clinical alert. If may_remind is False, do NOT mention any medication reminder this turn, no matter what due_medications contains - just respond naturally to what the user actually said. If the user's latest message confirms they just took a due medication, don't remind them of it again - warmly acknowledge that instead. If memory_context is non-empty, you MAY naturally weave it into your reply if it genuinely fits the moment (e.g. asking how Emma's birthday planning is going, if the user brought up family) - like organic recall, never a forced callback; skip it if it wouldn't fit naturally. If memory_context is empty, do not reference any memory fact at all this turn.";
sem EmberTurn.mood = "The emotional tone of the conversation so far, exactly one of: calm, cheerful, concerned.";
sem EmberTurn.mentioned_reminder = "True if and only if the 'reply' text you just wrote actually includes a mention of a medication reminder this turn. Must be False whenever may_remind is False, and False whenever your reply doesn't bring up a medication at all.";
sem EmberTurn.confirmed_medication = "Set this field ONLY when the user's latest message states or implies they just took one of the medications listed in due_medications (trigger phrases include things like 'yes I took it', 'just took my insulin', 'I already did that'). The value must be copied EXACTLY, character for character, from the 'name' portion of the matching due_medications entry (e.g. 'Lispro Insulin') - never the user's own words, never a paraphrase, never the trigger phrase itself. If nothing in the user's message confirms taking a medication, this must be the empty string \"\".";
sem EmberTurn.checkin_mood_score = "If the user's latest message shares how they're feeling or how their day/life is going (emotionally, not just neutral factual chit-chat like asking the time), rate their mood on a 1-5 scale: 1 = very distressed or down, 2 = somewhat down or struggling, 3 = neutral/okay, 4 = good, 5 = great. If the message doesn't share anything about their mood or how their day is going, this must be exactly 0.";
sem EmberTurn.checkin_snippet = "A short, neutral, third-person summary of what the user shared about their mood or day, suitable for a private wellness log (e.g. 'Feeling lonely and low energy today.'). Empty string \"\" if checkin_mood_score is 0.";

def generate_reply(tone: str, history: list[str], message: str, due_medications: list[str], may_remind: bool, memory_context: str) -> EmberTurn by llm();
sem generate_reply = "Ember is a real companion talking to someone she knows, not a wellness app or a therapist. Write her natural, spoken reply to the user's latest message: react like an actual person would in conversation - pick up on a specific detail in what they said, and respond with genuine personality, maybe a small observation, a memory, or a real follow-up question, instead of a generic reassurance. Speak in the given persona tone and use the conversation history for context, but do not fall back on scripted comfort phrases ('it's okay to feel that way', 'I'm here for you', 'that sounds difficult', 'thank you for sharing that') - a real friend wouldn't talk like a hotline script. Recognize when the user confirms taking a due medication regardless of may_remind. Weave in a reminder per EmberTurn.reply's may_remind guidance, and a memory per its memory_context guidance. Separately, and without changing how you phrase your reply, assess whether the user's latest message shares how they're feeling or how their day is going, for a private wellness check-in log. Then judge the overall mood of the conversation.";
sem generate_reply.tone = "Ember's persona - how she should sound, e.g. warm, patient, simple everyday language, never robotic or clinical, like a caring companion.";
sem generate_reply.history = "Recent conversation turns as 'speaker: text' lines, oldest first, ending with the user's latest message.";
sem generate_reply.message = "The user's latest message, which Ember is replying to.";
sem generate_reply.due_medications = "Medications currently due, each formatted as 'name (dosage) - scheduled for schedule_time'. Used ONLY to recognize a confirmation ('yes I took it') - never proactively mention one of these unless may_remind is also True. Empty list if nothing is due right now.";
sem generate_reply.may_remind = "Whether it is appropriate to proactively bring up a medication reminder this turn. This is already False when the reminder was already mentioned earlier this conversation, or when the user's latest message signals distress, urgency, or a crisis - the reminder can wait for a calmer moment. When False, do not bring up any medication reminder in your reply no matter what due_medications contains.";
sem generate_reply.memory_context = "A single fact about the user, already pre-filtered for relevance to their latest message (e.g. 'Granddaughter Emma's birthday is on Friday'), or the empty string \"\" if nothing on file is relevant right now. See EmberTurn.reply for how to use it.";

def is_distress_signal(message: str) -> bool by llm();
sem is_distress_signal = "Determine whether the user's latest message signals emotional distress, urgency, or a crisis - e.g. panic, a medical emergency, intense grief, fear, or saying they're struggling badly right now - a moment where bringing up an unrelated reminder would feel tone-deaf. Ordinary tiredness, mild complaints, or casual chit-chat do NOT count as distress.";
sem is_distress_signal.message = "The user's latest message.";

def relevant_memory(message: str, facts: list[str]) -> str by llm();
sem relevant_memory = "Determine if any of the given facts about the user is genuinely relevant to what they just said in their latest message - e.g. they bring up family and one fact is about a family member, or they mention food/drink and one fact is a related preference. Only pick a fact if recalling it would feel like natural, organic conversation, not a random or forced callback. If a fact IS relevant, return it copied EXACTLY, character for character, from the facts list - never a paraphrase. If none of the facts are clearly relevant to the message, return the empty string \"\".";
sem relevant_memory.message = "The user's latest message.";
sem relevant_memory.facts = "Known facts about the user, each a short string. Empty list if none exist yet.";

def log_checkin(mood_score: int, snippet: str) -> CheckInResult {
    checkin = root ++> CheckIn(
        mood_score=mood_score,
        snippet=snippet,
        timestamp=datetime.now().isoformat()
    );
    past = [n for n in [root -->] if isinstance(n, CheckIn)];
    recent = past[-3:];
    low_count = len([c for c in recent if c.mood_score <= 2]);
    return CheckInResult(
        check_in_id=jid(checkin),
        alert_raised=(low_count >= 2)
    );
}

walker:pub SendMessage {
    """Generate Ember's reply with an LLM, grounded in her persona, recent history, and any due medications."""
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

        due_meds = [n for n in [-->] if isinstance(n, MedicationItem) and n.is_due];
        due_medications = [f"{m.name} ({m.dosage}) - scheduled for {m.schedule_time}" for m in due_meds];

        already_reminded = [r.medication_name for r in [n for n in [-->] if isinstance(n, ReminderLog)]];
        unmentioned_due = [m for m in due_meds if m.name not in already_reminded];

        may_remind = len(unmentioned_due) > 0;
        if may_remind and is_distress_signal(message=self.text) {
            may_remind = False;
        }

        facts = [n for n in [-->] if isinstance(n, MemoryFact)];
        fact_strings = [f.fact for f in facts];
        memory_context = relevant_memory(message=self.text, facts=fact_strings) if len(fact_strings) > 0 else "";

        turn = generate_reply(tone=tone, history=history, message=self.text, due_medications=due_medications, may_remind=may_remind, memory_context=memory_context);

        if may_remind and turn.mentioned_reminder {
            for m in unmentioned_due {
                here ++> ReminderLog(medication_name=m.name, timestamp=datetime.now().isoformat());
            }
        }

        if turn.confirmed_medication != "" {
            matched = [m for m in due_meds if m.name == turn.confirmed_medication];
            if len(matched) > 0 {
                matched[0].is_due = False;
                matched[0].last_taken = datetime.now().strftime("%Y-%m-%d");
                old_reminders = [n for n in [-->] if isinstance(n, ReminderLog) and n.medication_name == matched[0].name];
                for r in old_reminders {
                    del r;
                }
            }
        }

        if turn.checkin_mood_score > 0 {
            log_checkin(mood_score=turn.checkin_mood_score, snippet=turn.checkin_snippet);
        }

        chat = ChatReply(reply=turn.reply, mood=turn.mood);

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
    """Mark the named MedicationItem (matched by name) as taken."""
    has med_id: str,
        reports: list[ActionResult] = [];

    can log with Root entry {
        matches = [n for n in [-->] if isinstance(n, MedicationItem) and n.name == self.med_id];
        if len(matches) == 0 {
            report ActionResult(
                success=False,
                message=f"No medication found matching '{self.med_id}'."
            );
        } else {
            med = matches[0];
            med.is_due = False;
            med.last_taken = datetime.now().strftime("%Y-%m-%d");
            report ActionResult(
                success=True,
                message=f"Logged medication '{med.name}' as taken."
            );
        }
    }
}

walker:pub LogCheckIn {
    """Persist a wellness check-in; alert_raised flags a pattern of low mood across recent check-ins."""
    has mood_score: int,
        snippet: str,
        reports: list[CheckInResult] = [];

    can log with Root entry {
        report log_checkin(mood_score=self.mood_score, snippet=self.snippet);
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
