#define BONGO_HIT (*(volatile unsigned int*) 0x20000000)
#define UART_DATA (*(volatile unsigned char*) 0x10000000)

void uart_puts(const char* s) {
  while (*s) {
    UART_DATA = *s++;
  }
}

int main() {
  // Mensaje de bienvenida
  uart_puts("🎵 Bongo Synth Ready! Press Left or Right 🔊\n");

  unsigned int last = 0;

  while (1) {
    unsigned int current = BONGO_HIT;

    if ((current & 0x01) && !(last & 0x01)) {
      uart_puts("bongo Left\n");
    }

    if ((current & 0x02) && !(last & 0x02)) {
      uart_puts("bongo Right\n");
    }

    last = current;
  }
}


