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
    if not window.speechSynthesis {
        return;
    }
    utterance = new(SpeechSynthesisUtterance, text);
    utterance.onstart = lambda { onSpeakingChange(True); };
    utterance.onend = lambda { onSpeakingChange(False); };
    utterance.onerror = lambda { onSpeakingChange(False); };
    window.speechSynthesis.cancel();
    window.speechSynthesis.speak(utterance);
}
