import { Session } from './session.js'

export function SessionManager() {
  this.sessions = {}

  this.createSession = function() {
    const newSession = new Session()
    const newId = newSession.getId()
    this.sessions[newId] = newSession
    return newId
  }

  this.getSession = function(sid) {
    return this.sessions[sid]
  }
}
