import express from 'express'
import http from 'http'
import socketio from 'socket.io'
// import { SessionManager } from './src/session-manager.js'

// const server = express()
// const port = 3000

// let sessionManager = new SessionManager()

// server.use(express.json())

// server.use('/', express.static('client'))

const app = express();
const server = http.Server(app);
const io = socketio(server);

server.listen(3000);

app.use('/', express.static('client'))

// const gpin = "fakegpin"

// io.on('connection', (socket) => {
//   socket.emit('welcome', 'welcome!');
//   socket.on('create game', (id, name) => {
//     console.log('Recieved create session request from', name)
//     // Create new session LOL
//     // Return data with sid
//     // socket.to(id).emit('created game', gpin)
//     socket.join(gpin)
//     socket.emit('created game');
//   });

//   // setTimeout(() => {
//   //   socket.to(gpin).emit("room broadcast", "BROADCAST!!!!")
//   // }, 10000)
// });

// setInterval(() => {
//   io.to(gpin).emit("room broadcast", "BROADCAST!!!!")
// }, 1000);

// server.post('/new-session', (req, res) => {
//   console.log("POST new-session")

//   const { name, word } = req.body

//   if (typeof name !== 'string' || typeof word !== 'string') {
//     res.end()
//     return
//   }

//   const sid = sessionManager.createSession()

//   const session = sessionManager.getSession(sid)

//   if (!session) {
//     console.log('Failed to create new session.')
//     res.end()
//     return
//   }

//   const pid = session.addPlayer(name)
//   session.setPlayerWord(pid, word)

//   res.send(sid)
// })

// server.post('/join-session', (req, res) => {
//   console.log(`POST join-session ${JSON.stringify(req.body)}`)

//   const { sid, name, word } = req.body

//   if (typeof sid !== 'string' || typeof name !== 'string' || typeof word !== 'string') {
//     res.end()
//     return
//   }

//   const session = sessionManager.getSession(sid)

//   if (!session) {
//     console.log('Requested session does not exist.')
//     res.end()
//     return
//   }

//   const pid = session.addPlayer(name)
//   session.setPlayerWord(pid, word)

//   res.send(pid)
// })

// server.post('/get-state', (req, res) => {
//   console.log(`POST get-state ${JSON.stringify(req.body)}`)

//   const { sid } = req.body

//   if (typeof sid !== 'string') {
//     res.end()
//     return
//   }

//   const session = sessionManager.getSession(sid)

//   if (!session) {
//     console.log('Requested session does not exist.')
//     res.end()
//     return
//   }

//   res.json(session) // TODO: prepare/sanitize
//   res.end()
// })

// server.post('/guess-letter', (req, res) => {
//   console.log(`POST guess-letter ${JSON.stringify(req.body)}`)

//   const { sid, letter } = req.body

//   if (typeof sid !== 'string' || typeof letter !== 'string' || letter.length !== 1) {
//     res.end()
//     return
//   }

//   const session = sessionManager.getSession(sid)

//   if (!session) {
//     console.log('Requested session does not exist.')
//     res.end()
//     return
//   }

//   session.guessLetter(letter)
//   res.end()
// })

// server.post('/guess-word', (req, res) => {
//   console.log(`POST guess-word ${JSON.stringify(req.body)}`)

//   const { sid, word } = req.body

//   if (typeof sid !== 'string' || typeof word !== 'string') {
//     res.end()
//     return
//   }

//   const session = sessionManager.getSession(sid)

//   if (!session) {
//     console.log('Requested session does not exist.')
//     res.end()
//     return
//   }

//   session.guessWord(word)
//   res.end()
// })

// server.listen(port, () => console.log(`Listening on port ${port}!`))
