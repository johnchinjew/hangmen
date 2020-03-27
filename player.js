import uuid from 'uuid'

export function Player(name) {
  this.id = uuid.v4()
  this.name = name
  this.word = ""
  this.ready = false
  this.alive = false

  this.getId = function() {
    return this.id
  }

  this.toggleReady = function() {
    this.ready = !this.ready
  }
}
