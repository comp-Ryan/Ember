"""ember - ElevenLabs text-to-speech (voice track boundary).

Turns Ember's reply text into spoken audio via the ElevenLabs API. Server-side
only, so the API key never reaches the browser. VoiceControls.cl.jac calls
this over `sv import` and plays the returned audio back locally.
"""

import os;
import base64;
import httpx;

# "Antoni" - one of ElevenLabs' default/premade voices. ElevenLabs describes
# it as warm with well-rounded undertones - fits a caring-companion persona
# without reading as young/energetic or stiffly formal. Swap this id to try
# a different voice from the library.
glob ELEVENLABS_VOICE_ID: str = "ErXwobaYiN019PkySvjV";

def:pub text_to_speech_audio(text: str) -> str {
    api_key = os.environ.get("TTS_API_KEY", "");
    if not api_key {
        raise ValueError("TTS_API_KEY is not set - add it to .env to enable voice playback.");
    }
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{ELEVENLABS_VOICE_ID}";
    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg"
    };
    body = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        # Lower stability = more expressive/varied delivery instead of flat and
        # monotone; higher similarity_boost = leans further into this voice's
        # own natural warmth rather than a neutral average. Tuned for a
        # warmer, less clinical-sounding companion voice.
        "voice_settings": {"stability": 0.35, "similarity_boost": 0.85}
    };
    response = httpx.post(url, headers=headers, json=body, timeout=15.0);
    response.raise_for_status();
    return base64.b64encode(response.content).decode("utf-8");
}
