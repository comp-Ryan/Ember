"""Ember's visual presence (avatar track boundary).

Starts as a simple animated circle, not a photorealistic avatar - swap the
rendering in here later without touching anything outside this file. The
only contract this component has with the rest of the app is the
`isSpeaking` prop: it glows/pulses while true, sits calm while false.
"""

def:pub AvatarView(isSpeaking: bool) -> JsxElement {
    return
        <div
            style={{
                "display": "flex",
                "flexDirection": "column",
                "alignItems": "center",
                "justifyContent": "center",
                "gap": "0.75rem"
            }}
        >
            <div
                style={{
                    "width": "160px",
                    "height": "160px",
                    "borderRadius": "50%",
                    "backgroundColor": "#ffb703" if isSpeaking else "#cfd8dc",
                    "boxShadow": "0 0 0 12px rgba(255,183,3,0.25)" if isSpeaking else "none",
                    "transition": "all 0.2s ease-in-out"
                }}
            />
            <p style={{"color": "#666", "fontSize": "0.9rem"}}>
                {"Ember is speaking..." if isSpeaking else "Ember is listening"}
            </p>
        </div>;
}
