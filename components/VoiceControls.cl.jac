"""Ember's voice interface (voice track boundary).

Mic button wired to the browser's Web Speech API: SpeechRecognition for
speech-to-text, speechSynthesis for text-to-speech playback of Ember's
reply. Swap either provider out later without touching anything outside
this file (see .env.example for where dedicated provider keys will go).

Calls `root spawn SendMessage(text)` on the shared `endpoints.sv.jac` seam
and reports the speaking state back up to the parent via
`onSpeakingChange`, which is how this file and AvatarView.cl.jac react to
each other without importing each other directly. `onMoodChange` reports
the same ChatReply's `.mood` field back up too, which is how AvatarView's
mood gets real data without this file importing it directly.
`onHistoryChange` reports the full running list of `{"speaker", "text"}`
turns (both what the user said and what Ember replied) back up every
turn, which is how CaptionDisplay.cl.jac renders a whole-conversation
transcript without this file importing it directly.
"""

sv import from endpoints { SendMessage }

glob _recognition: any = None;

def:pub VoiceControls(
    onSpeakingChange: Callable[[bool], None],
    onHistoryChange: Callable[[list], None],
    onMoodChange: Callable[[str], None]
) -> JsxElement {
    has isRecording: bool = False,
        transcript: str = "",
        reply: str = "",
        history: list = [];

    can with entry {
        SpeechRecognitionCls = window.SpeechRecognition if window.SpeechRecognition else window.webkitSpeechRecognition;
        if not SpeechRecognitionCls {
            return;
        }
        recognition = new(SpeechRecognitionCls);
        recognition.continuous = False;
        recognition.interimResults = False;
        recognition.lang = "en-US";
        recognition.onresult = lambda (e: any) {
            handle_transcript(e.results[0][0].transcript);
        };
        recognition.onerror = lambda (_: any) {
            isRecording = False;
            transcript = "(couldn't hear that - try again)";
        };
        recognition.onend = lambda {
            isRecording = False;
        };
        _recognition = recognition;
    }

    async def toggleRecording -> None;
    async def handle_transcript(text: str) -> None;
    def speak(text: str) -> None;

    return
        <div
            style={{
                "display": "flex",
                "flexDirection": "column",
                "alignItems": "center",
                "gap": "1rem",
                "padding": "1rem",
                "width": "264px",
                "boxSizing": "border-box"
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
            <p style={{"fontStyle": "italic", "color": "#888", "minHeight": "1.2rem", "overflowWrap": "break-word", "margin": "0"}}>
                {transcript}
            </p>
            <p style={{"color": "#1a1a2e", "minHeight": "1.2rem", "overflowWrap": "break-word", "margin": "0"}}>
                {reply}
            </p>
        </div>;
}
