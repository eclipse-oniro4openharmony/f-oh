# F-OH Server

## Project Introduction

F-OH server, providing interface services, platform management, etc. (to be developed)
## Technology Selection

- Java SpringBoot `First choice`
- Go Gin `Alternative`
- Python Flask `Alternative`

## Initial concept

- Role permissions
    - Administrator, all permissions
    - Developers, submit applications, view the list and status of applications you have submitted
- Functional modules
    - /api `Interface service, providing the HTTP interface required by the F-OH client`
    - /platform `Platform Management`
        - /login `Log in`
        - /register `Developer Registration`
        - /dev `Developer Center, submit apps, view submitted apps and review status`
        - /index `Home Statistics`
        - /app `Application management and audit`
        - /settings `Platform settings (announcements, etc.)`