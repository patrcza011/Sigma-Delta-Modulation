from scipy.signal import firwin
import numpy as np

# Sampling parameters
fs = 2822400  # Input sampling rate (2.8224 MHz)
decimation_factor = 64
output_fs = fs / decimation_factor  # Output sampling rate (44.1 kHz)

# Filter design parameters
num_taps = 80 # Filter length
cutoff = 20000  # Passband cutoff (20 kHz)
nyquist = fs / 2  # Nyquist frequency of the input

# Design lowpass FIR filter
coefficients = firwin(num_taps, cutoff / nyquist, window='hamming')

# Normalize coefficients
coefficients = coefficients / np.sum(coefficients)

# Print or save coefficients
print(coefficients)
scaled_coefficients = [int(c * (2**15)) for c in coefficients]
hex_coefficients = [hex((c + (1 << 16)) % (1 << 16)) for c in scaled_coefficients]

print("Scaled coefficients:", scaled_coefficients)
print("Hex coefficients:", hex_coefficients)