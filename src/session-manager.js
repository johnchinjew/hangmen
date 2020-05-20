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

  this.releaseSessions = function() {
  	console.log("Cleaning up unused sessions...")
		for (const pin in this.sessions) {
			const session = this.sessions[pin]
			if (Object.keys(session.players).length == 0) {
        console.log("Deleting session", pin)
        console.log("State:", session)
				delete this.sessions[pin]
			}
		}
	}
}
