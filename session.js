import uuid from 'uuid'
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

  this.getPlayer = function(pid) {
    return this.players[pid]
  }

  this.getAlphabet = function() {
    return this.alphabet
  }

  this.isLobby = function() {
    return this.isLobby
  }

  this.addPlayer = function(player) {
    this.players[player.getId()] = player
  }

  this.reset = function() {
    this.alphabet = new Alphabet()
  }
}
