"""Ember's visual presence (avatar track boundary).

Three swappable looks for Ember, picked with a small "Circle" / "Fox" /
"3D" toggle owned entirely by this file: the original calm breathing
circle, Fox, a warm critter face built from plain nested divs and inline
styles (no image assets, no separate stylesheet - same one-file rule as
the rest of this component), and 3D, a Ready Player Me model rendered via
Avatar3DView.cl.jac (its own isolated file/lifecycle, so a WebGL or
model-load problem there can never break Circle or Fox). This component's
contract with the rest of the
app is two props: `isSpeaking` (a slow gentle breathing pulse while false, a
faster brighter pulse while true - Fox also gets a talking mouth on top of
that same pulse) and `mood` (tints the idle/listening pulse's color and
pace - "calm" / "cheerful" / "concerned" - and defaults to "calm" if omitted
or unrecognized). Fox also expresses mood through its eyebrows (raised for
cheerful, gently furrowed for concerned) rather than a color/fur change -
an expression reads more naturally on an already-has-a-face critter than a
tint would, and keeps the color language reserved for "is Ember talking?".

Large, high-contrast, and free of small/busy detail on purpose - built for
elderly users who need the "is Ember talking?" state readable at a glance.
Mood only reshapes the idle pulse, never the speaking one: the amber
"I'm talking" cue stays identical across every mood so it never competes
with mood's much subtler color/tempo shifts, and no mood pushes the pulse
fast or bright enough to read as alarming.

The pulse is driven by a setInterval-toggled scale + CSS transition (not
CSS keyframes/a stylesheet), so it needs nothing beyond this one file.
"""

import from react { useEffect }
import from .Avatar3DView { Avatar3DView }

def:pub AvatarView(isSpeaking: bool, mood: str = "calm") -> JsxElement {
    has pulsedUp: bool = False,
        avatarStyle: str = "circle";

    mood_key = mood if mood in ["calm", "cheerful", "concerned"] else "calm";

    # Idle-only presets. Speaking always uses the fixed amber values below,
    # regardless of mood, so "is Ember talking?" stays a reliable, constant cue.
    # brow_tilt is the LEFT eyebrow's rotation in degrees; the right eyebrow
    # always mirrors it with the opposite sign. Positive tilt lifts the left
    # eyebrow's outer (left) end and drops its inner (right) end - mirrored,
    # that's an outer-up arch on both brows (cheerful). Negative tilt does
    # the opposite - an inner-up furrow on both brows (concerned).
    mood_presets = {
        "calm": {
            "color": "#219ebc", "ring_rgb": "33, 158, 188",
            "period": 1600, "amp": 1.04,
            "ring_lo": 14, "ring_hi": 20,
            "alpha_lo": 0.15, "alpha_hi": 0.22,
            "transition": "1.5s",
            "brow_tilt": 0, "brow_top": "58px"
        },
        "cheerful": {
            "color": "#f4845c", "ring_rgb": "244, 132, 92",
            "period": 1300, "amp": 1.07,
            "ring_lo": 16, "ring_hi": 24,
            "alpha_lo": 0.18, "alpha_hi": 0.27,
            "transition": "1.15s",
            "brow_tilt": 8, "brow_top": "53px"
        },
        "concerned": {
            "color": "#7d8fa6", "ring_rgb": "125, 143, 166",
            "period": 2200, "amp": 1.02,
            "ring_lo": 10, "ring_hi": 14,
            "alpha_lo": 0.11, "alpha_hi": 0.15,
            "transition": "2.0s",
            "brow_tilt": -12, "brow_top": "61px"
        }
    };
    preset = mood_presets[mood_key];

    useEffect(lambda {
        period = 350 if isSpeaking else preset["period"];
        timer = setInterval(lambda { pulsedUp = not pulsedUp; }, period);
        return lambda { clearInterval(timer); };
    }, [isSpeaking, mood_key]);

    scale = (1.18 if pulsedUp else 1.0) if isSpeaking else (preset["amp"] if pulsedUp else 1.0);
    ring_spread = (34 if pulsedUp else 18) if isSpeaking else (preset["ring_hi"] if pulsedUp else preset["ring_lo"]);
    ring_alpha = (0.42 if pulsedUp else 0.28) if isSpeaking else (preset["alpha_hi"] if pulsedUp else preset["alpha_lo"]);
    ring_rgb = "255, 183, 3" if isSpeaking else preset["ring_rgb"];
    transition_duration = "0.32s" if isSpeaking else preset["transition"];
    circle_color = "#ffb703" if isSpeaking else preset["color"];
    box_shadow = f"0 0 0 {ring_spread}px rgba({ring_rgb}, {ring_alpha})";
    mouth_height = (22 if pulsedUp else 10) if isSpeaking else 10;
    brow_top = preset["brow_top"];
    brow_tilt = preset["brow_tilt"];
    brow_transition = "transform 0.4s ease-in-out, top 0.4s ease-in-out";

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
                        "top": brow_top,
                        "left": "26px",
                        "width": "24px",
                        "height": "6px",
                        "borderRadius": "3px",
                        "backgroundColor": "#6b4226",
                        "transform": f"rotate({brow_tilt}deg)",
                        "transformOrigin": "center",
                        "transition": brow_transition
                    }}
                />
                <div
                    style={{
                        "position": "absolute",
                        "top": brow_top,
                        "right": "26px",
                        "width": "24px",
                        "height": "6px",
                        "borderRadius": "3px",
                        "backgroundColor": "#6b4226",
                        "transform": f"rotate({-brow_tilt}deg)",
                        "transformOrigin": "center",
                        "transition": brow_transition
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

    avatar_3d_view = <Avatar3DView isSpeaking={isSpeaking} mood={mood}/>;

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
                <button
                    style={{
                        "border": "none",
                        "borderRadius": "999px",
                        "padding": "0.5rem 1.1rem",
                        "minHeight": "44px",
                        "fontSize": "1rem",
                        "fontWeight": "600",
                        "cursor": "pointer",
                        "backgroundColor": "#219ebc" if avatarStyle == "3d" else "transparent",
                        "color": "#fff" if avatarStyle == "3d" else "#46545c"
                    }}
                    onClick={lambda { avatarStyle = "3d"; }}
                >
                    3D
                </button>
            </div>
            <div style={{"padding": "2.75rem 0"}}>
                {circle_view if avatarStyle == "circle" else (fox_view if avatarStyle == "fox" else avatar_3d_view)}
            </div>
            <p style={{"color": "#333", "fontSize": "1.25rem", "fontWeight": "600"}}>
                {"Ember is speaking..." if isSpeaking else "Ember is listening"}
            </p>
        </div>;
}
