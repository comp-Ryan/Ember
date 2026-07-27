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
                        "backgroundColor": "#FFD2A6",
                        "color": "#5A351D",
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
                        "color": "#C94F08",
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
                    "padding": "0.8rem 1rem",
                    "borderRadius": "8px",
                    "fontSize": "1.08rem",
                    "lineHeight": "1.55",
                    "fontWeight": "500",
                    "overflowWrap": "break-word",
                    "backgroundColor": "#FCE7D2" if is_user[i] else ("#FFF0D9" if has_reminder[i] else "#FFF9EE"),
                    "color": "#3B2D22",
                    "border": "1px solid #F36B12" if is_user[i] else ("1px solid #E6A35F" if has_reminder[i] else "1px solid #D9C8AC")
                }}
            >
                {history[i]["text"]}
            </div>
        </div>
        for i in range(len(history))
    ];

    return
        <div aria-live="polite" style={{"width": "100%", "maxWidth": "22rem", "maxHeight": "30rem", "overflowY": "auto", "boxSizing": "border-box", "paddingRight": "0.25rem"}}>
            {bubbles if len(history) > 0 else None}
        </div>;
}
