import express from 'express'
import http from 'http'
import socketio from 'socket.io'
import { SessionManager } from './src/session-manager.js'

const app = express()
const server = http.Server(app)
const io = socketio(server)
const port = 3000

server.listen(port)

app.use('/', express.static('client'))

const sessionManager = new SessionManager()

setInterval(sessionManager.releaseSessions, 1000 * 60 * 10)

io.on('connection', (socket) => {
  let session = null
  let sessionPin = null
  let playerPin = null

  socket.on('create-game', (name) => {
    console.log('create-game', name)
    sessionPin = sessionManager.createSession()
    console.log(`created game ${sessionPin}`)
    session = sessionManager.getSession(sessionPin)
    socket.join(sessionPin)
    playerPin = session.addPlayer(name)
    io.to(socket.id).emit('join-successful', playerPin)
    io.to(sessionPin).emit('game-update', session)
  })
  socket.on('join-game', (pin, name) => {
    console.log('join-game', pin, name)
    sessionPin = pin
    session = sessionManager.getSession(pin)
    if (!session) {
      console.log(`failed to join game ${sessionPin}`)
      return
    }
    console.log(`joined game ${sessionPin}`)
    playerPin = session.addPlayer(name)
    socket.join(sessionPin)
    io.to(socket.id).emit('join-successful', playerPin)
    io.to(sessionPin).emit('game-update', session)
  })
  socket.on('start-game', (word) => {
    console.log('start-game', word)
    session.setPlayerWord(playerPin, word)
    io.to(sessionPin).emit('game-update', session)
  })
  socket.on('guess-letter', (letter) => {
    // Sanity checks
    console.log('guess-letter', letter)
    if (playerPin !== session.currentPlayerPin()) {
      console.log(`${playerPin} attempted out-of-order guess-turn`)
      return
    }
    if (!session) {
      console.log(`${playerPin} attempted guess-word in non-existent session`)
    }

    // Handle game logic
    session.guessLetter(letter)
    io.to(sessionPin).emit('game-update', session)
    if (session.checkGameOver()) {
      console.log('Game over')
      session.reset()
    } else {
      console.log('game not over')
    }
    if (!session) {
      console.log(`${playerPin} attempted guess-word in non-existent session`)
    }
  })
  socket.on('guess-word', (pin, word) => {
    // Sanity checks
    console.log('guess-word', pin, word)
    if (playerPin !== session.currentPlayerPin()) {
      console.log(`${playerPin} attempted out-of-order guess-word`)
      return
    }
    if (!session) {
      console.log(`${playerPin} attempted guess-word in non-existent session`)
    }

    // Handle game logic
    session.guessWord(pin, word)
    io.to(sessionPin).emit('game-update', session)
    if (session.checkGameOver()) {
      console.log('Game over')
      session.reset()
    } else {
      console.log('game not over')
    }
  })
  socket.on('skip-turn', () => {
    // Sanity checks
    console.log('skip-turn')
    if (playerPin !== session.currentPlayerPin()) {
      console.log(`${playerPin} attempted out-of-order skip-turn`)
      return
    }
    if (!session) {
      console.log(`${playerPin} attempted guess-word in non-existent session`)
    }

    // Handle game logic
    session.skipTurn()
    io.to(sessionPin).emit('game-update', session)
    if (session.checkGameOver()) {
      console.log('Game over')
      session.reset()
    } else {
      console.log('game not over')
    }
  })
  // Detect disconnect -> removePlayer -> Broadcast/GameOver?
  socket.on('disconnect', () => {
    // Sanity check
    if (!session || !playerPin || !sessionPin) {
      return
    }

    // Handle game logic
    session.removePlayer(playerPin)
    io.to(sessionPin).emit('game-update', session)
    if (session.checkGameOver()) {
      console.log('Game over')
      session.reset()
    } else {
      console.log('game not over')
    }
  })
})
