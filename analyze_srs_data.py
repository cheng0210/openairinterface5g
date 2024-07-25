import scipy.io
import numpy as np
import matplotlib.pyplot as plt

# Read the .mat file
mat_contents = scipy.io.loadmat('srs_data.mat')

# Get all variables starting with 'srs_data_'
srs_data_vars = [key for key in mat_contents.keys() if key.startswith('srs_data_')]

# Sort the variables to ensure they're in order
srs_data_vars.sort(key=lambda x: int(x.split('_')[-1]))

# Process each dataset
for var_name in srs_data_vars:
    srs_data = mat_contents[var_name].flatten()

    print(f"\nProcessing {var_name}")
    print(f"Number of elements: {len(srs_data)}")
    print(f"Data type: {srs_data.dtype}")
    print(f"Min value: {np.min(srs_data)}")
    print(f"Max value: {np.max(srs_data)}")
    print(f"Mean value: {np.mean(srs_data)}")

    print(srs_data.shape)

    # Plot the data
    plt.figure(figsize=(12, 6))
    plt.plot(srs_data)
    plt.title(f'SRS Estimated Channel Frequency - {var_name}')
    plt.xlabel('Sample Index')
    plt.ylabel('Value')
    plt.grid(True)
    plt.show()

    # If the data represents complex values (real and imaginary parts alternating),
    # separate them:
    complex_data = srs_data[::2] + 1j * srs_data[1::2]

    # Plot magnitude and phase of complex data
    plt.figure(figsize=(12, 10))

    plt.subplot(2, 1, 1)
    plt.plot(np.abs(complex_data))
    plt.title(f'Magnitude of Complex SRS Data - {var_name}')
    plt.xlabel('Sample Index')
    plt.ylabel('Magnitude')
    plt.grid(True)

    plt.subplot(2, 1, 2)
    plt.plot(np.angle(complex_data))
    plt.title(f'Phase of Complex SRS Data - {var_name}')
    plt.xlabel('Sample Index')
    plt.ylabel('Phase (radians)')
    plt.grid(True)

    plt.tight_layout()
    plt.show()