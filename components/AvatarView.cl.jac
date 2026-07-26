"""Ember's visual presence (avatar track boundary).

Simple, warm animated presence - a large calm circle, not a photorealistic
avatar. Swap the rendering in here later (e.g. a 3D model) without touching
anything outside this file. The only contract this component has with the
rest of the app is the `isSpeaking` prop: a slow gentle breathing pulse
while false, a faster brighter pulse while true.

Large, high-contrast, and free of small/busy detail on purpose - built for
elderly users who need the "is Ember talking?" state readable at a glance.
The pulse is driven by a setInterval-toggled scale + CSS transition (not
CSS keyframes/a stylesheet), so it needs nothing beyond this one file.
"""

import from react { useEffect }

def:pub AvatarView(isSpeaking: bool) -> JsxElement {
    has pulsedUp: bool = False;

    useEffect(lambda {
        period = 350 if isSpeaking else 1600;
        timer = setInterval(lambda { pulsedUp = not pulsedUp; }, period);
        return lambda { clearInterval(timer); };
    }, [isSpeaking]);

    scale = (1.18 if pulsedUp else 1.0) if isSpeaking else (1.04 if pulsedUp else 1.0);
    ring_spread = (34 if pulsedUp else 18) if isSpeaking else (20 if pulsedUp else 14);
    ring_alpha = (0.42 if pulsedUp else 0.28) if isSpeaking else (0.22 if pulsedUp else 0.15);
    ring_rgb = "255, 183, 3" if isSpeaking else "33, 158, 188";
    transition_duration = "0.32s" if isSpeaking else "1.5s";
    circle_color = "#ffb703" if isSpeaking else "#219ebc";
    box_shadow = f"0 0 0 {ring_spread}px rgba({ring_rgb}, {ring_alpha})";

    return
        <div
            style={{
                "display": "flex",
                "flexDirection": "column",
                "alignItems": "center",
                "justifyContent": "center",
                "gap": "1.25rem"
            }}
        >
            <div
                style={{
                    "width": "220px",
                    "height": "220px",
                    "borderRadius": "50%",
                    "backgroundColor": circle_color,
                    "transform": f"scale({scale})",
                    "boxShadow": box_shadow,
                    "transition": f"transform {transition_duration} ease-in-out, box-shadow {transition_duration} ease-in-out, background-color 0.3s ease-in-out"
                }}
            />
            <p style={{"color": "#333", "fontSize": "1.25rem", "fontWeight": "600"}}>
                {"Ember is speaking..." if isSpeaking else "Ember is listening"}
            </p>
        </div>;
}
