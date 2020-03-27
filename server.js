import { Player } from './src/player.js'
import { Session } from './src/session.js'
import { Alphabet } from './src/alphabet.js'

const express = require('express')

/*********
 * MODEL *
 *********/

let sessions = {}

// UPDATE MODEL
// Create new session
// Returns SessionId of new session
function createNewSession() {
    const newSession = new Session()
    sessions[newSession.getId()] = newSession
    return newSession.getId()
}

// Add player NAME to session SID
// Returns PlayerId
function addPlayer(sid, name) {
    const newPlayer = new Session(name)
    sessions[sid].addPlayer(newPlayer)
    return newPlayer.getId()
}

// Get session's current state
// Returns Session
function getState(sid) {
    return sessions[sid]
}

// Updates internal game state with action ACT(ARG)
// Action cases:
//      - Ready (word)
//      - Guess (letter)
//      - Guess (word)
// Returns Void
const actions = {
    GUESS: {
        LETTER: 'guess.letter',
        WORD: 'guess.word'
    },
    READY: 'ready'
}

// Problems:
//      - Need to differentiate between different actions
//      - Need variable number of arguments
function applyAction(sid, pid, act, args) {

    let session = sessions[sid]
    let player = session.getPlayer(pid)

    switch (act) {
        case actions.READY:

            player.toggleReady()
            
        case actions.GUESS.WORD:
            // TODO: Handle target word guesses - needs targeted player argument

        case actions.GUESS.LETTER:
            if (session.isLetterSet(args[0])) {
                // Reject if letter already guessed
                return
            } else {
                // Set letter if not guessed 
                session.setLetter(arg) 
            }
    }
}

/**********
 * SERVER *
 **********/

const server = express()
const port = 3000

/* Client end point. */
server.use('/', express.static("client"))

/* Server end points. */
server.post('/get-new-session', (req, res) => {
    console.log(req)
    // createNewSession()
    res.send('')
})
server.post('/join-session', (req, res) => {
    console.log(req)
    // addPlayer()
    res.send('')
})
server.post('/get-state', (req, res) => {
    console.log(req)
    // getState()
    res.send('')
})
server.post('/post-action', (req, res) => {
    console.log(req)
    // applyAction()
    res.send('')
})

server.listen(port, () => console.log(`Listening on port ${port}!`))