"""ember - Entry Point.

Combines server-side endpoints with the client-side UI.
"""

import from endpoints {
    Message, PostMessage, ListMessages,
    SendMessage, GetDueMedications, LogMedicationTaken, LogCheckIn
}

# Client-side UI
cl {
    import from .frontend { app as ClientApp }

    def:pub app -> JsxElement {
        return <ClientApp/>;
    }
}
