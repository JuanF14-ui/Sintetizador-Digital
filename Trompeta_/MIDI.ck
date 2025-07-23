// Sintetizador con control MIDI de volumen
MidiIn min;
MidiMsg msg;

OscRecv orec;
6449 => orec.port;
orec.listen();

// Configuración MIDI
if (!min.open(0)) {
    <<< "Error: No se pudo abrir dispositivo MIDI", "" >>>;
    me.exit();
}

// Instrumento con control de volumen
BlowBotl tuba => Gain master => dac;
0.5 => master.gain;
0.1 => tuba.noiseGain;

// Control de volumen MIDI
fun void midiVolumeControl() {
    while (true) {
        min => now;
        while (min.recv(msg)) {
            if (msg.data1 == 0xB0 && msg.data2 == 7) { // Control Change CC7 (Volumen)
                msg.data3 / 127.0 => master.gain;
                <<< "Volumen ajustado a:", msg.data3 >>>;
            }
        }
    }
}

// Receptor OSC para notas de la FPGA
fun void oscHandler() {
    orec.event("/nota,i") @=> OscEvent noteEvent;
    while (true) {
        noteEvent => now;
        while (noteEvent.nextMsg() != 0) {
            noteEvent.getInt() => int nota;
            Std.mtof(nota) => tuba.freq;
            0.8 => tuba.startBlowing;
            <<< "Nota recibida:", nota >>>;
        }
    }
}

// Iniciar hilos
spork ~ midiVolumeControl();
spork ~ oscHandler();

// Bucle principal
while (true) {
    1::second => now;
}
