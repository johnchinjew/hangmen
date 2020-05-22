import { pin } from './pin.js'
import { Player } from './player.js'
import { Alphabet } from './alphabet.js'

/**
 * Shuffles array in place.
 * @param {Array} a items An array containing the items.
 */
function shuffle(a) {
  var j, x, i
  for (i = a.length - 1; i > 0; i--) {
    j = Math.floor(Math.random() * (i + 1))
    x = a[i]
    a[i] = a[j]
    a[j] = x
  }
  return a
}

export function Session() {
  this.pin = pin()
  this.players = {}
  this.turnOrder = []
  this.alphabet = new Alphabet()
  this.isLobby = true
  this.log = []

  this.getPin = function () {
    return this.pin
  }

  this.addPlayer = function (pin, name) {
    if (pin in this.players)
      return
    this.players[pin] = new Player(name)
  }

  this._killPlayer = function (pid) {
    this.players[pid].kill()
    const turn = this.turnOrder.indexOf(pid)
    if (turn > -1) {
      this.turnOrder.splice(turn, 1)
    }
  }

  this.removePlayer = function (pid) {
    if (this.isLobby) {
      // If  not in middle of session, just delete player from collection
      if (this.players[pid]) {
        delete this.players[pid]
      }
    } else {
      // We don't actually want to delete player from library
      // as we want to keep the data to render game state
      // We simply want to kill the player
      // will be automatically removed by reset()
      if (!this.players[pid].isReady()) {
        delete this.players[pid]
      } else {
        this._killPlayer(pid)
      }
    }
  }

  this.setPlayerWord = function (pin, word) {
    // if (!this.isLobby) return    // Removed to permit hotjoins

    const player = this.players[pin]

    if (!player) return

    player.setWordAndReady(word)

    if (this.isLobby) {
      // Check number of players in lobby
      if (Object.keys(this.players).length < 2) return
  
      // If all players are ready, start the game
      const allReady = Object.values(this.players).reduce(
        (a, p) => a && p.isReady(),
        true,
      )
      if (allReady) {
        // Starting game process
        this._start()
      }
    } else {
      this.turnOrder.push(pin)
    }
  }

  this._start = function () {
    // Randomly generate turn order using keys in player map
    this.turnOrder = Object.keys(this.players) // assumes a list is returned
    shuffle(this.turnOrder)
    this.isLobby = false
  }

  this.guessLetter = function (letter) {
    if (this.isLobby || this.alphabet.didSet(letter) || this.checkGameOver())
      return

    this.alphabet.set(letter)

    // With this newly guessed letter, some players may die
    for (const pid in this.players) {
      const player = this.players[pid]
      if (player.isReady() && player.isAlive() && this.alphabet.canSpell(player.getWord()))
        this._killPlayer(pid)
    }

    const guesser = this._currentPlayer()
    if (!this.checkGameOver() && guesser.isAlive()) this._progressTurn()
  }

  this.currentPlayerPin = function () {
    return this.turnOrder[0]
  }

  this._currentPlayer = function () {
    return this.players[this.turnOrder[0]]
  }

  this.guessWord = function (pin, word) {
    if (this.isLobby || this.checkGameOver()) return

    const target = this.players[pin]
    const guesser = this._currentPlayer()

    if (!target.isAlive() || target.getPin() === guesser.getPin()) return

    if (word === target.getWord()) {
      if (target.isReady()) {
        this._killPlayer(target.getPin())
      }
    } else {
      if (guesser.isReady()) {
        this._killPlayer(guesser.getPin())
      }
    }

    if (!this.checkGameOver() && guesser.isAlive()) {
      this._progressTurn()
    }
  }

  this.checkGameOver = function () {
    let gameOver = true
    for (const pin in this.players) {
      const player = this.players[pin]
      if (pin !== this.currentPlayerPin() && player.isAlive()) gameOver = false
    }
    return gameOver
  }

  this.skipTurn = function () {
    this._progressTurn()
  }

  this._progressTurn = function () {
    // Let's hope this works
    const top = this.turnOrder.splice(0, 1)[0]
    this.turnOrder.push(top)
  }

  this.reset = function () {
    this.players = {}
    this.turnOrder = []
    this.alphabet = new Alphabet()
    this.isLobby = true
    this.log = []
  }
}
