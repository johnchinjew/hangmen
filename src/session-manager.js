import { Session } from './session.js'

export function SessionManager() {
  this.sessions = {}

  this.createSession = function () {
    const newSession = new Session()
    const newPin = newSession.getPin()
    this.sessions[newPin] = newSession
    return newPin
  }

  this.getSession = function (pin) {
    return this.sessions[pin]
  }
}
