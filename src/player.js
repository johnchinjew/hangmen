import { pin } from './pin.js'

export function Player(pin, name) {
  this.pin = pin
  this.name = name
  this.word = ""
  this.ready = false
  this.alive = true

  this.getPin = function () {
    return this.pin
  }

  this.getWord = function () {
    return this.word
  }

  this.isReady = function () {
    return this.ready
  }

  this.isAlive = function () {
    return this.alive
  }

  this.setWordAndReady = function (word) {
    this.word = word
    this.ready = true
  }

  this.kill = function () {
    this.alive = false
  }
}
