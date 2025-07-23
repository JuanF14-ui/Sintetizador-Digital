// Configuración OSC
OscIn oin;
OscMsg msg;
9001 => oin.port;
oin.addAddress("/dev1/piano, i");

// Sintetizador de piano
Rhodey piano => dac;
0.5 => piano.gain;

// Función para tocar una nota
fun void playNote(int midiNote) {
    Std.mtof(midiNote) => piano.freq;
    1 => piano.noteOn;
    250::ms => now;
    1 => piano.noteOff;
}

// Función para manejar los mensajes OSC
fun void listenOSC() {
    while (true) {
        oin => now;
        
        while (oin.recv(msg)) {
            if (msg.address == "/dev1/piano") {
                msg.getInt(0) => int note;
                <<< "Nota recibida:", note >>>;
                
                // Tocar la nota en un hilo separado
                spork ~ playNote(note);
            }
        }
    }
}

// Iniciar el listener OSC
spork ~ listenOSC();

// Mantener el programa corriendo
while (true) {
    1::second => now;
}
