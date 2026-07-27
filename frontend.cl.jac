"""ember - Client-side presentation shell.

This parent owns shared speaking, mood, and transcript state.  The visual
composition is deliberately separate from the voice, avatar, and caption
contracts passed to the child components below.
"""

import from .components.VoiceControls { VoiceControls }
import from .components.AvatarView { AvatarView }
import from .components.CaptionDisplay { CaptionDisplay }

def:pub app -> JsxElement {
    has isSpeaking: bool = False,
        mood: str = "calm",
        history: list = [];

    return
        <main
            style={{
                "minHeight": "100dvh",
                "width": "100%",
                "boxSizing": "border-box",
                "display": "flex",
                "alignItems": "center",
                "justifyContent": "center",
                "padding": "clamp(1rem, 4vw, 3.5rem) clamp(0.85rem, 3vw, 2rem)",
                "background": "linear-gradient(180deg, #F5EBDD 0%, #F5EBDD 82%, #FFA45C 100%)",
                "fontFamily": "Georgia, 'Times New Roman', serif",
                "color": "#3B2D22"
            }}
        >
            <section
                aria-labelledby="ember-title"
                style={{
                    "width": "100%",
                    "maxWidth": "70rem",
                    "boxSizing": "border-box",
                    "padding": "clamp(1.25rem, 4vw, 3.5rem)",
                    "backgroundColor": "#FFF9EE",
                    "border": "1px solid #D9C8AC",
                    "borderRadius": "18px",
                    "boxShadow": "0 12px 28px rgba(91, 62, 35, 0.08)"
                }}
            >
                <header style={{"textAlign": "center", "maxWidth": "42rem", "margin": "0 auto 2rem"}}>
                    <p style={{"margin": "0 0 0.65rem", "color": "#C94F08", "fontFamily": "ui-monospace, 'Courier New', monospace", "fontSize": "0.78rem", "fontWeight": "700", "letterSpacing": "0.13em", "textTransform": "uppercase"}}>
                        Your conversation companion
                    </p>
                    <h1 id="ember-title" style={{"margin": "0 0 0.75rem", "fontSize": "clamp(2.5rem, 7vw, 4.5rem)", "lineHeight": "0.95", "letterSpacing": "-0.045em", "color": "#3B2D22"}}>
                        Ember
                    </h1>
                    <p style={{"margin": "0", "color": "#6F5D4A", "fontSize": "clamp(1.05rem, 2vw, 1.22rem)", "lineHeight": "1.6"}}>
                        A calm voice and a friendly face, for anyone who could use both.
                    </p>
                </header>
                <div aria-label="Choose Ember's mood" style={{"display": "flex", "justifyContent": "center", "flexWrap": "wrap", "gap": "0.45rem", "marginBottom": "2rem"}}>
                    <button aria-pressed={mood == "calm"} style={{"border": "1px solid #D9C8AC", "borderRadius": "999px", "padding": "0.6rem 1.15rem", "minHeight": "46px", "fontFamily": "inherit", "fontSize": "1rem", "fontWeight": "700", "cursor": "pointer", "backgroundColor": "#C94F08" if mood == "calm" else "#FFF9EE", "color": "#FFFFFF" if mood == "calm" else "#3B2D22"}} onClick={lambda { mood = "calm"; }}>Calm</button>
                    <button aria-pressed={mood == "cheerful"} style={{"border": "1px solid #D9C8AC", "borderRadius": "999px", "padding": "0.6rem 1.15rem", "minHeight": "46px", "fontFamily": "inherit", "fontSize": "1rem", "fontWeight": "700", "cursor": "pointer", "backgroundColor": "#C94F08" if mood == "cheerful" else "#FFF9EE", "color": "#FFFFFF" if mood == "cheerful" else "#3B2D22"}} onClick={lambda { mood = "cheerful"; }}>Cheerful</button>
                    <button aria-pressed={mood == "concerned"} style={{"border": "1px solid #D9C8AC", "borderRadius": "999px", "padding": "0.6rem 1.15rem", "minHeight": "46px", "fontFamily": "inherit", "fontSize": "1rem", "fontWeight": "700", "cursor": "pointer", "backgroundColor": "#C94F08" if mood == "concerned" else "#FFF9EE", "color": "#FFFFFF" if mood == "concerned" else "#3B2D22"}} onClick={lambda { mood = "concerned"; }}>Concerned</button>
                </div>
                <div style={{"display": "flex", "gap": "clamp(1.5rem, 4vw, 3.5rem)", "alignItems": "stretch", "justifyContent": "center", "flexWrap": "wrap"}}>
                    <div style={{"display": "flex", "flex": "1 1 34rem", "gap": "clamp(1.25rem, 4vw, 3rem)", "alignItems": "center", "justifyContent": "center", "flexWrap": "wrap", "padding": "1.25rem", "boxSizing": "border-box", "backgroundColor": "#F9F0E2", "border": "1px solid #D9C8AC", "borderRadius": "14px"}}>
                        <AvatarView isSpeaking={isSpeaking} mood={mood}/>
                        <VoiceControls
                            onSpeakingChange={lambda (speaking: bool) { isSpeaking = speaking; }}
                            onHistoryChange={lambda (h: list) { history = h; }}
                            onMoodChange={lambda (m: str) { mood = m; }}
                        />
                    </div>
                    <aside aria-labelledby="transcript-title" style={{"flex": "1 1 19rem", "maxWidth": "25rem", "minWidth": "min(100%, 18rem)", "boxSizing": "border-box", "padding": "1.4rem", "backgroundColor": "#FFFDF7", "border": "1px solid #D9C8AC", "borderRadius": "14px"}}>
                        <p style={{"margin": "0 0 0.3rem", "fontFamily": "ui-monospace, 'Courier New', monospace", "fontSize": "0.76rem", "fontWeight": "700", "letterSpacing": "0.1em", "color": "#C94F08", "textTransform": "uppercase"}}>Read along</p>
                        <h2 id="transcript-title" style={{"margin": "0 0 1rem", "fontSize": "1.55rem", "color": "#3B2D22"}}>Reminders</h2>
                        <CaptionDisplay history={history}/>
                    </aside>
                </div>
            </section>
        </main>;
}
