# PowTotp

- [ ] 2FA time code
  - [x] Allow user to setup 2fa in settings
  - [x] Create a database entry containing the user_secret, contents of the OTP URL, 2fa is now activated
  - [ ] On sign in, create a session entry of the login attempt and a random generated credential (random bytes)
  - [ ] Take the generated credential in a form along with a place to enter the totp code. If the totp code matches, the credential is exchanged for a login session

# TODO List

- Verify on sign in
