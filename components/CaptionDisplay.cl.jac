"""Live transcript of the conversation with Ember (accessibility track).

A tall, high-contrast, scrollable panel showing every turn of the
conversation so far - both what the user said and what Ember replied -
for the many elderly users who benefit from reading along rather than
(or in addition to) listening. This component's only contract with the
rest of the app is the `history` prop - a list of `{"speaker", "text"}`
dicts, oldest turn first, or an empty list before anything has been said.

Reminder detection lives entirely in this file: ChatReply doesn't expose a
dedicated "this mentions a reminder" flag today, so this does a simple
keyword check on each of Ember's turns. If a real flag shows up on
ChatReply later, swap this heuristic for it without touching anything
outside this file. Either way, the cue stays gentle on purpose - a warm
tint plus a small text badge on just that turn, never a popup, never
red/alarming.
"""

def:pub CaptionDisplay(history: list) -> JsxElement {
    placeholder = "Ember's replies will appear here so you can read along.";

    is_user = [turn["speaker"] == "user" for turn in history];
    lower_texts = [turn["text"].lower() for turn in history];
    has_reminder = [
        (not is_user[i]) and (
            ("medication" in lower_texts[i]) or
            ("insulin" in lower_texts[i]) or
            ("pill" in lower_texts[i]) or
            ("tablet" in lower_texts[i]) or
            ("dose" in lower_texts[i]) or
            ("prescription" in lower_texts[i])
        )
        for i in range(len(history))
    ];

    bubbles = [
        <div
            key={f"turn-{i}"}
            style={{
                "display": "flex",
                "flexDirection": "column",
                "alignItems": "flex-end" if is_user[i] else "flex-start",
                "marginBottom": "0.85rem"
            }}
        >
            {
                <span
                    style={{
                        "display": "inline-block",
                        "marginBottom": "0.3rem",
                        "padding": "0.2rem 0.65rem",
                        "borderRadius": "999px",
                        "backgroundColor": "#f4a259",
                        "color": "#4a2e05",
                        "fontSize": "0.75rem",
                        "fontWeight": "700",
                        "letterSpacing": "0.02em"
                    }}
                >
                    Reminder
                </span> if has_reminder[i] else (
                    None if is_user[i] else
                    <span
                        style={{
                            "display": "inline-block",
                            "marginBottom": "0.3rem",
                            "fontSize": "0.85rem",
                            "fontWeight": "700",
                            "color": "#a5652e",
                            "letterSpacing": "0.02em"
                        }}
                    >
                        Ember
                    </span>
                )
            }
            <div
                style={{
                    "maxWidth": "88%",
                    "boxSizing": "border-box",
                    "padding": "0.65rem 1rem",
                    "borderRadius": "12px",
                    "fontSize": "1.05rem",
                    "lineHeight": "1.45",
                    "fontWeight": "500",
                    "overflowWrap": "break-word",
                    "backgroundColor": "#eaf6fb" if is_user[i] else ("#fff3dd" if has_reminder[i] else "#fdf3e7"),
                    "color": "#123244" if is_user[i] else "#1a1a2e",
                    "border": "2px solid #219ebc" if is_user[i] else ("2px solid #f4a259" if has_reminder[i] else "2px solid #a5652e")
                }}
            >
                {history[i]["text"]}
            </div>
        </div>
        for i in range(len(history))
    ];

    return
        <div
            style={{
                "width": "100%",
                "maxWidth": "22rem",
                "boxSizing": "border-box",
                "display": "flex",
                "flexDirection": "column",
                "borderRadius": "20px",
                "backgroundColor": "#ffffff",
                "border": "2px solid #e3e9eb"
            }}
        >
            <h2
                style={{
                    "margin": "0",
                    "padding": "1rem 1.25rem 0.75rem",
                    "fontSize": "1.1rem",
                    "color": "#14424f",
                    "borderBottom": "1px solid #e3e9eb"
                }}
            >
                Reminders
            </h2>
            <div
                style={{
                    "padding": "1.1rem 1.25rem",
                    "maxHeight": "28rem",
                    "overflowY": "auto"
                }}
            >
                {
                    bubbles if len(history) > 0 else
                    <p
                        style={{
                            "margin": "0",
                            "fontSize": "1.05rem",
                            "lineHeight": "1.5",
                            "fontStyle": "italic",
                            "color": "#8a97a0"
                        }}
                    >
                        {placeholder}
                    </p>
                }
            </div>
        </div>;
}
