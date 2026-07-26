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
        _recognition.start();
    }
}

impl VoiceControls.handle_transcript(text: str) -> None {
    transcript = text;
    result = root spawn SendMessage(text=text);
    if result.reports and len(result.reports) > 0 {
        reply = result.reports[0].reply;
        speak(reply);
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
