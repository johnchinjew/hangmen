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
    const newPlayer = new Player(name)
    const session = this.sessions[sid]
    if (session) {
      session.addPlayer(newPlayer)
      return newPlayer.getId()
    }
    return undefined
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
