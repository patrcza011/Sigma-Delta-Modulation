import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import resample
from scipy.signal import firwin, lfilter, decimate
import sys
import os

parent_path = os.path.abspath(os.path.join(os.path.dirname(__file__),".."))
if parent_path not in sys.path:
    sys.path.append(parent_path)

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
    integrator += input_signal[index] - (32768 if quantizer == 1 else -32768)

    # Append the quantized value to the output
    output_signal.append(quantizer)
    return sigma_delta_modulator(input_signal, index + 1, integrator, output_signal)

# minimalnie się różni od poprzedniej funkcji, lepiej zrobić jedną funkcję z dodatkowym parametrem zamiast 2
def second_order_sigma_delta_modulator(input_signal, index=0, integrator1=0, integrator2=0, output_signal=None):
    """
    Recursive implementation of a second-order Sigma-Delta modulator for 0 and 1 output.

    Args:
        input_signal (array-like): The input analog signal to be converted.
        index (int): Current index in the signal.
        integrator1 (float): Current state of the first integrator.
        integrator2 (float): Current state of the second integrator.
        output_signal (list): Accumulated output signal (0 or 1).

    Returns:
        list: The quantized output signal (0 or 1).
    """
    if output_signal is None:
        output_signal = []

    if index >= len(input_signal):  # Base case
        return output_signal

    # First integrator: accumulate the difference
    integrator1 += input_signal[index] - (32768 if integrator2 > 0 else -32768)

    # Second integrator: accumulate the output of the first integrator
    integrator2 += integrator1

    # Quantizer: outputs 0 or 1 based on the second integrator
    quantizer = 1 if integrator2 > 0 else 0

    # Append the quantized value to the output
    output_signal.append(quantizer)
    return second_order_sigma_delta_modulator(input_signal, index + 1, integrator1, integrator2, output_signal)

def convert_audio_to_sdm(audio_data, sample_rate, target_rate, order=1):
    """
    Converts 16-bit audio data at 44.1 kHz to Sigma-Delta modulated signal at 2.8224 MHz.

    Args:
        audio_data (array-like): The input 16-bit audio signal.
        sample_rate (int): Original sample rate of the audio (44.1 kHz).
        target_rate (int): Target sample rate (2.8224 MHz).
        order (int): Order of the sigma delta modulator, available order=1 or order=2

    Returns:
        array: Sigma-Delta modulated signal (0 or 1) at target rate.
    """
    print(f"sample_rate: {sample_rate}, target_rate: {target_rate}")
    # Normalize audio data to [0, 1]
    #print(f"max: {np.max(np.abs(audio_data))}")
    #audio_data = audio_data / 32768 #np.max(np.abs(audio_data))  # Normalize to [-1, 1]
    #audio_data = (audio_data + 1) / 2  # Shift to [0, 1]
    print(f"Adudio data len: {len(audio_data)}")

    # Calculate the oversampling factor
    oversampling_factor = 64#target_rate // sample_rate
    print(f"oversampling_factor: {oversampling_factor}")

    # Oversample the input signal
    oversampled_audio = [int(x) for x in audio_data for _ in range(oversampling_factor)] #lst = [(j, k) for j in s1 for k in s2]
    print(f"oversampled: {oversampled_audio}")
    #oversampled_audio = resample(audio_data, len(audio_data) * oversampling_factor)

    # Apply Sigma-Delta Modulation
    sdm_signal = sigma_delta_modulator(oversampled_audio) if order != 2 else second_order_sigma_delta_modulator(oversampled_audio)

    # Decimate the SDM signal to reduce the number of samples
    #decimation_factor = 64
    #decimated_sdm_signal = sdm_signal[::decimation_factor]
    #return decimated_sdm_signal
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

if __name__ == "__main__":
    # Generate a test 16-bit sine wave audio signal at 44.1 kHz
    #duration = 1.0  # 1 second
    #sample_rate = 44100  # 44.1 kHz
    #target_rate = 2822400  # 2.8224 MHz
    #t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    #frequency = 100
    #audio_data = (0.9 * np.sin(2 * np.pi * frequency * t) * 32767).astype(np.int16)
    #print("Audio_data len: ", len(audio_data))
    # Convert the audio to Sigma-Delta Modulated Signal

    # TEMP #############

    periods=5
    samples_per_period=5
    target_rate=2822400
    frequency=100

    # Calculate the duration for 5 periods
    duration = periods / frequency

    # Total number of samples
    total_samples = periods * samples_per_period

    # Time array with 5 samples per period
    t = np.linspace(0, duration, int(total_samples), endpoint=False)
    print(f"t: {t}, len: {len(t)}")

    # Generate sine wave with the desired properties
    audio_data = (0.9 * np.sin(2 * np.pi * frequency * t) * 32767).astype(dtype='int16')
    print(f"audio_data: {audio_data}, len: {len(audio_data)}")
    # Convert to SDM signal
    sdm_signal = convert_audio_to_sdm(audio_data, total_samples, target_rate)


    #sdm_signal = convert_audio_to_sdm(audio_data, sample_rate, target_rate)

    #demodulated_audio_fir = sigma_delta_demodulator_fir(sdm_signal, target_rate, sample_rate)

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

    ## Plot demodulated audio signal
    #demodulated_t = np.linspace(0, duration, len(demodulated_audio_fir), endpoint=False)
    #plt.subplot(3, 1, 3)
    #plt.plot(demodulated_t[:1000], demodulated_audio_fir[:1000], label="Demodulated Audio Signal (FIR, 16-bit)")
    #plt.title("Demodulated Audio Signal (44.1 kHz) Using FIR")
    #plt.grid(True)
    #plt.legend()

    # Adjust layout
    plt.tight_layout()
    plt.show()
