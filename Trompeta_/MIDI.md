# Protocolo MIDI para el Sintetizador FPGA

## Mensajes Implementados

1. **Control Change (CC) - Volumen**
   - Byte 1: `0xBn` (n = canal MIDI)
   - Byte 2: `0x07` (CC7 = Volumen)
   - Byte 3: `0x00-0x7F` (valor)

2. **Note On**
   - Byte 1: `0x9n` (n = canal)
   - Byte 2: Nota MIDI (0-127)
   - Byte 3: Velocidad (0-127)

3. **Note Off**
   - Byte 1: `0x8n` (n = canal)
   - Byte 2: Nota MIDI
   - Byte 3: Velocidad (usualmente 0)
