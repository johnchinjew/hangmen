# Hangmen

## TODO

- Fixes end-game functionality (if necessary, refer to notes)
- Server auto-kill dead sessions
- Server auto remove disconnected players
- Allow hot joins with retro-active loss, remove spectation
  - Hotjoin users will join w/ empty word -> immediate death on game update
    - FIX: Use player.ready flag to handle hotjoins
    - If player.not ready but shud die, they don't die bro.

## TODO later

- Implement new FE
    - (Probably not necessary due to websockets:) send remove-player request on
      refresh/navigation
    - On refresh, simply render the Home screen... do NOT recall prior identity,
      game is "in-memory"
- Mitigate AFK: introduce a turn timeout on server
- Disallow set-word with numbers, etc on BE
- Sanitize before sending session state in BE
- Use locks to prevent double-guessing, etc
- A/B later: Guess word does not need to specify a target
- Improve form error messages on FE
- Display game pin during active game
- FE game action log

## Build and run

```
npm start
```

## Figma mockups

https://www.figma.com/file/duqoAy2jCyriuG03nRTxUJ/Hangmen?node-id=0%3A1
https://www.figma.com/file/k5HFlWyDUscjIa4RKlPBji/Hangmen?node-id=0%3A1
