# Changelog

## [1.0.1] - 2026-05-24

### Changed

- Relaxed Rails component dependency bounds to support Rails 8.x applications, including Rails 8.1.3
- Updated the development bundle to run against Rails 8.1.3

## [1.0.0] - 2026-05-23

Initial release.

### Added

- Mountable Rails engine for TOTP-based multi-factor authentication in session-based applications
- `TwoStep::Models::Authenticatable` concern for OTP secrets, provisioning URIs, replay protection, backup code generation, and backup code consumption
- TwoStep setup and challenge flows with QR-code enrollment, manual setup key fallback, TOTP verification, and one-time backup code support
- Install generator that creates the initializer and migration for `otp_secret`, `otp_required_for_login`, `otp_backup_codes`, and `last_otp_at`
- Configurable host-app integration hooks for pending resource lookup, current resource lookup, redirects, session completion, and layout metadata
- Built-in engine views, styles, routes, and English/Japanese translations

### Security

- Backup codes stored as digests by default and verified with constant-time comparison
- Replay protection for TOTP codes via `last_otp_at`
- Safe relative-path handling for setup disable redirects
- Support for encrypted `otp_secret` storage in host applications
