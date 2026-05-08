/**
 * 纯 ArkTS 实现 SHA-256 / SHA-512 / HMAC
 * 不依赖系统 cryptoFramework，同步调用
 */

// ─── SHA-256 ────────────────────────────────────────

const SHA256_K: number[] = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
  0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
  0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
  0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
  0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
  0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

const SHA256_H0: number[] = [
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
]

function rotr32(x: number, n: number): number {
  return ((x >>> n) | (x << (32 - n))) >>> 0
}

function sha256Digest(msg: Uint8Array): Uint8Array {
  // Padding
  const bitLen = msg.length * 8
  const padLen = msg.length % 64 < 56 ? 64 - msg.length % 64 - 9 : 128 - msg.length % 64 - 1
  const padded = new Uint8Array(msg.length + 1 + padLen + 8)
  padded.set(msg)
  padded[msg.length] = 0x80
  // Big-endian 64-bit length
  const view = new DataView(padded.buffer)
  view.setUint32(padded.length - 4, bitLen, false)

  // Init hash
  const h = SHA256_H0.slice()

  // Process each 64-byte block
  for (let offset = 0; offset < padded.length; offset += 64) {
    const w: number[] = new Array(64)
    for (let i = 0; i < 16; i++) {
      w[i] = view.getUint32(offset + i * 4, false)
    }
    for (let i = 16; i < 64; i++) {
      const s0 = rotr32(w[i - 15], 7) ^ rotr32(w[i - 15], 18) ^ (w[i - 15] >>> 3)
      const s1 = rotr32(w[i - 2], 17) ^ rotr32(w[i - 2], 19) ^ (w[i - 2] >>> 10)
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) | 0
    }

    let a = h[0], b = h[1], c = h[2], d = h[3]
    let e = h[4], f = h[5], g = h[6], hh = h[7]

    for (let i = 0; i < 64; i++) {
      const S1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25)
      const ch = (e & f) ^ (~e & g)
      const temp1 = (hh + S1 + ch + SHA256_K[i] + w[i]) | 0
      const S0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22)
      const maj = (a & b) ^ (a & c) ^ (b & c)
      const temp2 = (S0 + maj) | 0
      hh = g; g = f; f = e
      e = (d + temp1) | 0
      d = c; c = b; b = a
      a = (temp1 + temp2) | 0
    }

    h[0] = (h[0] + a) | 0; h[1] = (h[1] + b) | 0
    h[2] = (h[2] + c) | 0; h[3] = (h[3] + d) | 0
    h[4] = (h[4] + e) | 0; h[5] = (h[5] + f) | 0
    h[6] = (h[6] + g) | 0; h[7] = (h[7] + hh) | 0
  }

  const out = new Uint8Array(32)
  const ov = new DataView(out.buffer)
  for (let i = 0; i < 8; i++) {
    ov.setUint32(i * 4, h[i], false)
  }
  return out
}

// ─── SHA-512 (64-bit simulation: [hi, lo] pairs) ────

function makeU64(hi: number, lo: number): number[] { return [hi >>> 0, lo >>> 0] }

function add64(a: number[], b: number[]): number[] {
  const loSum = a[1] + b[1]
  return [(a[0] + b[0] + (loSum > 0xFFFFFFFF ? 1 : 0)) >>> 0, loSum >>> 0]
}

function xor64(a: number[], b: number[]): number[] {
  return [(a[0] ^ b[0]) >>> 0, (a[1] ^ b[1]) >>> 0]
}

function and64(a: number[], b: number[]): number[] {
  return [(a[0] & b[0]) >>> 0, (a[1] & b[1]) >>> 0]
}

function not64(a: number[]): number[] {
  return [(~a[0]) >>> 0, (~a[1]) >>> 0]
}

function shr64(a: number[], n: number): number[] {
  if (n < 32) return [(a[0] >>> n) >>> 0, ((a[0] << (32 - n)) | (a[1] >>> n)) >>> 0]
  return [0, (a[0] >>> (n - 32)) >>> 0]
}

function shl64(a: number[], n: number): number[] {
  if (n < 32) return [((a[0] << n) | (a[1] >>> (32 - n))) >>> 0, (a[1] << n) >>> 0]
  return [(a[1] << (n - 32)) >>> 0, 0]
}

function rotr64(a: number[], n: number): number[] {
  return xor64(shr64(a, n), shl64(a, 64 - n))
}

function hexToU64(hex: string): number[] {
  return [parseInt(hex.substring(0, 8), 16), parseInt(hex.substring(8), 16)]
}

const SHA512_K_HEX: string[] = [
  '428a2f98d728ae22', '7137449123ef65cd', 'b5c0fbcfec4d3b2f', 'e9b5dba58189dbbc',
  '3956c25bf348b538', '59f111f1b605d019', '923f82a4af194f9b', 'ab1c5ed5da6d8118',
  'd807aa98a3030242', '12835b0145706fbe', '243185be4ee4b28c', '550c7dc3d5ffb4e2',
  '72be5d74f27b896f', '80deb1fe3b1696b1', '9bdc06a725c71235', 'c19bf174cf692694',
  'e49b69c19ef14ad2', 'efbe4786384f25e3', '0fc19dc68b8cd5b5', '240ca1cc77ac9c65',
  '2de92c6f592b0275', '4a7484aa6ea6e483', '5cb0a9dcbd41fbd4', '76f988da831153b5',
  '983e5152ee66dfab', 'a831c66d2db43210', 'b00327c898fb213f', 'bf597fc7beef0ee4',
  'c6e00bf33da88fc2', 'd5a79147930aa725', '06ca6351e003826f', '142929670a0e6e70',
  '27b70a8546d22ffc', '2e1b21385c26c926', '4d2c6dfc5ac42aed', '53380d139d95b3df',
  '650a73548baf63de', '766a0abb3c77b2a8', '81c2c92e47edaee6', '92722c851482353b',
  'a2bfe8a14cf10364', 'a81a664bbc423001', 'c24b8b70d0f89791', 'c76c51a30654be30',
  'd192e819d6ef5218', 'd69906245565a910', 'f40e35855771202a', '106aa07032bbd1b8',
  '19a4c116b8d2d0c8', '1e376c085141ab53', '2748774cdf8eeb99', '34b0bcb5e19b48a8',
  '391c0cb3c5c95a63', '4ed8aa4ae3418acb', '5b9cca4f7763e373', '682e6ff3d6b2b8a3',
  '748f82ee5defb2fc', '78a5636f43172f60', '84c87814a1f0ab72', '8cc702081a6439ec',
  '90befffa23631e28', 'a4506cebde82bde9', 'bef9a3f7b2c67915', 'c67178f2e372532b',
  'ca273eceea26619c', 'd186b8c721c0c207', 'eada7dd6cde0eb1e', 'f57d4f7fee6ed178',
  '06f067aa72176fba', '0a637dc5a2c898a6', '113f9804bef90dae', '1b710b35131c471b',
  '28db77f523047d84', '32caab7b40c72493', '3c9ebe0a15c9bebc', '431d67c49c100d4c',
  '4cc5d4becb3e42b6', '597f299cfc657e2a', '5fcb6fab3ad6faec', '6c44198c4a475817'
]

const SHA512_H0_HEX: string[] = [
  '6a09e667f3bcc908', 'bb67ae8584caa73b', '3c6ef372fe94f82b', 'a54ff53a5f1d36f1',
  '510e527fade682d1', '9b05688c2b3e6c1f', '1f83d9abfb41bd6b', '5be0cd19137e2179'
]

const SHA512_K: number[][] = SHA512_K_HEX.map((h: string) => hexToU64(h))
const SHA512_H0: number[][] = SHA512_H0_HEX.map((h: string) => hexToU64(h))

function sha512Digest(msg: Uint8Array): Uint8Array {
  const bitLen = msg.length * 8
  const padLen = msg.length % 128 < 112 ? 128 - msg.length % 128 - 17 : 256 - msg.length % 128 - 1
  const padded = new Uint8Array(msg.length + 1 + padLen + 16)
  padded.set(msg)
  padded[msg.length] = 0x80
  const view = new DataView(padded.buffer)
  // Big-endian 128-bit length (we only use lower 64 bits)
  view.setUint32(padded.length - 4, bitLen, false)
  view.setUint32(padded.length - 8, bitLen / 0x100000000, false)

  const h: number[][] = SHA512_H0.map((v: number[]) => [v[0], v[1]])

  for (let offset = 0; offset < padded.length; offset += 128) {
    const w: number[][] = new Array(80)
    for (let i = 0; i < 16; i++) {
      w[i] = [view.getUint32(offset + i * 8, false), view.getUint32(offset + i * 8 + 4, false)]
    }
    for (let i = 16; i < 80; i++) {
      const s0 = xor64(xor64(rotr64(w[i - 15], 1), rotr64(w[i - 15], 8)), shr64(w[i - 15], 7))
      const s1 = xor64(xor64(rotr64(w[i - 2], 19), rotr64(w[i - 2], 61)), shr64(w[i - 2], 6))
      w[i] = add64(add64(add64(w[i - 16], s0), w[i - 7]), s1)
    }

    let a = [h[0][0], h[0][1]], b = [h[1][0], h[1][1]]
    let c = [h[2][0], h[2][1]], d = [h[3][0], h[3][1]]
    let e = [h[4][0], h[4][1]], f = [h[5][0], h[5][1]]
    let g = [h[6][0], h[6][1]], hh = [h[7][0], h[7][1]]

    for (let i = 0; i < 80; i++) {
      const S1 = xor64(xor64(rotr64(e, 14), rotr64(e, 18)), rotr64(e, 41))
      const ch = xor64(and64(e, f), and64(not64(e), g))
      const temp1 = add64(add64(add64(add64(hh, S1), ch), SHA512_K[i]), w[i])
      const S0 = xor64(xor64(rotr64(a, 28), rotr64(a, 34)), rotr64(a, 39))
      const maj = xor64(xor64(and64(a, b), and64(a, c)), and64(b, c))
      const temp2 = add64(S0, maj)
      hh = g; g = f; f = e
      e = add64(d, temp1)
      d = c; c = b; b = a
      a = add64(temp1, temp2)
    }

    h[0] = add64(h[0], a); h[1] = add64(h[1], b)
    h[2] = add64(h[2], c); h[3] = add64(h[3], d)
    h[4] = add64(h[4], e); h[5] = add64(h[5], f)
    h[6] = add64(h[6], g); h[7] = add64(h[7], hh)
  }

  const out = new Uint8Array(64)
  const ov = new DataView(out.buffer)
  for (let i = 0; i < 8; i++) {
    ov.setUint32(i * 8, h[i][0], false)
    ov.setUint32(i * 8 + 4, h[i][1], false)
  }
  return out
}

// ─── HMAC ───────────────────────────────────────────

function hmacDigest(hashFn: (data: Uint8Array) => Uint8Array, blockSize: number,
  key: Uint8Array, data: Uint8Array): Uint8Array {
  // Pad or hash key to blockSize
  let k: Uint8Array
  if (key.length > blockSize) {
    k = hashFn(key)
    const padded = new Uint8Array(blockSize)
    padded.set(k)
    k = padded
  } else {
    const padded = new Uint8Array(blockSize)
    padded.set(key)
    k = padded
  }

  // ipad = key ^ 0x36, opad = key ^ 0x5c
  const ipad = new Uint8Array(blockSize)
  const opad = new Uint8Array(blockSize)
  for (let i = 0; i < blockSize; i++) {
    ipad[i] = k[i] ^ 0x36
    opad[i] = k[i] ^ 0x5c
  }

  // inner = H(ipad || data)
  const inner = new Uint8Array(blockSize + data.length)
  inner.set(ipad)
  inner.set(data, blockSize)
  const innerHash = hashFn(inner)

  // outer = H(opad || innerHash)
  const outer = new Uint8Array(blockSize + innerHash.length)
  outer.set(opad)
  outer.set(innerHash, blockSize)
  return hashFn(outer)
}

// ─── 导出 ────────────────────────────────────────────

export class PureCrypto {
  /** HMAC-SHA256，返回原始字节 */
  static hmacSha256Bytes(key: Uint8Array, data: Uint8Array): Uint8Array {
    return hmacDigest(sha256Digest, 64, key, data)
  }

  /** HMAC-SHA512，返回原始字节 */
  static hmacSha512Bytes(key: Uint8Array, data: Uint8Array): Uint8Array {
    return hmacDigest(sha512Digest, 128, key, data)
  }
}
