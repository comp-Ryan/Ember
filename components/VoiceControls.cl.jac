"""Ember's voice interface (voice track boundary).

Mic button wired to the browser's Web Speech API (SpeechRecognition) for
speech-to-text. Text-to-speech playback of Ember's reply goes through the
ElevenLabs API instead of the browser's speechSynthesis - see
TextToSpeech.sv.jac, which keeps the API key server-side and hands back
base64 audio for this file to play. Swap either provider out later without
touching anything outside this file (see .env.example for provider keys).

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
sv import from .TextToSpeech { text_to_speech_audio }
import from "thinking-orbs" { ThinkingOrb }
import from react { useRef }

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

    requestInFlightRef = useRef(False);
    lastHandledTranscriptRef = useRef("");
    pendingTranscriptRef = useRef("");

    can with entry {
        SpeechRecognitionCls = window.SpeechRecognition if window.SpeechRecognition else window.webkitSpeechRecognition;
        if not SpeechRecognitionCls {
            return;
        }
        recognition = new(SpeechRecognitionCls);
        recognition.continuous = False;
        # Show interim words locally, but do not call the backend until
        # `onend` says the utterance is complete.
        recognition.interimResults = True;
        recognition.lang = "en-US";
        recognition.onresult = lambda (e: any) {
            heard = e.results[0][0].transcript;
            pendingTranscriptRef.current = heard;
            transcript = heard;
        };
        recognition.onerror = lambda (_: any) {
            pendingTranscriptRef.current = "";
            isRecording = False;
            transcript = "(couldn't hear that - try again)";
        };
        recognition.onend = lambda {
            isRecording = False;
            completed = pendingTranscriptRef.current;
            pendingTranscriptRef.current = "";
            if completed {
                handle_transcript(completed);
            }
        };
        _recognition = recognition;
    }

    async def toggleRecording -> None;
    async def handle_transcript(text: str) -> None;
    async def speak(text: str) -> None;

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
                aria-label={"Stop" if isRecording else "Talk"}
                style={{
                    "width": "72px",
                    "height": "72px",
                    "borderRadius": "50%",
                    "border": "none",
                    "cursor": "pointer",
                    "display": "flex",
                    "alignItems": "center",
                    "justifyContent": "center",
                    "backgroundColor": "#e63946" if isRecording else "#4CAF50"
                }}
            >
                <ThinkingOrb state="listening" size={64} theme="light" paused={not isRecording}/>
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
