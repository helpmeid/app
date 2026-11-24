"""Build eight original, opaque 1024px iOS icons with the Python standard library."""
import json, struct, zlib
from pathlib import Path
root = Path(__file__).resolve().parent / "Assets.xcassets"
root.mkdir(exist_ok=True)
(root / "Contents.json").write_text(json.dumps({"info":{"author":"xcode","version":1}}))
colors = [(0,122,255),(255,151,36),(35,43,91),(22,126,190),(220,66,61),(123,74,199),(30,155,112),(43,56,75)]
def chunk(t,d):
    return struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d)&0xffffffff)
def draw(base,idx):
    rows=[]
    for y in range(1024):
        row=bytearray([0])
        for x in range(1024):
            # Oval speech mark and tail.
            bubble=((x-512)/320)**2+((y-470)/260)**2<=1
            tail=560<=y<=745 and 300<=x<=465 and x<=465-(y-560)*0.60
            if bubble or tail:
                dots=any((x-cx)**2+(y-470)**2<29**2 for cx in (390,512,634))
                rgb=base if dots else (255,255,255)
            else:
                rgb=tuple(max(0,min(255,int(v*(1.12-y/1024*.23)))) for v in base)
            row.extend(rgb)
        rows.append(row)
    data=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",1024,1024,8,2,0,0,0))+chunk(b"IDAT",zlib.compress(b"".join(rows),9))+chunk(b"IEND",b"")
    name="AppIcon" if idx==0 else f"Icon{idx}"
    folder=root/(name+".appiconset")
    folder.mkdir(exist_ok=True)
    (folder/"icon.png").write_bytes(data)
    (folder/"Contents.json").write_text(json.dumps({"images":[{"filename":"icon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}))
for idx,base in enumerate(colors):
    draw(base,idx)
