import uuid from 'uuid'
import { Player } from './player.js'
import { Alphabet } from './alphabet.js'

/**
 * Shuffles array in place.
 * @param {Array} a items An array containing the items.
 */
function shuffle(a) {
  var j, x, i;
  for (i = a.length - 1; i > 0; i--) {
      j = Math.floor(Math.random() * (i + 1));
      x = a[i];
      a[i] = a[j];
      a[j] = x;
  }
  return a;
}

export function Session() {
  this.id = uuid.v4()
  this.players = {}
  this.turnOrder = []
  this.alphabet = new Alphabet()
  this.isLobby = true

  this.getId = function() {
    return this.id
  }

  this.addPlayer = function(name) {
    const newPlayer = new Player(name)
    if (!this.isLobby) {
      newPlayer.isAlive = false
    }
    const newId = newPlayer.getId()
    this.players[newId] = newPlayer
    return newId
  }

  const killPlayer = function(pid) {
    this.players[pid].kill()
    const turn = this.turnOrder.indexOf(pid)
    if (turn > -1) {
      this.turnOrder.splice(turn, 1)
    }
  }

  this.removePlayer = function(pid) {
    if (!(pid in this.players)) {
      return 
    }

    delete this.players[pid] 
    killPlayer(pid)
  }

  this.setPlayerWord = function(pid, word) {
    if (!this.isLobby)
      return

    const player = this.players[pid]

    if (!player)
      return

    player.setWordAndReady(word)
    
    // Check number of players in lobby
    if (Object.keys(this.players).length < 2)
      return 
    
    // If all players are ready, start the game
    const allReady = Object.values(this.players).reduce((a, p) => a && p.isReady() , true)
    if (allReady) {
      // Starting game process
      this.turnOrder = Object.keys(this.players)  // assumes a list is returned 
      shuffle(this.turnOrder)
      this.isLobby = false
    }
  }

  this.guessLetter = function(letter) {
    if (this.isLobby || this.alphabet.didSet(letter))
      return

    this.alphabet.set(letter)
    
    // With this newly guessed letter, some players may die
    for (const pid of this.players) {
      const player = this.players[pid]
      if (player.isAlive() && this.alphabet.canSpell(player.getWord())) {
        killPlayer(pid)
      }            
    }

    if (checkGameOver()) {
      progressTurn()
    }
  }

  const currentPlayer = function() {
    return this.players[this.turnOrder[0]]
  }

  this.guessWord = function(pid, word) {
    if (this.isLobby || !player.isAlive())
      return

    const target = this.players[pid]
    const guesser = currentPlayer()
    
    if (word === target.getWord()) 
      killPlayer(target.getId())
    else
      killPlayer(guesser.getId())

    if (checkGameOver()) {
      progressTurn()
    }
  }

  const checkGameOver = function() {
    let gameOver = true
    for (const pid of this.players) {
      const player = this.players[pid]
      if (pid !== this.turnOrder[0] && player.isAlive())
        gameOver = false
    }
    return gameOver
  }

  const progressTurn = function() {    
    // Let's hope this works
    const top = this.turnOrder.splice(0, 1)[0]
    this.turnOrder.push(top)
  }

  this.reset = function() {
    this.players = {}
    this.turnOrder = []
    this.alphabet = new Alphabet()
    this.isLobby = true
  }
}
