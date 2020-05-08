import uuid from 'uuid'

export function Player(name) {
  this.id = uuid.v4()
  this.name = name
  this.word = ""
  this.ready = false
  this.alive = true

  this.getId = function() {
    return this.id
  }

  this.getWord = function() {
    return this.word
  }

  this.isReady = function() {
    return this.ready
  }

  this.isAlive = function() {
    return this.alive
  }

  this.setWordAndReady = function(word) {
    this.word = word
    this.ready = true
  }

  this.kill = function() {
    this.alive = false
  }
}
