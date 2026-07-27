"""Manual "add reminder" button + modal for the Reminders panel (voice track boundary).

A simple calendar-style "New event" flow: a "+ Add reminder" button opens a
small modal with just a label and a time, plus a Create button - no
attendees, no location, no recurrence. Calls `root spawn
CreateManualReminder(label, time)` on the shared `endpoints.sv.jac` seam.

This file also owns the live reminders list shown below the button: it
fetches `GetDueReminders` (the unified medication + manual list) once on
mount, and again right after a successful create or delete, so the list
always reflects persisted state without a page refresh. Each row has a
small "x" on its right edge that calls `DeleteReminder(reminder_id)` -
reminder_id is the same id GetDueReminders reports on every ReminderItem.

Manual creation only - Ember referencing these naturally in conversation is
already wired server-side; having Ember update/complete reminders through
conversation is a separate, later phase and this file has no LLM involvement.
"""

import from react { useEffect }
sv import from endpoints { CreateManualReminder, GetDueReminders, DeleteReminder }

def:pub AddReminderModal -> JsxElement {
    has isOpen: bool = False,
        label: str = "",
        time: str = "",
        isSubmitting: bool = False,
        errorMessage: str = "",
        reminders: list = [];

    async def handleCreate -> None;
    async def fetchReminders -> None;
    async def handleDelete(reminder_id: str) -> None;

    useEffect(lambda { fetchReminders(); }, []);

    canSubmit = (len(label) > 0) and (len(time) > 0) and (not isSubmitting);

    return
        <div>
            <button
                onClick={lambda (_: MouseEvent) { isOpen = True; errorMessage = ""; }}
                aria-label="Add reminder"
                style={{
                    "width": "100%",
                    "boxSizing": "border-box",
                    "border": "2px dashed #C94F08",
                    "borderRadius": "10px",
                    "padding": "0.75rem 1rem",
                    "minHeight": "48px",
                    "fontFamily": "inherit",
                    "fontSize": "1.05rem",
                    "fontWeight": "700",
                    "cursor": "pointer",
                    "backgroundColor": "#FFF9EE",
                    "color": "#C94F08",
                    "marginBottom": "1rem"
                }}
            >
                + Add reminder
            </button>
            <ul
                aria-label="Current reminders"
                style={{
                    "listStyle": "none",
                    "margin": "0 0 1rem",
                    "padding": "0",
                    "display": "flex",
                    "flexDirection": "column",
                    "gap": "0.5rem"
                }}
            >
                {[
                    <li
                        key={f"reminder-{i}"}
                        style={{
                            "display": "flex",
                            "justifyContent": "space-between",
                            "alignItems": "center",
                            "gap": "0.5rem",
                            "padding": "0.6rem 0.6rem 0.6rem 0.85rem",
                            "backgroundColor": "#FFF9EE",
                            "border": "1px solid #D9C8AC",
                            "borderRadius": "8px",
                            "fontSize": "1rem",
                            "color": "#3B2D22"
                        }}
                    >
                        <span style={{"fontWeight": "700", "flex": "1 1 auto"}}>{reminders[i].label}</span>
                        <span style={{"color": "#6F5D4A"}}>{reminders[i].time}</span>
                        <button
                            onClick={lambda (_: MouseEvent) { handleDelete(reminders[i].reminder_id); }}
                            aria-label={f"Delete reminder: {reminders[i].label}"}
                            style={{
                                "border": "none",
                                "borderRadius": "999px",
                                "width": "44px",
                                "height": "44px",
                                "minWidth": "44px",
                                "flexShrink": "0",
                                "fontSize": "1.3rem",
                                "fontWeight": "700",
                                "lineHeight": "1",
                                "cursor": "pointer",
                                "backgroundColor": "transparent",
                                "color": "#8B5E3C"
                            }}
                        >
                            ×
                        </button>
                    </li>
                    for i in range(len(reminders))
                ]}
            </ul>
            {if isOpen {
                <div
                    role="dialog"
                    aria-modal="true"
                    aria-label="Add a new reminder"
                    style={{
                        "position": "fixed",
                        "top": "0",
                        "left": "0",
                        "width": "100%",
                        "height": "100%",
                        "backgroundColor": "rgba(59, 45, 34, 0.45)",
                        "display": "flex",
                        "alignItems": "center",
                        "justifyContent": "center",
                        "zIndex": "1000",
                        "padding": "1rem",
                        "boxSizing": "border-box"
                    }}
                >
                    <div
                        style={{
                            "width": "100%",
                            "maxWidth": "26rem",
                            "boxSizing": "border-box",
                            "backgroundColor": "#FFF9EE",
                            "border": "1px solid #D9C8AC",
                            "borderRadius": "14px",
                            "padding": "1.5rem",
                            "boxShadow": "0 12px 28px rgba(91, 62, 35, 0.25)"
                        }}
                    >
                        <h2 style={{"margin": "0 0 1rem", "fontSize": "1.35rem", "color": "#3B2D22"}}>
                            New reminder
                        </h2>
                        <label style={{"display": "block", "marginBottom": "1rem"}}>
                            <span style={{"display": "block", "marginBottom": "0.4rem", "fontSize": "1.05rem", "fontWeight": "700", "color": "#3B2D22"}}>
                                What should Ember remind you about?
                            </span>
                            <input
                                type="text"
                                value={label}
                                onChange={lambda (e: ChangeEvent) { label = e.target.value; }}
                                placeholder="e.g. Take morning insulin"
                                style={{
                                    "width": "100%",
                                    "boxSizing": "border-box",
                                    "border": "1px solid #D9C8AC",
                                    "borderRadius": "8px",
                                    "padding": "0.75rem",
                                    "minHeight": "48px",
                                    "fontFamily": "inherit",
                                    "fontSize": "1.1rem",
                                    "color": "#3B2D22",
                                    "backgroundColor": "#FFFDF7"
                                }}
                            />
                        </label>
                        <label style={{"display": "block", "marginBottom": "1.25rem"}}>
                            <span style={{"display": "block", "marginBottom": "0.4rem", "fontSize": "1.05rem", "fontWeight": "700", "color": "#3B2D22"}}>
                                What time?
                            </span>
                            <input
                                type="time"
                                value={time}
                                onChange={lambda (e: ChangeEvent) { time = e.target.value; }}
                                style={{
                                    "width": "100%",
                                    "boxSizing": "border-box",
                                    "border": "1px solid #D9C8AC",
                                    "borderRadius": "8px",
                                    "padding": "0.75rem",
                                    "minHeight": "48px",
                                    "fontFamily": "inherit",
                                    "fontSize": "1.1rem",
                                    "color": "#3B2D22",
                                    "backgroundColor": "#FFFDF7"
                                }}
                            />
                        </label>
                        {if errorMessage {
                            <p style={{"margin": "0 0 1rem", "color": "#B3261E", "fontSize": "0.95rem", "fontWeight": "700"}}>
                                {errorMessage}
                            </p>
                        }}
                        <div style={{"display": "flex", "gap": "0.75rem", "justifyContent": "flex-end"}}>
                            <button
                                onClick={lambda (_: MouseEvent) { isOpen = False; label = ""; time = ""; errorMessage = ""; }}
                                style={{
                                    "border": "1px solid #D9C8AC",
                                    "borderRadius": "999px",
                                    "padding": "0.65rem 1.25rem",
                                    "minHeight": "48px",
                                    "fontFamily": "inherit",
                                    "fontSize": "1rem",
                                    "fontWeight": "700",
                                    "cursor": "pointer",
                                    "backgroundColor": "#FFF9EE",
                                    "color": "#3B2D22"
                                }}
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleCreate}
                                disabled={not canSubmit}
                                style={{
                                    "border": "none",
                                    "borderRadius": "999px",
                                    "padding": "0.65rem 1.25rem",
                                    "minHeight": "48px",
                                    "fontFamily": "inherit",
                                    "fontSize": "1rem",
                                    "fontWeight": "700",
                                    "cursor": "pointer" if canSubmit else "not-allowed",
                                    "backgroundColor": "#C94F08",
                                    "color": "#FFFFFF",
                                    "opacity": "1" if canSubmit else "0.5"
                                }}
                            >
                                {"Creating..." if isSubmitting else "Create"}
                            </button>
                        </div>
                    </div>
                </div>
            }}
        </div>;
}
