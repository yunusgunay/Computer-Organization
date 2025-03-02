/*  Author: Yunus Gunay

    Description:
    portA is connected to J1 Port. Jumpers are 5V, pull down.
    portE is connected to J2 Port. Jumpers are 5V, pull down.
    TrisA determines portA as the output.
    TrisE determines portE as the output. */

unsigned int fibb = 0;
unsigned int fibbBefore = 0;
unsigned int fibbBefore2 = 1;
unsigned int delayTime = 0;
unsigned int RUN = 1;
unsigned int waitTime;

void calculateNextFibb(){
    fibb = fibbBefore + fibbBefore2;
    fibbBefore = fibbBefore2;
    fibbBefore2 = fibb;
}

// Hexadecimal patterns on 7-segment
unsigned char binary_pattern[] = {
    0x3F, // 0
    0x06, // 1
    0x5B, // 2
    0x4F, // 3
    0x66, // 4
    0x6D, // 5
    0x7D, // 6
    0x07, // 7
    0x7F, // 8
    0x6F  // 9
};


void main(){
    AD1PCFG = 0xFFFF;        // Configure AN pins as digital I/O
    DDPCONbits.JTAGEN = 0;   // Disable JTAG
    TRISA = 0x00;  // PortA: output for segment data
    TRISE = 0x00;  // PortE: output for digit selection

    while(RUN){
        // Total wait: fibb * 25 * 4 ms = fibb * 100 ms
        delayTime = fibb * 25;
        for(waitTime = 0; waitTime < delayTime; waitTime++){
            // Thousands
            PORTA = binary_pattern[fibb / 1000];
            PORTE = 0x01;
            Delay_ms(1);

            // Hundreds
            PORTA = binary_pattern[(fibb / 100) % 10];
            PORTE = 0x02;
            Delay_ms(1);

            // Tens
            PORTA = binary_pattern[(fibb / 10) % 10];
            PORTE = 0x04;
            Delay_ms(1);

            // Ones
            PORTA = binary_pattern[fibb % 10];
            PORTE = 0x08;
            Delay_ms(1);
        }

        // Move to the next Fibonacci number
        calculateNextFibb();
    }
}

