import express from 'express'
import http from 'http'
import socketio from 'socket.io'
import { pin } from './src/pin.js'
import { SessionManager } from './src/session-manager.js'

const app = express()
const server = http.Server(app)
const io = socketio(server)
const port = 3000

server.listen(port)

app.use('/', express.static('client'))

const sessionManager = new SessionManager()

io.on('connection', (socket) => {
  // Consider setting session and sessionPin to null on disconnect 
  let session = null
  let sessionPin = null 
  let playerPin = pin()

  const handleReset = function () {
    if (!session.isLobby && session.checkGameOver()) {
      io.in(sessionPin).clients((error, sockets) => {
        if (error) throw error
        sockets.forEach(socket => io.sockets.sockets[socket].leave(sessionPin))
      })
      console.log('reset session', sessionPin)
      session.reset()
    }
  }

  console.log(`${playerPin} connected to server`)
  io.to(socket.id).emit('connect-successful', playerPin)

  socket.on('create-game', (name) => {
    console.log('create-game', name, 'by', playerPin)
    if (!playerPin) {
      console.log(`failed to create pin for ${name}`)
      return
    }
    sessionPin = sessionManager.createSession()
    console.log(`created game ${sessionPin}`)
    session = sessionManager.getSession(sessionPin)
    if (!session) {
      console.log(`failed to create game ${sessionPin}`)
      return
    }
    // Establish connection between session and server
    session.skipListener.on('emit-skip', () => {
      io.to(sessionPin).emit('game-update', session)
      console.log('emit-skip', sessionPin)
    })
    socket.join(sessionPin)
    session.addPlayer(playerPin, name)
    io.to(sessionPin).emit('game-update', session)
  })

  socket.on('join-game', (pin, name) => {
    console.log('join-game', pin, name, 'by', playerPin)
    if (!playerPin) {
      console.log(`failed to create pin for ${name}`)
      return
    }
    sessionPin = pin
    session = sessionManager.getSession(pin)
    if (!session) {
      console.log(`failed to join game ${sessionPin}`)
      return
    }

    console.log(`joined game ${sessionPin}`)
    socket.join(sessionPin)
    session.addPlayer(playerPin, name)
    io.to(sessionPin).emit('game-update', session)
  })

  socket.on('set-word', (word) => {
    console.log('set-word', word, 'by', playerPin)
    session.setPlayerWord(playerPin, word)
    io.to(sessionPin).emit('game-update', session)
  })

  socket.on('start-game', () => {
    console.log('start-game by', playerPin)
    // session.setPlayerWord(playerPin, word)
    session.togglePlayerReady(playerPin)
    io.to(sessionPin).emit('game-update', session)
  })

  socket.on('guess-letter', (letter) => {
    // Sanity checks
    console.log('guess-letter', letter, 'by', playerPin)
    if (playerPin !== session.currentPlayerPin()) {
      console.log(`${playerPin} attempted out-of-order guess-turn`)
      return
    }
    if (!session) {
      console.log(`${playerPin} attempted guess-letter in non-existent session`)
    }

    // Handle game logic
    session.guessLetter(letter)
    io.to(sessionPin).emit('game-update', session)
    handleReset()
  })

  socket.on('guess-word', (pin, word) => {
    // Sanity checks
    console.log('guess-word', pin, word, 'by', playerPin)
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
    handleReset()
  })

  // socket.on('skip-turn', () => {
  //   // Sanity checks
  //   console.log('skip-turn by', playerPin)
  //   if (playerPin !== session.currentPlayerPin()) {
  //     console.log(`${playerPin} attempted out-of-order skip-turn`)
  //     return
  //   }
  //   if (!session) {
  //     console.log(`${playerPin} attempted skip-word in non-existent session`)
  //   }

  //   // Handle game logic
  //   session.skipTurn()
  //   io.to(sessionPin).emit('game-update', session)
  //   handleReset()
  // })

  socket.on('disconnect', () => {
    // Sanity check
    if (!session || !playerPin || !sessionPin) {
      return
    }
    console.log('disconnect', playerPin)

    // Handle game logic
    session.removePlayer(playerPin)
    io.to(sessionPin).emit('game-update', session)
    handleReset()
  })
})
