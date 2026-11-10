"""Sintetiza una base rítmica (trap oscuro, 140 BPM) y un whoosh.
Uso: python3 scripts/synth-audio.py  (escribe en public/music y public/sfx)"""
import math, random, struct, wave

SR = 44100
random.seed(7)

def write(path, left, right=None):
    right = right or left
    peak = max(1e-9, max(max(abs(x) for x in left), max(abs(x) for x in right)))
    g = 0.89 / peak
    with wave.open(path, 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<hh', int(l * g * 32767), int(r * g * 32767)) for l, r in zip(left, right)))

def add(buf, start, samples, gain=1.0):
    i0 = int(start * SR)
    for i, s in enumerate(samples):
        if 0 <= i0 + i < len(buf): buf[i0 + i] += s * gain

def kick():
    n = int(0.45 * SR); out = []; ph = 0
    for i in range(n):
        t = i / SR; f = 40 + 110 * math.exp(-t * 28); ph += 2 * math.pi * f / SR
        out.append(math.sin(ph) * math.exp(-t * 6) + (random.uniform(-1, 1) * math.exp(-t * 300) * 0.3))
    return out

def hat(dur=0.05):
    n = int(dur * SR); prev = 0; out = []
    for i in range(n):
        x = random.uniform(-1, 1); hp = x - prev; prev = x
        out.append(hp * math.exp(-i / SR * 70))
    return out

def snare():
    n = int(0.25 * SR); out = []
    for i in range(n):
        t = i / SR
        out.append(random.uniform(-1, 1) * math.exp(-t * 18) * 0.8 + math.sin(2 * math.pi * 190 * t) * math.exp(-t * 25) * 0.5)
    return out

def sub(freq, dur):
    n = int(dur * SR); out = []
    for i in range(n):
        t = i / SR; env = min(1, t / 0.01) * math.exp(-t * 1.2)
        s = math.sin(2 * math.pi * freq * t); out.append(math.tanh(s * 2.2) * env)
    return out

def pad(freqs, dur):
    n = int(dur * SR); out = []
    for i in range(n):
        t = i / SR; env = min(1, t / 0.8) * min(1, (dur - t) / 0.8)
        out.append(sum(math.sin(2 * math.pi * f * t + math.sin(t * 0.7 + k)) for k, f in enumerate(freqs)) / len(freqs) * env)
    return out

LEN = 27.5
L = [0.0] * int(LEN * SR); R = [0.0] * int(LEN * SR)
beat = 60 / 140
DROP = 9.0  # el golpe fuerte coincide con la revelación del producto

# Intro (0–9 s): pad oscuro + hats suaves que crecen
for buf in (L, R):
    add(buf, 0, pad([55, 82.4, 110, 164.8], DROP + 0.2), 0.22)
t = 2.0
while t < DROP - 0.1:
    g = 0.05 + 0.10 * (t / DROP)
    add(L, t, hat(), g); add(R, t + 0.003, hat(), g)
    t += beat / 2
# Redoble antes del drop
for k in range(8):
    tt = DROP - 1.0 + k * (1.0 / 8)
    for buf in (L, R): add(buf, tt, snare(), 0.15 + k * 0.04)

# Drop (9–24 s): kick, snare, hats en semicorcheas y 808
notes = [55, 55, 65.4, 49]  # La, La, Do, Sol
bar = beat * 4; t = DROP; bar_i = 0
while t < 26.0:
    f = notes[bar_i % len(notes)]
    for buf in (L, R):
        add(buf, t, kick(), 0.9); add(buf, t + beat * 2.5, kick(), 0.7)
        add(buf, t + beat, snare(), 0.45); add(buf, t + beat * 3, snare(), 0.45)
        add(buf, t, sub(f, bar * 0.95), 0.55)
        add(buf, t, pad([f * 2, f * 3, f * 4], bar), 0.08)
    for k in range(16):
        g = 0.12 if k % 2 == 0 else 0.07
        add(L, t + k * beat / 4, hat(0.035), g); add(R, t + k * beat / 4 + 0.004, hat(0.035), g)
    t += bar; bar_i += 1

# Final: fundido
n = len(L); fade0 = int(25.6 * SR)
for i in range(fade0, n):
    g = max(0.0, 1 - (i - fade0) / (n - fade0)); L[i] *= g; R[i] *= g
write('public/music/beat.wav', L, R)

# Whoosh: ruido filtrado con barrido
n = int(0.9 * SR); out = []; y = 0
for i in range(n):
    t = i / SR; a = 0.02 + 0.5 * math.sin(math.pi * t / 0.9) ** 2
    y += a * (random.uniform(-1, 1) - y)
    out.append(y * math.sin(math.pi * t / 0.9) ** 1.5)
write('public/sfx/whoosh.wav', out, out[::-1] + [] if False else out)
print('ok')
