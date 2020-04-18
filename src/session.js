import uuid from 'uuid'
import { Player } from './player.js'
import { Alphabet } from './alphabet.js'

export function Session() {
  this.id = uuid.v4()
  this.players = {}
  this.alphabet = new Alphabet()
  this.isLobby = true
  this.turn = 0

  this.getId = function() {
    return this.id
  }

  this.addPlayer = function(name) {
    const newPlayer = new Player(name)
    const newId = newPlayer.getId()
    this.players[newId] = newPlayer
    return newId
  }

  this.setPlayerWord = function(pid, word) {
    if (!this.isLobby)
      return

    const player = this.players[pid]

    if (!player)
      return

    player.setWordAndReady(word)
    
    // If all players are ready, start the game
    const allReady = this.players.reduce((a, p) => a && p.isReady(), true)
    if (allReady) {
      this.isLobby = false
    }
  }

  this.guessLetter = function(letter) {
    if (this.isLobby || this.alphabet.didSet(letter))
      return

    this.alphabet.set(letter)
    
    // With this newly guessed letter, some players may die
    for (const player of this.players) {
      if (player.isAlive() && this.alphabet.canSpell(player.getWord())) {
        player.kill()
      }            
    }

    // How are turns implemented
    this.turn++
  }

  const currentPlayer = function() {
    const ids = Object.keys(this.players)
    ids.sort()
    const currentId = ids[this.turn]
    return this.players[currentId]
  }

  this.guessWord = function(pid, word) {
    if (this.isLobby || !player.isAlive())
      return

    const target = this.players[pid]
    const guesser = currentPlayer()
    
    if (word === target.getWord()) 
      target.kill()
    else
      guesser.kill()
  }

  this.start = function() {
    // (Randomly?) initialize player turn

  }

  this.reset = function() {
    this.alphabet = new Alphabet()
  }
}
