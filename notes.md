# Notes

## Security

* The strictness/strength of security measures at any given time is controlled by a
  server-wide suspicion level.
* There are three suspicion levels:
  * Unsuspecting: The default state. Users have the freedom to make a large number of mistakes.
  * Suspicious: A low-scale hack attempt on a specific user might be happening.
  * Paranoid: A large-scale hack attempt or mining might be going on.
* Suspicion is raised by a number of things:
  * A high number of active authentication sessions in comparison to the number of users.
  * A high number of "fake" authentication session (attempts to log into email addresses that don't exist)
* With increasing suspicion, the server will add security measures to the already existing
  ones. A suspicious server will add measures which will ensure the safety of individual
  users. A paranoid server will add measures which will prevent any "bulk attempting".
  Some of these measures involve:
  * Lowering the MAX_ALLOWED_ATTEMPTS threshold.
  * Preventing users from making log-in attempts from a different IP address than their
    previous failed attempt was made from, for a short duration (like 5 minutes).
  * Temporarily locking out IP addresses with a remarkably high amount of combined attempts.
  * Limiting the number of different users that a single IP address can attempt to log in to.
