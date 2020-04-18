import express from 'express'
import { SessionManager } from './src/session-manager.js'

const server = express()
const port = 3000

let sessionManager = new SessionManager()

server.use(express.json())

server.use('/', express.static('client'))

// req.body = empty
// res = string (session id)
server.post('/new-session', (req, res) => {
  console.log("POST new-session")
  
  const sid = sessionManager.createSession()
  
  res.send(sid)
})

// req.body = { sid : string (session id), name : string (player name) }
// res = string (player id)
server.post('/join-session', (req, res) => {
  console.log(`POST join-session ${JSON.stringify(req.body)}`)

  const { sid, name } = req.body
  
  if (typeof sid !== 'string' || typeof name !== 'strine') {
    res.end()
    return
  }
  
  const session = sessionManager.getSession(sid)
  
  if (!session) {
    res.end()
    return
  }

  const pid = session.addPlayer(name)
  res.send(pid)
})

// req.body = { sid : string (session id) }
// res = json (session)
server.post('/get-state', (req, res) => {
  console.log(`POST get-state ${JSON.stringify(req.body)}`)
  
  const { sid } = req.body
  
  if (typeof sid !== 'string') {
    res.end()
    return
  }

  const session = sessionManager.getSession(sid)
  
  if (!session) {
    res.end()
    return
  }

  res.json(session) // TODO: sanitize
})

// req.body = { sid : string (session id), pid : string (player id), word : string }
// res = empty
server.post('/set-word', (req, res) => {
  console.log(`POST set-word ${JSON.stringify(req.body)}`)
  
  const { sid, pid, word } = req.body
  
  if (typeof sid !== 'string' || typeof pid !== 'string' || typeof word !== 'string') {
    res.end()
    return
  }

  const session = sessionManager.getSession(sid)
  
  if (session) {
    session.setPlayerWord(pid, word)
  }

  res.end()
})

// req.body = { sid : string (session id), letter : string }
// res = empty
server.post('/guess-letter', (req, res) => {
  console.log(`POST guess-letter ${JSON.stringify(req.body)}`)
  
  const { sid, letter } = req.body
  
  if (typeof sid !== 'string' || typeof letter !== 'string' || letter.length !== 1) {
    res.end()
    return
  }

  const session = sessionManager.getSession(sid)

  if (session) {
    session.guessLetter(letter)
  }

  res.end()
})

// req.body = { sid : string (session id), pid : string (target player id), word : string }
// res = empty
server.post('/guess-word', (req, res) => {
  console.log(`POST guess-word ${JSON.stringify(req.body)}`)
  
  const { sid, pid, word } = req.body
  
  if (typeof sid !== 'string' || typeof pid !== 'string' || typeof word !== 'string') {
    res.end()
    return
  }

  const session = sessionManager.getSession(sid)
  
  if (session) {
    session.guessWord(pid, word)
  }

  res.end()
})

// TODO: explicit start game api
// req.body = { sid : string (session id) }
// res = empty
server.post('/start-session', (req, res) => {
  console.log(`POST start-session ${JSON.stringify(req.body)}`)

  const { sid } = req.body

  if (typeof sid !== 'string') {
    res.end()
    return 
  }
  
  const session = sessionManager.getSession(sid)

  if (session) {
    session.start()
  }

  res.end()  
})

// TODO: what happens if player leaves lobby/game?
//  - Immediately lose - kick player from session

// TODO: whoever clicks "new game"/reset, rejoins the lobby? 
//  - Detect end-game-state: remove all players from players collection
//  - whoever chooses to reset-state => re-add their id to players collection

// TODO: restart game api
// req.body = { sid : string (session id) }
// res = empty
server.post('/reset-session', (req, res) => {
  console.log(`POST reset-session ${JSON.stringify(req.body)}`)

  const { sid } = req.body

  if (typeof sid !== 'string') {
    res.end()
    return
  }

  const session = sessionManager.getSession(sid)

  if (session) {
    session.reset()
  }

  res.end()
})

server.listen(port, () => console.log(`Listening on port ${port}!`))
