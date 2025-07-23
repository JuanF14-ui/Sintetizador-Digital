from machine import ADC, Pin
import time

# Configuración del ADC (potenciómetro en GPIO36)
pot = ADC(Pin(36))
pot.atten(ADC.ATTN_11DB)  # Rango completo 0-3.3V
pot.width(ADC.WIDTH_12BIT)  # Resolución de 10 bits (0-1023)


while True:
    valor_adc = pot.read()  # Lee valor (0-1023)
    valor_adc = valor_adc*(1/4092)
    print("Dato Laser=", round(valor_adc))
      
      
time.sleep_ms(1000)  # Ajusta el delay según necesidad
