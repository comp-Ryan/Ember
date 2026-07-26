"""Implementation for VoiceControls (voice track boundary)."""

impl VoiceControls.toggleRecording -> None {
    if isRecording {
        isRecording = False;
        transcript = "(mock transcript) Good morning, Ember!";
        result = root spawn SendMessage(text=transcript);
        reply = result.reports[0].reply;
        onSpeakingChange(True);
    } else {
        isRecording = True;
        reply = "";
        onSpeakingChange(False);
    }
}
