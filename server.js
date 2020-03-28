import express from 'express'
import { SessionManager } from './session-manager.js'

const server = express()
const port = 3000

let sessionManager = new SessionManager()

server.use(express.json())

server.use('/', express.static('client'))

server.post('/new-session', (req, res) => {
  console.log("POST new-session")
  const sid = sessionManager.createSession()
  res.send(sid)
})

server.post('/join-session', (req, res) => {
  console.log(`POST join-session ${JSON.stringify(req.body)}`)
  const { sid, name } = req.body
  if (typeof sid == 'string' && typeof name == 'string') {
    const pid = sessionManager.addPlayer(sid, name)
    res.send(pid)
    return
  }
  res.end()
})

server.post('/get-state', (req, res) => {
  console.log(`POST get-state ${JSON.stringify(req.body)}`)
  const { sid } = req.body
  if (typeof sid == 'string') {
    const session = sessionManager.getSession(sid)
    if (session) {
      res.json(session)
      return
    }
  }
  res.end()
})

server.post('/set-word', (req, res) => {
  console.log('POST set-word')
  res.end()
})

server.post('/guess-letter', (req, res) => {
  console.log('POST guess-letter')
  res.end()
})

server.post('/guess-word', (req, res) => {
  console.log('POST guess-word')
  res.end()
})

server.listen(port, () => console.log(`Listening on port ${port}!`))
