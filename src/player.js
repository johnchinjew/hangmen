import { v4 as uuidv4 } from 'uuid';

export function Player(name) {
    this.id = uuidv4()
    this.name = name
    this.word = ""
    this.ready = false
    this.alive = false

    this.getId = function () {
        return this.id
    }

    this.toggleReady = function () {
        this.ready = !this.ready
    }
}