"""Ember's voice interface (voice track boundary).

Mic button + speech-to-text placeholder + Ember's spoken reply. Speech
capture and playback are both mocked for now - swap `toggleRecording`'s
body for a real STT/TTS provider later without touching anything outside
this file (see .env.example for where those provider keys will go).

Calls `root spawn SendMessage(text)` on the shared `endpoints.sv.jac` seam
and reports the reply back up to the parent via `onSpeakingChange`, which
is how this file and AvatarView.cl.jac react to each other without
importing each other directly.
"""

sv import from endpoints { SendMessage }

def:pub VoiceControls(onSpeakingChange: Callable) -> JsxElement {
    has isRecording: bool = False,
        transcript: str = "",
        reply: str = "";

    async def toggleRecording -> None;

    return
        <div
            style={{
                "display": "flex",
                "flexDirection": "column",
                "alignItems": "center",
                "gap": "1rem",
                "padding": "1rem",
                "minWidth": "260px"
            }}
        >
            <button
                onClick={toggleRecording}
                style={{
                    "width": "72px",
                    "height": "72px",
                    "borderRadius": "50%",
                    "border": "none",
                    "cursor": "pointer",
                    "backgroundColor": "#e63946" if isRecording else "#4CAF50",
                    "color": "white",
                    "fontSize": "0.9rem"
                }}
            >
                {"Stop" if isRecording else "Talk"}
            </button>
            <p style={{"color": "#666", "textAlign": "center"}}>
                {"Listening... (speech-to-text placeholder)" if isRecording else "Tap to talk to Ember"}
            </p>
            <p style={{"fontStyle": "italic", "color": "#888", "minHeight": "1.2rem"}}>
                {transcript}
            </p>
            <p style={{"color": "#1a1a2e", "minHeight": "1.2rem"}}>
                {reply}
            </p>
        </div>;
}
