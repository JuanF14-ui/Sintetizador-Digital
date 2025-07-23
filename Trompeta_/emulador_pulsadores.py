import pygame
import numpy as np
import os
import time

# Configura el driver de audio para Linux
os.environ['SDL_AUDIODRIVER'] = 'pulseaudio'

# Inicialización segura
try:
    pygame.mixer.quit()
    pygame.mixer.init(frequency=44100, size=-16, channels=2)
except pygame.error as e:
    print(f"Error inicializando mixer: {e}")
    print("Probando configuración alternativa...")
    pygame.mixer.init()

# Frecuencias de notas (Hz)
NOTAS = {
    '0': 262, '1': 294, '2': 330,
    '0+1': 349, '0+2': 392, '1+2': 440,
    '0+1+2': 494, '': 523
}

# Teclas asignadas (Z, X, C)
TECLAS = {pygame.K_z: '0', pygame.K_x: '1', pygame.K_c: '2'}

def generar_sonido(frecuencia, duracion=0.8):
    """Genera tono sinusoidal con numpy y pygame"""
    sample_rate = 44100
    t = np.linspace(0, duracion, int(sample_rate * duracion), False)
    onda = np.sin(2 * np.pi * frecuencia * t) * 0.3
    stereo_onda = np.column_stack((onda, onda))
    sonido = pygame.sndarray.make_sound(np.int16(stereo_onda * 32767))
    sonido.play()

# Bucle principal
pygame.init()
screen = pygame.display.set_mode((200, 200))  # Ventana mínima

teclas_activas = set()
print("Presiona Z, X, C (solos/combinados). ESC para salir.")

running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        
        if event.type == pygame.KEYDOWN:
            if event.key in TECLAS:
                teclas_activas.add(TECLAS[event.key])
            elif event.key == pygame.K_ESCAPE:
                running = False
        
        if event.type == pygame.KEYUP:
            if event.key in TECLAS:
                teclas_activas.discard(TECLAS[event.key])
    
    combo = '+'.join(sorted(teclas_activas))
    if teclas_activas:
        frecuencia = NOTAS.get(combo, NOTAS[''])
        generar_sonido(frecuencia, 0.3)
        print(f"Teclas: {combo} -> Nota: {frecuencia} Hz")
    
    pygame.display.flip()
    time.sleep(0.1)

pygame.quit()
