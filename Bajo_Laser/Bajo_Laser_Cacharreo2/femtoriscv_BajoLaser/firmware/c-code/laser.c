#include "libs/time.h"
#include "libs/uart.h"
#include <stdint.h>
#include "libs/utilities.h"

// Dirección base de hardware
#define IO_BASE    0x400000
#define LASER      0x410000
#define GET_LASER  0x02

// Punteros a registros de memoria mapeada
volatile uint32_t *const get_laser = (uint32_t *)(LASER + GET_LASER);
volatile uint32_t *const gp = (uint32_t *)IO_BASE;

// Buffers de mensaje
char osc_msg[32];  // Mensaje completo OSC
char laser_str[8]; // Valor leído del láser convertido a string

int main() {
  const char topic[] = "osc /dev1/piano ";  // Tópico OSC

  putstring("start LASER\n\r");

  while (1) {
    // Leer el valor digital del sensor láser
    uint8_t laserin = *get_laser;

    // Convertir ese valor a string
    itoa_simple_signed(laserin, laser_str);

    // Construir el mensaje OSC en el buffer
    osc_msg[0] = '\0';               // Vaciar buffer
    mi_strcat(osc_msg, topic);       // Agregar el topic
    mi_strcat(osc_msg, "i ");        // Formato integer
    mi_strcat(osc_msg, laser_str);   // Agregar valor del láser
    mi_strcat(osc_msg, "\r\n");      // Final del mensaje

    // Enviar por UART
    putstring(osc_msg);

    // Esperar unos ciclos
    wait(20);
  }

  return 0;
}

