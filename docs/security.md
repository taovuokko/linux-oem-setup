# Security Notes

- Passwords must not be passed as command-line arguments.
- GUI validation is only a usability feature. The helper must validate all input
  again.
- The cleanup order is critical: autologin must be removed before the temporary
  setup user is removed.
- If critical cleanup fails, the systemd cleanup unit must fail and retry on the
  next boot.
- The installer must not delete an existing setup user during a reinstall.
- Rollback must remove a partially created target user if apply fails before the
  operation is committed.
