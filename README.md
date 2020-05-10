# Hangmen

## TODO

- First, re-implement server using socket.io:
    - https://ellie-app.com/8yYgw7y7sM2a1
    - https://socket.io/docs/#Using-with-Express
    - Removes need for player ids?
    - Fixes end-game functionality (if necessary, refer to notes)
    - Server auto-kill dead sessions
    - Server auto remove disconnected players
    - Allow hot joins with retro-active loss, remove spectation
    - Integrate new game PIN functionality into API

## TODO later

- Implement new FE
    - (Probably not necessary due to websockets:) send remove-player request on
      refresh/navigation
    - On refresh, simply render the Home screen... do NOT recall prior identity,
      game is "in-memory"
    - Since we are using PIN and are no longer using invite links, there is no
      need for routing, the only entry point is Home.
- Mitigate AFK: introduce a turn timeout on server
- Disallow set-word with numbers, etc
- Sanitize before sending session state in BE
- Use locks to prevent double-guessing, etc
- Introduce typed Ids for client

## Completed changes (update Eero about these)

- Guess word does not need to specify a target

## Build and run

```
npm start
```

## Figma mockups

https://www.figma.com/file/duqoAy2jCyriuG03nRTxUJ/Hangmen?node-id=0%3A1
