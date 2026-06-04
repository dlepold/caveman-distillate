<?php
/**
 * nhv-creator-watch notifier.
 *
 * Thin wrapper around the project's existing admin2email() helper (remote/common).
 * Falls back to PHP mail() if the helper can't be loaded.
 *
 * Usage:
 *   php notify.php "Subject line" < body.txt        # body on stdin
 *
 * Config via env (exported by run-daily.sh from config.sh):
 *   CW_ADMIN_MAIL_INCLUDE   PHP file defining the helper
 *   CW_ADMIN_MAIL_FUNC      function name (default: admin2email)
 *   CW_ADMIN_FALLBACK_TO    recipient for the mail() fallback
 */

$subject = $argv[1] ?? 'Creator-Watch';
$body    = stream_get_contents(STDIN);
if ($body === false || $body === '') {
    fwrite(STDERR, "notify.php: empty body on stdin\n");
    exit(2);
}

$include = getenv('CW_ADMIN_MAIL_INCLUDE') ?: '';
$func    = getenv('CW_ADMIN_MAIL_FUNC') ?: 'admin2email';
$to      = getenv('CW_ADMIN_FALLBACK_TO') ?: '';

if ($include !== '' && is_readable($include)) {
    require_once $include;
}

if (function_exists($func)) {
    // Assumed signature: admin2email($subject, $body). Adjust here if yours differs.
    $func($subject, $body);
    fwrite(STDERR, "notify.php: sent via {$func}()\n");
    exit(0);
}

// Fallback.
if ($to === '') {
    fwrite(STDERR, "notify.php: {$func}() not found and no CW_ADMIN_FALLBACK_TO set\n");
    exit(3);
}
$headers = "From: creator-watch@" . (gethostname() ?: 'localhost') . "\r\n"
         . "Content-Type: text/plain; charset=UTF-8\r\n";
if (mail($to, $subject, $body, $headers)) {
    fwrite(STDERR, "notify.php: sent via mail() to {$to}\n");
    exit(0);
}
fwrite(STDERR, "notify.php: mail() failed\n");
exit(4);
