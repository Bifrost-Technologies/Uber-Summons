// Read raw ZIP headers: archive libraries may silently normalize invalid separators.
const fs = require('node:fs');
const zlib = require('node:zlib');
const assert = require('node:assert/strict');
const b = fs.readFileSync(process.argv[2]);
const root = process.argv[3] || 'Uber';
assert(/^[A-Za-z][A-Za-z_0-9]*$/.test(root), 'Invalid addon root');
const entryPattern = new RegExp('^'+root+'/[A-Za-z_][A-Za-z_0-9.\\-]*$');
const u16 = n => b.readUInt16LE(n), u32 = n => b.readUInt32LE(n);
let end = -1;
for (let n = b.length - 22; n >= Math.max(0, b.length - 65557); n--) {
  if (u32(n) === 0x06054b50 && n + 22 + u16(n + 20) === b.length) {end = n; break;}
}
assert(end >= 0, 'Missing end-of-central-directory');
assert.equal(u16(end + 4), 0, 'Multi-disk ZIP unsupported');
assert.equal(u16(end + 6), 0);
assert.equal(u16(end + 8), u16(end + 10));
let pos = u32(end + 16);
const start = pos, count = u16(end + 10), names = new Set();
assert(count > 0, 'Empty archive');
function crc32(data) {
  let crc = 0xffffffff;
  for (const byte of data) {
    crc ^= byte;
    for (let i = 0; i < 8; i++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
for (let i = 0; i < count; i++) {
  assert.equal(u32(pos), 0x02014b50, 'Invalid central header');
  const flags = u16(pos + 8), method = u16(pos + 10), crc = u32(pos + 16);
  const packed = u32(pos + 20), size = u32(pos + 24), nlen = u16(pos + 28);
  const rawName = b.subarray(pos + 46, pos + 46 + nlen);
  const name = rawName.toString('utf8');
  assert(entryPattern.test(name), `Non-portable ZIP path: ${name}`);
  assert(!names.has(name.toLowerCase()), `Duplicate path: ${name}`); names.add(name.toLowerCase());
  assert.equal(flags & 1, 0, 'Encrypted ZIP unsupported');
  assert(method === 0 || method === 8, 'Unsupported compression');
  const local = u32(pos + 42);
  assert.equal(u32(local), 0x04034b50, 'Invalid local header');
  assert.equal(u16(local + 6), flags); assert.equal(u16(local + 8), method);
  assert(b.subarray(local + 30, local + 30 + u16(local + 26)).equals(rawName), 'Local/central name mismatch');
  const dataAt = local + 30 + u16(local + 26) + u16(local + 28);
  assert(dataAt + packed <= start, 'Entry overlaps central directory');
  const compressed = b.subarray(dataAt, dataAt + packed);
  const data = method === 8 ? zlib.inflateRawSync(compressed, {maxOutputLength: 10485760}) : compressed;
  assert.equal(data.length, size, `Size mismatch: ${name}`);
  assert.equal(crc32(data), crc, `CRC mismatch: ${name}`);
  pos += 46 + nlen + u16(pos + 30) + u16(pos + 32);
}
assert.equal(pos, start + u32(end + 12), 'Central directory length mismatch');
assert.equal(pos, end, 'Unexpected trailing central data');
assert(names.has((root+'/'+root+'.toc').toLowerCase()), 'Missing main TOC');
console.log(`PASS: ${count} raw ZIP paths, local headers, decompression and CRC checks`);
