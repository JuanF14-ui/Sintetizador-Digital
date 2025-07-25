// Configuración OSC - escuchamos en todas las direcciones
OscIn oin;
OscMsg msg;
9001 => oin.port;
oin.addAddress("/*");

// Sintetizadores
Rhodey piano => dac;
Flute flauta => dac;
0.5 => piano.gain;
0.5 => flauta.gain;
[0, 64, 69,60 , 62,61 ,63 ,65,67,66,68,69,70,71,72,73] @=> int arreglo[];

// Función para tocar una nota en el piano
fun void playPiano(int midiNote) {
    Std.mtof(midiNote) => piano.freq;
    1 => piano.noteOn;
    350::ms => now;
    1 => piano.noteOff;
}

// Función para tocar una nota en la flauta
fun void playFlauta(int midiNote) {
    Std.mtof(midiNote) => flauta.freq;
    1 => flauta.noteOn;
    350::ms => now; // Nota más larga para la flauta
    1 => flauta.noteOff;
}

// Función para manejar los mensajes OSC
fun void listenOSC() {
    while (true) {
        oin => now;
        
        while (oin.recv(msg)) {
            if (msg.address == "/dev1/piano") {
                arreglo[msg.getInt(0)] => int note;
                <<< "Nota de piano recibida:", note >>>;
                spork ~ playPiano(note);
            }
            else if (msg.address == "/dev2/piano") {
                msg.getInt(0) => int note;
                <<< "Nota de flauta recibida:", note >>>;
                spork ~ playFlauta(note);
            }
            else {
                <<< "Mensaje OSC recibido en dirección no reconocida:", msg.address >>>;
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
