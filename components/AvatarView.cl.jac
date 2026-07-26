"""Ember's visual presence (avatar track boundary).

Two swappable looks for Ember, picked with a small "Circle" / "Fox" toggle
owned entirely by this file: the original calm breathing circle, and Fox, a
warm critter face built from plain nested divs and inline styles (no image
assets, no separate stylesheet - same one-file rule as the rest of this
component). Swap in a third rendering later the same way, without touching
anything outside this file. The only contract this component has with the
rest of the app is the `isSpeaking` prop: a slow gentle breathing pulse
while false, a faster brighter pulse while true - Fox also gets a talking
mouth on top of that same pulse.

Large, high-contrast, and free of small/busy detail on purpose - built for
elderly users who need the "is Ember talking?" state readable at a glance.
The pulse is driven by a setInterval-toggled scale + CSS transition (not
CSS keyframes/a stylesheet), so it needs nothing beyond this one file.
"""

import from react { useEffect }

def:pub AvatarView(isSpeaking: bool) -> JsxElement {
    has pulsedUp: bool = False,
        avatarStyle: str = "circle";

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
    mouth_height = (22 if pulsedUp else 10) if isSpeaking else 10;

    circle_view =
        <div
            style={{
                "width": "264px",
                "height": "264px",
                "borderRadius": "50%",
                "backgroundColor": circle_color,
                "transform": f"scale({scale})",
                "boxShadow": box_shadow,
                "transition": f"transform {transition_duration} ease-in-out, box-shadow {transition_duration} ease-in-out, background-color 0.3s ease-in-out"
            }}
        />;

    fox_inner =
        <div style={{"position": "relative", "width": "220px", "height": "232px"}}>
            <div
                style={{
                    "position": "absolute",
                    "left": "-6px",
                    "bottom": "30px",
                    "width": "64px",
                    "height": "30px",
                    "borderRadius": "50%",
                    "background": "linear-gradient(200deg, #f8b463, #e08b3a)",
                    "transform": "rotate(-32deg)",
                    "zIndex": "0"
                }}
            />
            <div
                style={{
                    "position": "absolute",
                    "left": "50%",
                    "bottom": "0",
                    "transform": "translateX(-50%)",
                    "width": "128px",
                    "height": "110px",
                    "borderRadius": "50% 50% 46% 46% / 58% 58% 42% 42%",
                    "background": "linear-gradient(160deg, #f8b463, #c96e2a)",
                    "zIndex": "1"
                }}
            />
            <div
                style={{
                    "position": "absolute",
                    "top": "0",
                    "left": "50%",
                    "transform": f"translateX(-50%) scale({scale})",
                    "transformOrigin": "center bottom",
                    "width": "150px",
                    "height": "150px",
                    "borderRadius": "50%",
                    "background": "radial-gradient(circle at 34% 28%, #f8b463, #e08b3a 55%, #c96e2a 100%)",
                    "boxShadow": box_shadow,
                    "transition": f"transform {transition_duration} ease-in-out, box-shadow {transition_duration} ease-in-out",
                    "zIndex": "2"
                }}
            >
                <div
                    style={{
                        "position": "absolute",
                        "top": "-30px",
                        "left": "-4px",
                        "width": "42px",
                        "height": "54px",
                        "background": "linear-gradient(160deg, #f8b463, #c96e2a)",
                        "clipPath": "polygon(50% 0%, 0% 100%, 100% 100%)",
                        "transform": "rotate(-14deg)"
                    }}
                >
                    <div
                        style={{
                            "position": "absolute",
                            "left": "50%",
                            "bottom": "6px",
                            "transform": "translateX(-50%)",
                            "width": "58%",
                            "height": "56%",
                            "background": "#6b4226",
                            "clipPath": "polygon(50% 0%, 0% 100%, 100% 100%)"
                        }}
                    />
                </div>
                <div
                    style={{
                        "position": "absolute",
                        "top": "-30px",
                        "right": "-4px",
                        "width": "42px",
                        "height": "54px",
                        "background": "linear-gradient(160deg, #f8b463, #c96e2a)",
                        "clipPath": "polygon(50% 0%, 0% 100%, 100% 100%)",
                        "transform": "rotate(14deg)"
                    }}
                >
                    <div
                        style={{
                            "position": "absolute",
                            "left": "50%",
                            "bottom": "6px",
                            "transform": "translateX(-50%)",
                            "width": "58%",
                            "height": "56%",
                            "background": "#6b4226",
                            "clipPath": "polygon(50% 0%, 0% 100%, 100% 100%)"
                        }}
                    />
                </div>
                <div
                    style={{
                        "position": "absolute",
                        "top": "100px",
                        "left": "6px",
                        "width": "26px",
                        "height": "16px",
                        "borderRadius": "50%",
                        "background": "radial-gradient(circle, rgba(230,111,81,0.5), transparent 70%)",
                        "filter": "blur(1px)"
                    }}
                />
                <div
                    style={{
                        "position": "absolute",
                        "top": "100px",
                        "right": "6px",
                        "width": "26px",
                        "height": "16px",
                        "borderRadius": "50%",
                        "background": "radial-gradient(circle, rgba(230,111,81,0.5), transparent 70%)",
                        "filter": "blur(1px)"
                    }}
                />
                <div
                    style={{
                        "position": "absolute",
                        "top": "70px",
                        "left": "22px",
                        "width": "34px",
                        "height": "38px",
                        "borderRadius": "50%",
                        "background": "#fff",
                        "boxShadow": "0 2px 4px rgba(0,0,0,0.15) inset"
                    }}
                >
                    <div
                        style={{
                            "position": "absolute",
                            "left": "50%",
                            "top": "58%",
                            "transform": "translate(-50%, -50%)",
                            "width": "18px",
                            "height": "20px",
                            "borderRadius": "50%",
                            "background": "#2b2420"
                        }}
                    >
                        <div
                            style={{
                                "position": "absolute",
                                "left": "62%",
                                "top": "18%",
                                "width": "5px",
                                "height": "5px",
                                "borderRadius": "50%",
                                "background": "#fff"
                            }}
                        />
                    </div>
                </div>
                <div
                    style={{
                        "position": "absolute",
                        "top": "70px",
                        "right": "22px",
                        "width": "34px",
                        "height": "38px",
                        "borderRadius": "50%",
                        "background": "#fff",
                        "boxShadow": "0 2px 4px rgba(0,0,0,0.15) inset"
                    }}
                >
                    <div
                        style={{
                            "position": "absolute",
                            "left": "50%",
                            "top": "58%",
                            "transform": "translate(-50%, -50%)",
                            "width": "18px",
                            "height": "20px",
                            "borderRadius": "50%",
                            "background": "#2b2420"
                        }}
                    >
                        <div
                            style={{
                                "position": "absolute",
                                "left": "62%",
                                "top": "18%",
                                "width": "5px",
                                "height": "5px",
                                "borderRadius": "50%",
                                "background": "#fff"
                            }}
                        />
                    </div>
                </div>
                <div
                    style={{
                        "position": "absolute",
                        "top": "94px",
                        "left": "50%",
                        "transform": "translateX(-50%)",
                        "width": "80px",
                        "height": "52px",
                        "borderRadius": "50%",
                        "background": "#d8d2c6"
                    }}
                >
                    <div
                        style={{
                            "position": "absolute",
                            "top": "12px",
                            "left": "50%",
                            "transform": "translateX(-50%)",
                            "width": "14px",
                            "height": "10px",
                            "borderRadius": "50%",
                            "background": "#2b2420"
                        }}
                    />
                    <div
                        style={{
                            "position": "absolute",
                            "top": "26px",
                            "left": "50%",
                            "transform": "translateX(-50%)",
                            "width": "24px",
                            "height": f"{mouth_height}px",
                            "borderRadius": "0 0 16px 16px",
                            "backgroundColor": "#2b2420",
                            "transition": f"height {transition_duration} ease-in-out"
                        }}
                    />
                </div>
            </div>
        </div>;

    fox_view =
        <div style={{"position": "relative", "width": "264px", "height": "278px"}}>
            <div
                style={{
                    "position": "absolute",
                    "top": "0",
                    "left": "50%",
                    "width": "220px",
                    "height": "232px",
                    "transform": "translateX(-50%) scale(1.2)",
                    "transformOrigin": "top center"
                }}
            >
                {fox_inner}
            </div>
        </div>;

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
                    "display": "flex",
                    "gap": "0.5rem",
                    "backgroundColor": "#eef2f3",
                    "padding": "0.3rem",
                    "borderRadius": "999px",
                    "position": "relative",
                    "zIndex": "2"
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
                        "backgroundColor": "#219ebc" if avatarStyle == "circle" else "transparent",
                        "color": "#fff" if avatarStyle == "circle" else "#46545c"
                    }}
                    onClick={lambda { avatarStyle = "circle"; }}
                >
                    Circle
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
                        "backgroundColor": "#219ebc" if avatarStyle == "fox" else "transparent",
                        "color": "#fff" if avatarStyle == "fox" else "#46545c"
                    }}
                    onClick={lambda { avatarStyle = "fox"; }}
                >
                    Fox
                </button>
            </div>
            {circle_view if avatarStyle == "circle" else fox_view}
            <p style={{"color": "#333", "fontSize": "1.25rem", "fontWeight": "600"}}>
                {"Ember is speaking..." if isSpeaking else "Ember is listening"}
            </p>
        </div>;
}
