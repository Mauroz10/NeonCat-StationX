"""Comprueba la orientación REAL de la actividad del APK, sin librerías externas."""
import struct
import sys
import zipfile

def read_strings(data, base):
    header, total = struct.unpack_from('<HI', data, base + 2)
    count, _, flags, start, _ = struct.unpack_from('<5I', data, base + 8)
    offsets = struct.unpack_from('<' + 'I' * count, data, base + header)
    def length(pos, wide=False):
        if wide:
            n = struct.unpack_from('<H', data, pos)[0];pos += 2
            if n & 0x8000:
                n = ((n & 0x7fff) << 16) | struct.unpack_from('<H', data, pos)[0];pos += 2
        else:
            n = data[pos];pos += 1
            if n & 0x80:n = ((n & 0x7f) << 8) | data[pos];pos += 1
        return n, pos
    strings = []
    for off in offsets:
        pos = base + start + off
        if flags & 0x100:
            _, pos = length(pos)
            size, pos = length(pos)
            strings.append(data[pos:pos+size].decode('utf8'))
        else:
            size, pos = length(pos, True)
            strings.append(data[pos:pos+size*2].decode('utf-16le'))
    return strings

def verify(path):
    with zipfile.ZipFile(path) as z:
        data = z.read('AndroidManifest.xml')
        assert z.testzip() is None, 'ZIP corrupto'
    strings=[];found=False;pos=8
    while pos < len(data):
        kind, header, size = struct.unpack_from('<HHI', data, pos)
        assert size >= 8, 'AXML inválido'
        if kind == 1: strings = read_strings(data, pos)
        elif kind == 0x102:
            ext = pos + header
            _, tag, attr_start, attr_size, count = struct.unpack_from('<IIHHH', data, ext)
            attrs={}
            for i in range(count):
                at = ext + attr_start + i * attr_size
                _, name, raw = struct.unpack_from('<III',data,at)
                typ = data[at+15];value = struct.unpack_from('<I',data,at+16)[0]
                attrs[strings[name]] = strings[value] if typ == 3 else value
            if strings[tag] == 'activity' and attrs.get('name') == 'com.godot.game.GodotApp':
                assert attrs.get('screenOrientation') == 0, 'APK NO está fijado en horizontal: '+str(attrs)
                found=True
        pos += size
    assert found, 'No se encontró la actividad del juego'
    print('OK: APK íntegro y actividad Godot en horizontal (landscape=0).')
if __name__ == '__main__':verify(sys.argv[1])
