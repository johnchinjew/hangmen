# Hangmen

## TODO

- Do we need player ids - NO, using websockets
- Async
    - Locking is necessary! But also, stop listening to connections.
    - We want all operations for each session to be synchronous
    - Prevent double-guessing/concurrency issues
- Socket.io
    - https://ellie-app.com/8yYgw7y7sM2a1
    - https://socket.io/docs/#Using-with-Express

- Refine APIs w/r new design
- Fix server first, completely.
    - Server auto-kill dead sessions
    - Sanitize before sending session state in BE
    - Disallow set-word with numbers, etc

- End game is too ambiguous!
    - Refer to notes!!

```
- NEW: https://www.figma.com/file/duqoAy2jCyriuG03nRTxUJ/Hangmen?node-id=0%3A1
- Use Game PIN: Only one entrypoint (Home), only ONE URL, no longer a need for routing
- Merge join, and lobby
- Allow hot joins with "retro-active loss", remove "spectation"
    - Removed lobby list
- Remove guess screen
- To solve AFK: introduce a turn timeout on server
- On refresh/navigation
    - Send a remove-player request, removing the player
    - OR, use websockets features
- On refresh, simply render the Home screen... do NOT recall prior identity
    - Game is totally "in-volatile-memory"
```

- Introduce typed Ids for client

## Changes

- Guess word does not need to specify a target

## Build and run

```
npm start
```
