/// Fixed overnight focus window.
///
/// The overnight lock is intentionally not user-editable in v1.1: it runs every
/// day from local midnight to 08:00, including weekends.
const int overnightLockStartHour = 0;
const int overnightLockEndHour = 8;

/// True while the fixed overnight block window is active.
bool isOvernightLockWindow(DateTime moment) =>
    moment.hour >= overnightLockStartHour && moment.hour < overnightLockEndHour;

/// Local 08:00 on the day that contains [moment].
DateTime overnightLockEndFor(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day, overnightLockEndHour);
