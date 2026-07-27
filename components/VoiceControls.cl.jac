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
        <section aria-label="Voice conversation" style={{"display": "flex", "flexDirection": "column", "alignItems": "center", "gap": "0.85rem", "padding": "1rem", "width": "min(100%, 17rem)", "boxSizing": "border-box", "textAlign": "center"}}>
            <p style={{"margin": "0", "fontFamily": "ui-monospace, 'Courier New', monospace", "fontSize": "0.78rem", "fontWeight": "700", "letterSpacing": "0.1em", "color": "#6F5D4A", "textTransform": "uppercase"}}>Speak with Ember</p>
            <button onClick={toggleRecording} aria-label={"Stop listening" if isRecording else "Start talking to Ember"} aria-pressed={isRecording} style={{"width": "96px", "height": "96px", "borderRadius": "50%", "border": "5px solid #FFF9EE", "outline": "2px solid #F36B12", "outlineOffset": "3px", "cursor": "pointer", "display": "flex", "alignItems": "center", "justifyContent": "center", "backgroundColor": "#C94F08" if isRecording else "#F36B12", "boxShadow": "0 7px 0 #A94108", "transition": "background-color 180ms ease, transform 180ms ease"}}>
                <ThinkingOrb state="listening" size={64} theme="light" paused={not isRecording}/>
            </button>
            <p aria-live="polite" style={{"margin": "0.45rem 0 0", "color": "#3B2D22", "fontSize": "1.12rem", "fontWeight": "700", "lineHeight": "1.4"}}>{"Listening — tap again when you're done." if isRecording else "Tap the orange button to talk."}</p>
            <p aria-live="polite" style={{"width": "100%", "minHeight": "1.5rem", "margin": "0.2rem 0 0", "padding": "0.65rem 0.8rem", "boxSizing": "border-box", "fontStyle": "italic", "color": "#6F5D4A", "fontSize": "1rem", "lineHeight": "1.45", "overflowWrap": "break-word", "backgroundColor": "#FFF9EE", "border": "1px solid #D9C8AC", "borderRadius": "8px"}}>{transcript if transcript else "Your words will appear here."}</p>
            <p aria-live="polite" style={{"width": "100%", "minHeight": "1.5rem", "maxHeight": "6rem", "overflowY": "auto", "margin": "0", "color": "#3B2D22", "fontSize": "1rem", "lineHeight": "1.5", "overflowWrap": "break-word", "boxSizing": "border-box"}}>{reply}</p>
        </section>;
}
