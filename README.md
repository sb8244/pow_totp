# PowTotp

- [x] 2FA time code
  - [x] Allow user to setup 2fa in settings
  - [x] Create a database entry containing the user_secret, contents of the OTP URL, 2fa is now activated
  - [x] On sign in, create a session entry of the login attempt and a random generated credential (random bytes)
  - [x] Take the generated credential in a form along with a place to enter the totp code. If the totp code matches, the credential is exchanged for a login session
- [ ] Allow for user to delete TOTP after it's setup
- [ ] Release with 1.0.20 for template hooks
- [ ] Implement base acceptable templates (extract from existing project)
- [ ] Should TOTP codes be 1-time use only? If so, need to implement via db powered code list

## In Action

![ezgif-2-7a5b55aed648](https://user-images.githubusercontent.com/1231659/77272726-42c85a00-6c88-11ea-8e27-5c19ad351069.gif)
