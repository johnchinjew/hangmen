import express from 'express'
import http from 'http'
import socketio from 'socket.io'
import { SessionManager } from './src/session-manager.js'

// app.use(express.json())

const app = express();
const server = http.Server(app);
const io = socketio(server);
const port = 3000

server.listen(port);

app.use('/', express.static('client'))

const sessionManager = new SessionManager()

io.on('connection', (socket) => {
    socket.on('create-game', (name, word) => {
        console.log('create-game', name, word)
        const newPin = sessionManager.createSession();
        console.log(`created game ${newPin}`)
        const session = sessionManager.getSession(newPin)
        socket.join(newPin)
        const newId = session.addPlayer(name)
        // TODO: also deliver pid in game-update
        io.to(newPin).emit('game-update', session)
    });
    socket.on('join-game', (pin, name, word) => {
        console.log('join-game', pin, name, word)
        socket.join(pin)
        const session = sessionManager.getSession(pin);
        console.log(`join this session: ${session}`)
        if (!session) {
            console.log(`session ${pin} DNE`)
            return
        }
        const newId = session.addPlayer(name)
        // TODO: also deliver pid in game-update
        io.to(pin).emit('game-update', session)
    });
    // setInterval(() => {
    //     console.log(gpin)
    //     if (gpin !== null)
    //         io.to(gpin).emit('game-update', 'game')
    // }, 2000);
});


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
