export function Alphabet() {
  this.letters = {}

  const allLetters = 'abcdefghjiklmnopqrstuvwxyz'

  for (const letter of allLetters) {
    this.letters[letter] = false
  }

  this.didSet = function(letter) {
    return this.letters[letter]
  }

  this.set = function(letter) {
    this.letters[letter] = true
  }

  this.canSpell = function(word) {
    return word.split('').reduce((a, c) => a && this.didSet(c), true) 
  }
}
