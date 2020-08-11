# Hangmen

## TODO

- Fix timer reset after player does turn
- Fix FE timer after player hotjoins
    - Possibly make time left on timer as part of session state 

## TODO later

- Make hotjoin robust 
    - Test more hotjoin cases 
        - Leave in middle of hotjoin without setting word
- Sanitize before sending session state in BE
- A/B later: Guess word does not need to specify a target
- A/B later: Remove lobby
- Improve form error messages on FE
- Confusion: set word vs vote to start game
- Potential: FE game action log

## Build and run

```
npm start
```

## Figma mockups

https://www.figma.com/file/k5HFlWyDUscjIa4RKlPBji/Hangmen?node-id=0%3A1
