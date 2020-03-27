export function Alphabet() {
    this.alphabet = {}
    
    for (const letter of 'abcdefghjiklmnopqrstuvwxyz') {
        this.alphabet[letter] = 0
    }

    this.setLetter = function(letter) {
        this.letters[letter] = 1
    }

    this.isLetterSet = function(letter) {
        return this.letters[letter] == 1
    }
}
