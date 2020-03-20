// HANGMEN SERVER
//
// To run server
//      node server.js

// DEPENDENCIES

const express = require('express')

// SETUP SERVER

const server = express()
const port = 3000

// USER INTERFACE END POINT

server.use('/', express.static("client"))

// GAME END POINTS

server.post('/get-new-session', (req, res) => {
    console.log(req)
    let ret = createNewSession()
    res.send('')
})
server.post('/join-session', (req, res) => {
    console.log(req)
    addPlayer()
    res.send('')
})
server.post('/get-state', (req, res) => {
    console.log(req)
    getState()
    res.send('')
})
server.post('/post-action', (req, res) => {
    console.log(req)
    handleAction()
    res.send('')
})

server.listen(port, () => console.log(`Listening on port ${port}!`))

// HANDLE END POINTS

// Create new session
// Returns SessionId of new session
function createNewSession() {
    return newId()
}

// Add player NAME to session SID
// Returns Optional<PlayerId>
function addPlayer(sid, name) {
}

// Get session's current state
// Returns Session
function getState(sid) {
}

// Updates internal game state with action ACT
// Action cases:
//      - Ready (word)
//      - Guess (letter)
//      - Guess (word)
// Returns Void
function handleAction(sid, pid, act) {
}

// MODEL

let sessions = {}
let nextId = 0

function newId() {
    return nextId++
}

// Session ADT:
//      - id: SessionId
//      - players: Dict<PlayerId, Player>
//      - alphabet: Bitmap
//      - turn: PlayerId
//      - lobby: Bool
function session() {
    return {
        id: newId(),
        players: {},
        alphabet: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        turn: 0,
        lobby: true
    }
}

// Player ADT:
//    - id: PlayerId
//    - name: String
//    - word: String
//    - ready: Bool
//    - alive: Bool
function player() {
    return {
        id: newId(),
        name: "",
        word: "",
        ready: false,
        alive: false
    }
}
