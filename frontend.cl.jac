"""ember - Client-Side UI (shell/parent).

This file owns the shared `isSpeaking` state and renders the voice and
avatar tracks side by side. Voice-track work lives entirely in
`components/VoiceControls.cl.jac` (+ its .impl.jac); avatar-track work
lives entirely in `components/AvatarView.cl.jac`. Neither of those files
imports the other - this parent is the only thing that talks to both, by
owning `isSpeaking` and passing it down as a prop / callback.
"""

import from .components.VoiceControls { VoiceControls }
import from .components.AvatarView { AvatarView }

def:pub app -> JsxElement {
    has isSpeaking: bool = False;

    return
        <div
            style={{
                "maxWidth": "800px",
                "margin": "2rem auto",
                "padding": "0 1rem",
                "fontFamily": "system-ui, -apple-system, sans-serif",
                "color": "#1a1a2e"
            }}
        >
            <h1>ember</h1>
            <p style={{"color": "#666"}}>
                A calm voice and a friendly face, for anyone who could use both.
            </p>
            <div
                style={{
                    "display": "flex",
                    "flexDirection": "row",
                    "gap": "2rem",
                    "alignItems": "center",
                    "justifyContent": "center",
                    "marginTop": "2rem",
                    "flexWrap": "wrap"
                }}
            >
                <AvatarView isSpeaking={isSpeaking}/>
                <VoiceControls onSpeakingChange={lambda (speaking: bool) { isSpeaking = speaking; }}/>
            </div>
        </div>;
}
