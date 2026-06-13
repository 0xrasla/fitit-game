#!/usr/bin/env python3
"""Generate retro 8-bit style sound effects for Color Match Rush."""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 11025  # Low sample rate for authentic 8-bit feel
MAX_AMP = 127        # 8-bit signed range


def to_bytes(samples):
    """Convert float samples [-1, 1] to 8-bit signed PCM bytes."""
    data = bytearray()
    for s in samples:
        val = int(max(-1, min(1, s)) * MAX_AMP)
        data.append(struct.pack('b', val)[0])
    return bytes(data)


def square_wave(freq, duration, duty=0.5):
    """Generate a square wave at the given frequency."""
    samples = []
    period = SAMPLE_RATE / freq
    for i in range(int(SAMPLE_RATE * duration)):
        phase = (i % period) / period
        samples.append(1.0 if phase < duty else -1.0)
    return samples


def sawtooth_wave(freq, duration):
    """Generate a sawtooth wave."""
    samples = []
    period = SAMPLE_RATE / freq
    for i in range(int(SAMPLE_RATE * duration)):
        phase = (i % period) / period
        samples.append(2.0 * phase - 1.0)
    return samples


def triangle_wave(freq, duration):
    """Generate a triangle wave."""
    samples = []
    period = SAMPLE_RATE / freq
    for i in range(int(SAMPLE_RATE * duration)):
        phase = (i % period) / period
        if phase < 0.5:
            samples.append(4.0 * phase - 1.0)
        else:
            samples.append(3.0 - 4.0 * phase)
    return samples


def noise(duration):
    """Generate white noise."""
    return [random.uniform(-1, 1) for _ in range(int(SAMPLE_RATE * duration))]


def apply_envelope(samples, attack=0.0, decay=0.0, sustain=1.0, release=0.0):
    """Apply a simple ADSR-like envelope."""
    length = len(samples)
    env = [0.0] * length
    attack_samps = int(attack * SAMPLE_RATE)
    decay_samps = int(decay * SAMPLE_RATE)
    release_samps = int(release * SAMPLE_RATE)
    sustain_samps = max(0, length - attack_samps - decay_samps - release_samps)

    idx = 0
    for i in range(attack_samps):
        env[idx] = i / attack_samps if attack_samps > 0 else 1.0
        idx += 1
    for i in range(decay_samps):
        env[idx] = 1.0 - (1.0 - sustain) * (i / decay_samps) if decay_samps > 0 else sustain
        idx += 1
    for _ in range(sustain_samps):
        env[idx] = sustain
        idx += 1
    for i in range(release_samps):
        env[idx] = sustain * (1.0 - i / release_samps) if release_samps > 0 else 0.0
        idx += 1

    return [s * e for s, e in zip(samples, env)]


def bit_crush(samples, levels=16):
    """Reduce bit depth for crunchy 8-bit character."""
    step = 2.0 / levels
    return [math.floor(s / step + 0.5) * step for s in samples]


def save_wav(filename, samples):
    """Save float samples as a mono 8-bit WAV file."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.abspath(os.path.join(script_dir, '..', 'assets', 'audio'))
    filepath = os.path.join(output_dir, filename)
    os.makedirs(output_dir, exist_ok=True)
    with wave.open(filepath, 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(1)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(to_bytes(samples))
    print(f"Saved {filepath}")


def generate_correct():
    """Cheerful rising 8-bit arpeggio."""
    notes = [523.25, 659.25, 783.99, 1046.50]  # C5 E5 G5 C6
    samples = []
    for freq in notes:
        samples.extend(apply_envelope(square_wave(freq, 0.07), attack=0.005, decay=0.05, sustain=0.0))
    save_wav('correct.wav', bit_crush(samples))


def generate_wrong():
    """Descending buzz / error sound."""
    samples = []
    for freq in [200.0, 150.0, 100.0]:
        samples.extend(apply_envelope(sawtooth_wave(freq, 0.12), attack=0.01, decay=0.1, sustain=0.0))
    save_wav('wrong.wav', bit_crush(samples))


def generate_tick():
    """Short high tick for timer."""
    samples = apply_envelope(square_wave(880.0, 0.04), attack=0.005, decay=0.03, sustain=0.0)
    save_wav('tick.wav', bit_crush(samples))


def generate_game_over():
    """Sad descending game-over jingle."""
    notes = [523.25, 493.88, 466.16, 440.0, 392.0, 349.23, 329.63, 293.66]
    samples = []
    for freq in notes:
        samples.extend(apply_envelope(triangle_wave(freq, 0.12), attack=0.01, decay=0.1, sustain=0.0))
    samples.extend(apply_envelope(sawtooth_wave(130.81, 0.5), attack=0.05, decay=0.4, sustain=0.0))
    save_wav('game_over.wav', bit_crush(samples))


def generate_tap():
    """Short blip for UI taps."""
    samples = apply_envelope(square_wave(1320.0, 0.04), attack=0.005, decay=0.03, sustain=0.0)
    save_wav('tap.wav', bit_crush(samples))


def generate_bgm():
    """Short looping chiptune background track."""
    melody = [
        (261.63, 0.2), (261.63, 0.2), (392.0, 0.2), (392.0, 0.2),
        (440.0, 0.2), (440.0, 0.2), (392.0, 0.4),
        (349.23, 0.2), (349.23, 0.2), (329.63, 0.2), (329.63, 0.2),
        (293.66, 0.2), (293.66, 0.2), (261.63, 0.4),
    ]
    bass = [
        (130.81, 0.4), (130.81, 0.4), (146.83, 0.4), (146.83, 0.4),
        (196.0, 0.4), (196.0, 0.4), (130.81, 0.4), (130.81, 0.4),
    ]

    samples = []
    beat = 0
    for freq, dur in melody:
        note = apply_envelope(square_wave(freq, dur), attack=0.01, decay=0.05, sustain=0.3, release=0.05)
        bass_note_duration = 0.4
        bass_freq = bass[beat % len(bass)][0]
        bass_samp = apply_envelope(triangle_wave(bass_freq, bass_note_duration), attack=0.02, decay=0.1, sustain=0.2, release=0.05)
        # Mix melody and bass
        length = max(len(note), len(bass_samp))
        mixed = []
        for i in range(length):
            val = 0.0
            if i < len(note):
                val += note[i] * 0.6
            if i < len(bass_samp):
                val += bass_samp[i] * 0.4
            mixed.append(val)
        samples.extend(mixed)
        beat += 1

    save_wav('bgm.wav', bit_crush(samples, levels=32))


if __name__ == '__main__':
    generate_correct()
    generate_wrong()
    generate_tick()
    generate_game_over()
    generate_tap()
    generate_bgm()
    print("All 8-bit sounds generated!")
