import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import resample
from scipy.signal import firwin, lfilter, decimate
import sys  
  
sys.setrecursionlimit(10000000) 


def sigma_delta_modulator(input_signal, index=0, integrator=0, output_signal=None):
    """
    Recursive implementation of a first-order Sigma-Delta modulator for 0 and 1 output.

    Args:
        input_signal (array-like): The input analog signal to be converted.
        index (int): Current index in the signal.
        integrator (float): Current state of the integrator.
        output_signal (list): Accumulated output signal (0 or 1).

    Returns:
        list: The quantized output signal (0 or 1).
    """
    if output_signal is None:
        output_signal = []

    if index >= len(input_signal):  # Base case
        return output_signal

    # Integrator: accumulate the difference
    quantizer = 1 if integrator > 0 else 0  # Quantizer outputs 0 or 1
    integrator += input_signal[index] - (1 if quantizer == 1 else 0)

    # Append the quantized value to the output
    output_signal.append(quantizer)

    return sigma_delta_modulator(input_signal, index + 1, integrator, output_signal)

def convert_audio_to_sdm(audio_data, sample_rate, target_rate):
    """
    Converts 16-bit audio data at 44.1 kHz to Sigma-Delta modulated signal at 2.8224 MHz.

    Args:
        audio_data (array-like): The input 16-bit audio signal.
        sample_rate (int): Original sample rate of the audio (44.1 kHz).
        target_rate (int): Target sample rate (2.8224 MHz).

    Returns:
        array: Sigma-Delta modulated signal (0 or 1) at target rate.
    """
    # Normalize audio data to [0, 1]
    audio_data = audio_data / np.max(np.abs(audio_data))  # Normalize to [-1, 1]
    audio_data = (audio_data + 1) / 2  # Shift to [0, 1]

    # Calculate the oversampling factor
    oversampling_factor = target_rate // sample_rate

    # Oversample the input signal
    oversampled_audio = resample(audio_data, len(audio_data) * oversampling_factor)

    # Apply Sigma-Delta Modulation
    sdm_signal = sigma_delta_modulator(oversampled_audio)

    return sdm_signal

def sigma_delta_demodulator_fir(sdm_signal, target_rate, sample_rate, num_taps=64):
    """
    Demodulates a Sigma-Delta modulated signal using an FIR filter.

    Args:
        sdm_signal (array-like): 1-bit Sigma-Delta modulated signal with values 0 and 1.
        target_rate (int): The sampling rate of the modulated signal (e.g., 2.8224 MHz).
        sample_rate (int): The desired output sampling rate (e.g., 44.1 kHz).
        num_taps (int): Number of taps for the FIR filter.

    Returns:
        array: Demodulated audio signal at the original sampling rate (16-bit).
    """
    # Map SDM signal from [0, 1] to [-1, 1]
    sdm_signal = 2 * np.array(sdm_signal) - 1

    # Design an FIR low-pass filter
    nyquist = target_rate / 2
    cutoff = sample_rate / 2  # Low-pass filter cutoff frequency
    fir_coefficients = firwin(num_taps, cutoff / nyquist)

    # Apply FIR low-pass filter
    filtered_signal = lfilter(fir_coefficients, 1.0, sdm_signal)

    # Decimate the signal to reduce the sampling rate back to the original
    decimation_factor = target_rate // sample_rate
    demodulated_signal = decimate(filtered_signal, decimation_factor, ftype="fir")

    # Scale back to 16-bit integer range (-32768 to 32767)
    demodulated_signal = np.clip(demodulated_signal, -1, 1)  # Ensure the range is [-1, 1]
    demodulated_signal = (demodulated_signal * 32767).astype(np.int16)

    return demodulated_signal

# Generate a test 16-bit sine wave audio signal at 44.1 kHz
duration = 1.0  # 1 second
sample_rate = 44100  # 44.1 kHz
target_rate = 2822400  # 2.8224 MHz
t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
frequency = 100
audio_data = (0.9 * np.sin(2 * np.pi * frequency * t) * 32767).astype(np.int16)

# Convert the audio to Sigma-Delta Modulated Signal
sdm_signal = convert_audio_to_sdm(audio_data, sample_rate, target_rate)

demodulated_audio_fir = sigma_delta_demodulator_fir(sdm_signal, target_rate, sample_rate)

# Plot the results
plt.figure(figsize=(12, 9))

# Plot original audio signal
plt.subplot(3, 1, 1)
plt.plot(t[:1000], audio_data[:1000], label="Original Audio Signal")
plt.title("Original Audio Signal (44.1 kHz)")
plt.grid(True)
plt.legend()

# Plot Sigma-Delta Modulated Signal
oversampled_t = np.linspace(0, duration, len(sdm_signal), endpoint=False)
plt.subplot(3, 1, 2)
plt.step(oversampled_t[:64000], sdm_signal[:64000], label="Sigma-Delta Modulated Signal", where="mid")
plt.title("Sigma-Delta Modulated Signal (2.8224 MHz)")
plt.grid(True)
plt.legend()

# Plot demodulated audio signal
demodulated_t = np.linspace(0, duration, len(demodulated_audio_fir), endpoint=False)
plt.subplot(3, 1, 3)
plt.plot(demodulated_t[:1000], demodulated_audio_fir[:1000], label="Demodulated Audio Signal (FIR, 16-bit)")
plt.title("Demodulated Audio Signal (44.1 kHz) Using FIR")
plt.grid(True)
plt.legend()

# Adjust layout
plt.tight_layout()
plt.show()

