import subprocess
import serial
import time
import datetime

# Serial port settings
serial_port = '/dev/ttyUSB2'  # Replace with your actual serial port
baud_rate = 9600  # Replace with your actual baud rate

# Function to send AT command via serial
def send_at_command(command):
    with serial.Serial(serial_port, baud_rate, timeout=1) as ser:
        ser.write(command.encode('utf-8'))
        response = ser.readline().decode('utf-8').strip()
        assert command == response
        response = ser.readline().decode('utf-8').strip()
        print(f"Sent command: {command}, Response: {response}")

# Ping test function
def check_internet_connection(ping_count):
    host = "8.8.8.8"  # Google's public DNS server
    for _ in range(ping_count):
        result = subprocess.run(['ping','-I', 'usb0' ,'-c', '1', host], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            print(datetime.datetime.now().isoformat() + ": " + "Ping Success")
            return True
        time.sleep(0.1)
    print(datetime.datetime.now().isoformat() + ": " + "Ping failed {ping_count} times")
    return False

# Main loop
def main():
    consecutive_failures = 0
    while True:
        if not check_internet_connection(10):
            print(datetime.datetime.now().isoformat() + ": " + "Internet connection lost. Set modem to airplane mode...")
            send_at_command("at+cfun=0\r\n")
            time.sleep(10)  # Wait for modem to reset
            print(datetime.datetime.now().isoformat() + ": " + "Turn off the airplane mode...")
            send_at_command("at+cfun=1\r\n")
            print(datetime.datetime.now().isoformat() + ": " + "Modem reset complete.")
            if check_internet_connection(100):
                time.sleep(10)

if __name__ == "__main__":
    main()