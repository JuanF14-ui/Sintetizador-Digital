from machine import ADC, Pin, UART
import time

# Configuración del ADC (potenciómetro en GPIO36)
pot = ADC(Pin(36))
pot.atten(ADC.ATTN_11DB)  # Rango completo 0-3.3V
pot.width(ADC.WIDTH_10BIT)  # Resolución de 10 bits (0-1023)

# Configura UART (TX en GPIO17, baudrate 9600)
uart = UART(1, baudrate=9600, tx=17, rx=16)  # UART2 (TX en GPIO17)

while True:
    valor_adc = pot.read()  # Lee valor (0-1023)
    print("Potenciometro =", valor_adc)
    
    # Envía el valor a la FPGA como 2 bytes (MSB primero)
    #uart.write(bytes([valor_adc >> 8, valor_adc & 0xFF]))  # Formato: [high_byte, low_byte]
    uart.write(str(valor_adc)+'\r')
    
time.sleep_ms(100)  # Ajusta el delay según necesidad
