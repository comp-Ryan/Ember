"""ember - Entry Point.

Combines server-side endpoints with the client-side UI.
"""

import from endpoints {
    Message, PostMessage, ListMessages,
    SendMessage, GetDueMedications, LogMedicationTaken, LogCheckIn,
    GetDueReminders, CreateManualReminder
}
import from components.TextToSpeech { text_to_speech_audio }

# Client-side UI
cl {
    import from .frontend { app as ClientApp }

    def:pub app -> JsxElement {
        return <ClientApp/>;
    }
}
