const crypto = require('crypto')

// Random lowercase alphanumeric 6 character string
function alphanumId() {
    return parseInt(crypto.randomBytes(8).toString('hex'), 16).toString(36).slice(0, 6)
}
