#include "libs/time.h"
#include "libs/uart.h"
#include <stdint.h>
#include "libs/utilities.h"

// Definición de direcciones de memoria (equivalentes a las constantes en ASM)
#define IO_BASE 0x400000
#define LASER   0x410000
#define GET_LASER 0x02


// Mensaje a mostrar (equivalente a la sección .data)

//mapeo de registros
volatile uint32_t *const get_laser = (uint32_t *)(LASER + GET_LASER);

// Punteros a los registros de hardware
volatile uint32_t *const gp = (uint32_t *)IO_BASE;

// Mensaje a mostrar (equivalente a la sección .data)
char midi[4];     // Nota midi de 3 bits en formato humano
char osc_msg[32]; // mensaje a enviar hasta de 32 bytes
char buffer[16] = "start LASER\n\r";



//bucle de ejecucion del programa
int main() {

  const char topic[] = "osc /main/piano ";

  uint8_t laserin = 0;  //Se declara una variable de 8 bits llamada laserin que almacenará lo leído del láser.
  // Inicialización del stack pointer (simulado)
  // En realidad en C esto lo hace el startup code
  while (1) { // Equivalente al main_loop
    laserin = *get_laser; // captura, letyendo el dato del acorde
    osc_msg[0] = '\0';     // Limpiando el array de char
    putstring("\nget: \r\n");
    itoa_simple_signed(laserin, buffer); // transforma a str
    putstring(buffer); // Imprime por uart
    itoa_simple_signed(laserin, midi); // Convertir el entero a string y guardar
    mi_strcat(osc_msg, topic);   // Agregar el topic al mensaje
    mi_strcat(osc_msg, "i ");    // Agregar el formato del valor a enviar
    mi_strcat(osc_msg, midi);    // "/dev/teclado i midi"
    mi_strcat(osc_msg,"\r\n");  // Mensaje a enviar: "value_topic i value_midi\r\n"
    putstring(osc_msg); // Enviar el mensaje por uart
    wait(20); // Valor arbitrario para el wait (en ASM se usaba a0)
  }
  return 0; // Nunca se alcanzará, se repite todo
}
