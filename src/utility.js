import uuid from 'uuid';
import sha256 from 'crypto-js/sha256.js';
import Base64 from 'crypto-js/enc-base64.js';

export function alphanumId() {
  const length = 6;
  let id;
  do {
    id = Base64
          .stringify(sha256(uuid.v4()))
          .replace(/\W/g, '')
          .slice(0, length)
  } while (id.length < length)
  return id;
}
