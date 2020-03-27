import { Player } from './player.js'
import { Session } from './session.js'
import { Alphabet } from './alphabet.js'

export function SessionManager() {
  this.sessions = {}

  this.createSession = function() {
    const newSession = new Session()
    this.sessions[newSession.getId()] = newSession
    return newSession.getId()
  }

  this.addPlayer = function(sid, name) {
    const newPlayer = new Session(name)
    this.sessions[sid].addPlayer(newPlayer)
    return newPlayer.getId()
  }

  this.getSession = function(sid) {
    return this.sessions[sid]
  }

  this.setPlayerWord = function(sid, pid, word) {
  }

  this.guessLetter = function(sid, letter) {
  }

  this.guessPlayerWord = function(sid, pid, word) {
  }
}
