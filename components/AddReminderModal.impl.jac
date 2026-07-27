"""Implementation for AddReminderModal (voice track boundary)."""

impl AddReminderModal.handleCreate -> None {
    if (len(label) == 0) or (len(time) == 0) {
        return;
    }
    isSubmitting = True;
    errorMessage = "";
    try {
        result = root spawn CreateManualReminder(label=label, time=time);
        if result.reports and len(result.reports) > 0 {
            isOpen = False;
            label = "";
            time = "";
        } else {
            errorMessage = "Couldn't save that reminder - please try again.";
        }
    } except Exception {
        errorMessage = "Couldn't save that reminder - please try again.";
    } finally {
        isSubmitting = False;
    }
}
