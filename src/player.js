import uuid from 'uuid'

export function Player(name) {
  this.id = uuid.v4()
  this.name = name
  this.word = ""
  this.isReady = false
  this.isAlive = true

  this.getId = function() {
    return this.id
  }

  this.getWord = function() {
    return this.word
  }

  this.isReady = function() {
    return this.isReady
  }

  this.isAlive = function() {
    return this.isAlive
  }

  this.setWordAndReady = function(word) {
    this.word = word
    this.ready = true
  }

  this.kill = function() {
    this.isAlive = false
  }
}
