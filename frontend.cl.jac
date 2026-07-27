"""ember - Client-side presentation shell.

This parent owns shared speaking, mood, and transcript state.  The visual
composition is deliberately separate from the voice, avatar, and caption
contracts passed to the child components below.
"""

import from react { useEffect }
import from .components.VoiceControls { VoiceControls }
import from .components.AvatarView { AvatarView }
import from .components.CaptionDisplay { CaptionDisplay }
import from .components.AddReminderModal { AddReminderModal }

def:pub app -> JsxElement {
    has isSpeaking: bool = False,
        mood: str = "calm",
        history: list = [],
        embers: bool = False;

    # Slow, ambient drift of the bottom gradient's position - not tied to
    # isSpeaking/mood, just a low background flicker so the page never
    # feels static. Same setInterval-toggle-plus-CSS-transition trick
    # AvatarView.cl.jac uses for its pulse, so no keyframes/stylesheet
    # are needed here either.
    useEffect(lambda {
        timer = setInterval(lambda { embers = not embers; }, 2600);
        return lambda { clearInterval(timer); };
    }, []);

    # The browser's default <body> margin (8px on every side) sits outside
    # <main> entirely, so no amount of height/overflow control on <main>
    # stops it from padding out the document past 100dvh and forcing a
    # page-level scrollbar. Zero it once on mount instead of via a
    # stylesheet, matching this codebase's inline-style-only convention.
    useEffect(lambda {
        document.documentElement.style.margin = "0";
        document.documentElement.style.height = "100%";
        document.body.style.margin = "0";
        document.body.style.height = "100%";
        return lambda { };
    }, []);

    return
        <main
            style={{
                "height": "100dvh",
                "width": "100%",
                "boxSizing": "border-box",
                "overflow": "hidden",
                "display": "flex",
                "alignItems": "center",
                "justifyContent": "center",
                "padding": "0",
                "backgroundColor": "#F5EBDD",
                "backgroundImage": "linear-gradient(180deg, #F5EBDD 0%, #F5EBDD 66%, #FFCB8E 83%, #FF8A3D 93%, #FF5A1F 100%)",
                "backgroundSize": "100% 240%",
                "backgroundPosition": "center 100%" if embers else "center 82%",
                "backgroundRepeat": "no-repeat",
                "transition": "background-position 2.6s ease-in-out",
                "fontFamily": "Georgia, 'Times New Roman', serif",
                "color": "#3B2D22"
            }}
        >
            <section
                aria-labelledby="ember-title"
                style={{
                    "width": "100%",
                    "maxWidth": "88rem",
                    "maxHeight": "100%",
                    "overflowY": "auto",
                    "boxSizing": "border-box",
                    "padding": "clamp(0.75rem, 2vw, 1.25rem) clamp(1.25rem, 3vw, 2.5rem)",
                    "backgroundColor": "#FFF9EE",
                    "borderRadius": "18px",
                    "boxShadow": "0 12px 28px rgba(91, 62, 35, 0.08)"
                }}
            >
                <header style={{"textAlign": "center", "maxWidth": "42rem", "margin": "0 auto 1.1rem"}}>
                    <h1 id="ember-title" style={{"margin": "0 0 0.5rem", "fontSize": "clamp(2.2rem, 6vw, 3.75rem)", "lineHeight": "0.95", "letterSpacing": "-0.045em", "color": "#3B2D22"}}>
                        Ember
                    </h1>
                    <p style={{"margin": "0", "color": "#6F5D4A", "fontSize": "clamp(1rem, 1.8vw, 1.15rem)", "lineHeight": "1.5"}}>
                        A calm voice and a friendly face, for anyone who could use both.
                    </p>
                </header>
                <div style={{"display": "flex", "gap": "clamp(1.5rem, 4vw, 3.5rem)", "alignItems": "stretch", "justifyContent": "center", "flexWrap": "wrap"}}>
                    <div style={{"display": "flex", "flex": "2 1 40rem", "gap": "clamp(1.25rem, 4vw, 3rem)", "alignItems": "center", "justifyContent": "center", "flexWrap": "wrap", "padding": "1.1rem", "boxSizing": "border-box", "backgroundColor": "#F9F0E2", "border": "1px solid #D9C8AC", "borderRadius": "14px"}}>
                        <AvatarView
                            isSpeaking={isSpeaking}
                            mood={mood}
                            onMoodChange={lambda (m: str) { mood = m; }}
                        />
                        <VoiceControls
                            onSpeakingChange={lambda (speaking: bool) { isSpeaking = speaking; }}
                            onHistoryChange={lambda (h: list) { history = h; }}
                            onMoodChange={lambda (m: str) { mood = m; }}
                        />
                    </div>
                    <aside aria-labelledby="transcript-title" style={{"flex": "1 1 19rem", "maxWidth": "25rem", "minWidth": "min(100%, 18rem)", "boxSizing": "border-box", "padding": "1.4rem", "backgroundColor": "#FFFDF7", "border": "1px solid #D9C8AC", "borderRadius": "14px"}}>
                        <p style={{"margin": "0 0 0.3rem", "fontFamily": "ui-monospace, 'Courier New', monospace", "fontSize": "0.76rem", "fontWeight": "700", "letterSpacing": "0.1em", "color": "#C94F08", "textTransform": "uppercase"}}>Read along</p>
                        <h2 id="transcript-title" style={{"margin": "0 0 1rem", "fontSize": "1.55rem", "color": "#3B2D22"}}>Reminders</h2>
                        <AddReminderModal/>
                        <CaptionDisplay history={history}/>
                    </aside>
                </div>
            </section>
        </main>;
}
