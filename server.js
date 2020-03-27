import express from 'express'
import { SessionManager } from './session-manager.js'

const server = express()
const port = 3000
let sessionManager = new SessionManager()

server.use('/', express.static('client'))

server.post('/new-session', (req, res) => {
  console.log(req)
  // const sid = sessionManager.createSession()
  res.send('...')
})

server.post('/join-session', (req, res) => {
  console.log(req)
  // sessionManager.addPlayer(req.sid, req.name)
  res.send('...')
})

server.post('/get-state', (req, res) => {
  console.log(req)
  // sessionManager.getSession(...)
  res.send('...')
})

server.post('/set-word', (req, res) => {
  console.log(req)
  // sessionManager.applyAction(...)
  res.send('...')
})

server.post('/guess-letter', (req, res) => {
  console.log(req)
  // sessionManager.applyAction(...)
  res.send('...')
})

server.post('/guess-word', (req, res) => {
  console.log(req)
  // sessionManager.applyAction(...)
  res.send('...')
})

server.listen(port, () => console.log(`Listening on port ${port}!`))
