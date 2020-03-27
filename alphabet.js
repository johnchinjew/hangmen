export function Alphabet() {
  this.letters = {}

  for (const letter of 'abcdefghjiklmnopqrstuvwxyz') {
    this.letters[letter] = false
  }

  this.value = function(letter) {
    return this.letters[letter]
  }

  this.set = function(letter) {
    this.letters[letter] = true
  }
}
