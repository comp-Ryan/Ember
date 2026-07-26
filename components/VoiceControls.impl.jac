"""Implementation for VoiceControls (voice track boundary)."""

impl VoiceControls.toggleRecording -> None {
    if isRecording {
        if _recognition {
            _recognition.stop();
        }
    } else {
        if not _recognition {
            transcript = "Speech recognition isn't supported in this browser.";
            return;
        }
        isRecording = True;
        transcript = "";
        reply = "";
        pendingTranscriptRef.current = "";
        lastHandledTranscriptRef.current = "";
        _recognition.start();
    }
}

impl VoiceControls.handle_transcript(text: str) -> None {
    if requestInFlightRef.current or text == lastHandledTranscriptRef.current {
        return;
    }
    lastHandledTranscriptRef.current = text;
    requestInFlightRef.current = True;
    transcript = text;
    try {
        result = root spawn SendMessage(text=text);
        if result.reports and len(result.reports) > 0 {
            chat = result.reports[0];
            reply = chat.reply;
            history = history + [
                {"speaker": "user", "text": text},
                {"speaker": "ember", "text": chat.reply}
            ];
            onHistoryChange(history);
            onMoodChange(chat.mood);
            speak(chat.reply);
        }
    } except Exception {
        fallback = "Sorry, I'm having a little trouble right now - mind trying that again?";
        reply = fallback;
        onSpeakingChange(False);
        speak(fallback);
    } finally {
        requestInFlightRef.current = False;
    }
}

impl VoiceControls.speak(text: str) -> None {
    try {
        b64 = await text_to_speech_audio(text=text);
        binary = window.atob(b64);
        length = binary.length;  # jac:ignore[E1032]
        audio_bytes = new(Uint8Array, length);
        for i = 0 while i < length with i += 1 {
            audio_bytes[i] = binary.charCodeAt(i);  # jac:ignore[E1032,E1001]
        }
        blob = new(Blob, [audio_bytes], {"type": "audio/mpeg"});
        url = window.URL.createObjectURL(blob);
        audio = new(Audio, url);
        audio.onplay = lambda { onSpeakingChange(True); };
        audio.onended = lambda {
            onSpeakingChange(False);
            window.URL.revokeObjectURL(url);
        };
        audio.onerror = lambda {
            onSpeakingChange(False);
            window.URL.revokeObjectURL(url);
        };
        audio.play();
    } except Exception {
        onSpeakingChange(False);
    }
}
