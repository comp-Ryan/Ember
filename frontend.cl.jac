"""ember - Client-Side UI (shell/parent).

This file owns the shared `isSpeaking` state and renders the voice and
avatar tracks side by side. Voice-track work lives entirely in
`components/VoiceControls.cl.jac` (+ its .impl.jac); avatar-track work
lives entirely in `components/AvatarView.cl.jac`. Neither of those files
imports the other - this parent is the only thing that talks to both, by
owning `isSpeaking` and passing it down as a prop / callback.

Also owns `mood` ("calm" / "cheerful" / "concerned"), passed down to
AvatarView the same way. There's no real mood-detection signal yet (e.g.
from conversation sentiment), so for now this is surfaced as a small manual
picker here - swap the picker for a real signal later without touching
AvatarView, which only ever cares about the `mood` string it's handed.
"""

import from .components.VoiceControls { VoiceControls }
import from .components.AvatarView { AvatarView }

def:pub app -> JsxElement {
    has isSpeaking: bool = False,
        mood: str = "calm";

    return
        <div
            style={{
                "minHeight": "100dvh",
                "width": "100%",
                "boxSizing": "border-box",
                "display": "flex",
                "flexDirection": "column",
                "alignItems": "center",
                "justifyContent": "center",
                "gap": "3rem",
                "padding": "3rem 1.5rem",
                "backgroundColor": "#f4f8f9",
                "fontFamily": "system-ui, -apple-system, sans-serif",
                "color": "#1a1a2e"
            }}
        >
            <div style={{"textAlign": "center", "maxWidth": "32rem"}}>
                <h1 style={{"margin": "0 0 0.5rem", "fontSize": "2.5rem", "letterSpacing": "-0.02em", "color": "#14424f"}}>
                    ember
                </h1>
                <p style={{"margin": "0", "color": "#5c6b70", "fontSize": "1.05rem", "lineHeight": "1.5"}}>
                    A calm voice and a friendly face, for anyone who could use both.
                </p>
            </div>
            <div
                style={{
                    "display": "flex",
                    "gap": "0.5rem",
                    "backgroundColor": "#eef2f3",
                    "padding": "0.3rem",
                    "borderRadius": "999px"
                }}
            >
                <button
                    style={{
                        "border": "none",
                        "borderRadius": "999px",
                        "padding": "0.5rem 1.1rem",
                        "minHeight": "44px",
                        "fontSize": "1rem",
                        "fontWeight": "600",
                        "cursor": "pointer",
                        "backgroundColor": "#219ebc" if mood == "calm" else "transparent",
                        "color": "#fff" if mood == "calm" else "#46545c"
                    }}
                    onClick={lambda { mood = "calm"; }}
                >
                    Calm
                </button>
                <button
                    style={{
                        "border": "none",
                        "borderRadius": "999px",
                        "padding": "0.5rem 1.1rem",
                        "minHeight": "44px",
                        "fontSize": "1rem",
                        "fontWeight": "600",
                        "cursor": "pointer",
                        "backgroundColor": "#219ebc" if mood == "cheerful" else "transparent",
                        "color": "#fff" if mood == "cheerful" else "#46545c"
                    }}
                    onClick={lambda { mood = "cheerful"; }}
                >
                    Cheerful
                </button>
                <button
                    style={{
                        "border": "none",
                        "borderRadius": "999px",
                        "padding": "0.5rem 1.1rem",
                        "minHeight": "44px",
                        "fontSize": "1rem",
                        "fontWeight": "600",
                        "cursor": "pointer",
                        "backgroundColor": "#219ebc" if mood == "concerned" else "transparent",
                        "color": "#fff" if mood == "concerned" else "#46545c"
                    }}
                    onClick={lambda { mood = "concerned"; }}
                >
                    Concerned
                </button>
            </div>
            <div
                style={{
                    "display": "flex",
                    "flexDirection": "row",
                    "gap": "3rem",
                    "alignItems": "center",
                    "justifyContent": "center",
                    "flexWrap": "wrap"
                }}
            >
                <AvatarView isSpeaking={isSpeaking} mood={mood}/>
                <VoiceControls onSpeakingChange={lambda (speaking: bool) { isSpeaking = speaking; }}/>
            </div>
        </div>;
}
