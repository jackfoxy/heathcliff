// MediaInfo runs off the UI thread. Closing the attributes tab stops this worker.
import mediaInfoFactory from './mediainfo.js';

const maximumBytes = 64 * 1024 * 1024;
const fieldLabels = [
  ['Format', 'Format'], ['Format profile', 'Format_Profile'],
  ['Codec', 'CodecID'], ['Codec description', 'CodecID_Hint'],
  ['Duration', 'Duration', 's'], ['Bit rate', 'BitRate', 'bit/s'],
  ['Overall bit rate', 'OverallBitRate', 'bit/s'],
  ['Bit rate mode', 'BitRate_Mode'], ['Width', 'Width', 'px'],
  ['Height', 'Height', 'px'], ['Frame rate', 'FrameRate', 'fps'],
  ['Frame count', 'FrameCount'], ['Channels', 'Channels'],
  ['Channel layout', 'ChannelLayout'], ['Sample rate', 'SamplingRate', 'Hz'],
  ['Bit depth', 'BitDepth', 'bits'], ['Color space', 'ColorSpace'],
  ['Chroma subsampling', 'ChromaSubsampling'], ['Compression', 'Compression_Mode'],
  ['Compression method', 'Format_Compression'], ['Stream size', 'StreamSize'],
  ['Scan type', 'ScanType'], ['Rotation', 'Rotation', '°'],
  ['Display aspect ratio', 'DisplayAspectRatio'], ['Language', 'Language'],
  ['Title', 'Title'], ['Encoder', 'Encoded_Library'],
  ['Format description', 'Format_Info'], ['Packing method', 'Format_Settings_Packing'],
  ['Pixel aspect ratio', 'PixelAspectRatio'], ['Endianness', 'Format_Settings_Endianness'],
  ['Sample representation', 'Format_Settings_Sign'], ['Sample count', 'SamplingCount'],
  ['Encoding application', 'Encoded_Application'], ['File size', 'FileSize']
];
const labels = new Map(fieldLabels.map(([label, key, unit]) => [key, {label, unit}]));
const bookkeeping = new Set([
  'Count', 'StreamCount', 'StreamKind', 'StreamKindID', 'StreamKindPos', 'StreamOrder'
]);

function trackFields(track, fileSize) {
  // Some codecs put additional attributes inside "extra". Keep those too.
  const values = Object.create(null);
  const collect = (object, prefix = '') => {
    for (const [key, value] of Object.entries(object)) {
      const name = prefix + key;
      if (value && typeof value === 'object' && !Array.isArray(value)) {
        collect(value, key === 'extra' ? prefix : name + '_');
      } else {
        values[name] = value;
      }
    }
  };
  collect(track);
  const populated = (value) => value !== undefined && value !== null && value !== ''
    && (!Array.isArray(value) || value.length > 0);
  const keys = [...new Set(Object.keys(values).map(key => key.replace(/_String\d*$/, '')))];
  return keys.flatMap(key => {
    if (key.startsWith('@') || bookkeeping.has(key)) return [];
    // Container summaries repeat the individual tracks below them.
    if (/^(Video|Audio|Text|Other|Image|Menu)_(Format(_WithHint)?|Codec|Language)_List$/.test(key)) return [];
    if (key.endsWith('_Proportion') && populated(values[key.slice(0, -11)])) return [];
    if (key === 'Format_Commercial' && values[key] === values.Format) return [];
    const alternatives = Object.keys(values).filter(name => name.replace(/_String\d*$/, '') === key);
    const fallback = alternatives.find(name => populated(values[name]));
    const raw = populated(values[key]) ? values[key] : values[fallback];
    if (!populated(raw)) return [];
    const words = key.replace(/_/g, ' ').replace(/([A-Z]+)([A-Z][a-z])/g, '$1 $2')
      .replace(/([a-z\d])([A-Z])/g, '$1 $2').toLowerCase();
    const {label = words[0].toUpperCase() + words.slice(1), unit} = labels.get(key) || {};
    if (/^(FileSize|(?:Source_)?StreamSize(?:_Encoded|_Demuxed)?)$/.test(key)
      && Number.isFinite(Number(raw)) && Number(raw) >= 0) {
      const bytes = Number(raw);
      const scale = bytes >= 1048576 ? 2 : bytes >= 1024 ? 1 : 0;
      const size = Number((bytes / 1024 ** scale).toFixed(2));
      const share = key !== 'FileSize' && fileSize
        ? ` (${Number((100 * bytes / fileSize).toFixed(2))}%)` : '';
      return [[label, `${size} ${['B', 'KiB', 'MiB'][scale]}${share}`]];
    }
    const value = unit && populated(values[key]) ? `${raw} ${unit}` :
      populated(values[key + '_String']) ? values[key + '_String'] : raw;
    return [[label, Array.isArray(value) ? value.map(item =>
      item && typeof item === 'object' ? JSON.stringify(item) : String(item)).join(', ') : String(value)]];
  });
}

self.onmessage = async ({data}) => {
  let inspector;
  try {
    const response = await fetch(data.url, {credentials: 'same-origin'});
    if (!response.ok) throw new Error(`File request failed (${response.status}).`);
    const reader = response.body.getReader();
    const chunks = [];
    let size = 0;
    for (;;) {
      const {value, done} = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > maximumBytes) {
        await reader.cancel();
        throw new Error('Metadata inspection is limited to files up to 64 MiB.');
      }
      chunks.push(value);
    }
    const blob = new Blob(chunks);
    inspector = await mediaInfoFactory({
      format: 'object', full: true, locateFile: () => './mediainfo.wasm'
    });
    const result = await inspector.analyzeData(blob.size, async (length, offset) => {
      return new Uint8Array(await blob.slice(offset, offset + length).arrayBuffer());
    });
    const groups = (result.media?.track || []).map((track) => ({
      title: track['@type'] === 'General' ? 'Container' :
        `${track['@type']}${track.StreamOrder !== undefined ? ` ${track.StreamOrder}` : ''}`,
      fields: trackFields(track, blob.size)
    })).filter((group) => group.fields.length);
    self.postMessage({groups});
  } catch (cause) {
    self.postMessage({error: cause.message || 'Unable to inspect this file.'});
  } finally {
    inspector?.close();
  }
};
