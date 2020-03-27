import { v4 as uuidv4 } from 'uuid';

export function Session() {
    this.id = uuidv4()
    this.players = {}
    this.alphabet = Alphabet()
    this.turn = 0
    this.lobby = true

    this.getId = function () {
        return this.id
    }

    this.getPlayer = function (pid) {
        return this.players[pid]
    }

    this.addPlayer = function (player) {
        this.players[player.getId()] = player
    }

    this.isLobby = function () {
        return this.lobby
    }

    this.setLetter = function(letter) {
        this.alphabet.setLetter(letter)
    }

    this.isLetterSet = function(letter) {
        return this.alphabet.isLetterSet()
    }

    this.resetAlphabet = function() {
        this.alphabet = Alphabet()
    }

}

