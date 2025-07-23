import pygame.midi
import time
import json

class MidiController:
    def __init__(self):
        pygame.midi.init()
        self.device_id = self._detect_device()
        self.midi_out = pygame.midi.Output(self.device_id)
        
    def _detect_device(self):
        for i in range(pygame.midi.get_count()):
            info = pygame.midi.get_device_info(i)
            if info[2] == 1:  # Dispositivo de salida
                return i
        raise Exception("No se encontró dispositivo MIDI")
    
    def set_volume(self, volume):
        """Establece volumen (0-127)"""
        # CC7 es el control de volumen principal MIDI
        self.midi_out.write_short(0xB0, 7, volume)
    
    def close(self):
        self.midi_out.close()
        pygame.midi.quit()

if __name__ == "__main__":
    controller = MidiController()
    try:
        print("Controlador MIDI iniciado. Use Ctrl+C para salir.")
        while True:
            vol = int(input("Ingrese volumen (0-127): "))
            if 0 <= vol <= 127:
                controller.set_volume(vol)
            else:
                print("Volumen debe ser entre 0 y 127")
    except KeyboardInterrupt:
        controller.close()
