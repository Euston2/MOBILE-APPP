package com.lockout.lockout.platform

/**
 * Everything the blocking service needs to enforce the limit.
 *
 * Deliberately a plain data class with no Android imports: the decision logic
 * ([BlockPolicy]) is unit tested on the JVM, and the service must be able to
 * answer "would this app be blocked?" without Flutter being alive.
 *
 * The values are pushed from Dart (`LockoutPlatform.setBlockingConfig`) and
 * cached in [BlockingStore] so they survive the app process being killed.
 */
data class BlockingConfig(
    /** Apps whose combined foreground time counts against the limit. */
    val monitoredPackages: Set<String>,
    /** Combined daily limit in seconds; 0 means "no limit configured". */
    val dailyLimitSeconds: Int,
    /** True once the limit has been hit (Stage 4 stamps this at midnight). */
    val isLocked: Boolean,
    /** Local midnight at which a lock expires, as epoch millis. */
    val nextResetAtMs: Long,
) {
    /** Only run the service when there is actually something to enforce. */
    val isActive: Boolean
        get() = dailyLimitSeconds > 0 && monitoredPackages.isNotEmpty()
}
