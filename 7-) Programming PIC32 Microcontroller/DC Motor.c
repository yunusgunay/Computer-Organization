/*  Author: Yunus Gunay

    Description:
    portA is connected to DC Motor Module. Jumpers are 5V, pull up.
    portE is connected to Push Button Module. Jumpers are 3V, pull up.
    TrisA determines portA as the output.
    TrisE determines portE as the input. */

#define CLOCKWISE_PIN      (1 << 2)  // PORTA bit 2
#define COUNTERCW_PIN      (1 << 1)  // PORTA bit 1
#define BUTTON0_PRESSED    (PORTE & 0x0001) // Button 0 (bit 0)
#define BUTTON1_PRESSED    (PORTE & 0x0002) // Button 1 (bit 1)

void rotateClockwise(){
    Delay_ms(1000);
    PORTA |= CLOCKWISE_PIN;
    Delay_ms(1000);
    PORTA &= ~CLOCKWISE_PIN;
}

void rotateCounterClockwise(){
    Delay_ms(1000);
    PORTA |= COUNTERCW_PIN;
    Delay_ms(1000);
    PORTA &= ~COUNTERCW_PIN;
}

void main(){
    DDPCON.JTAGEN = 0;
    TRISA = 0x00;
    TRISE = 0xFF;
    PORTA = 0x00;
    while(1){
	Delay_ms(200);
        if(BUTTON0_PRESSED && BUTTON1_PRESSED){
            PORTA &= ~CLOCKWISE_PIN;
            PORTA &= ~COUNTERCW_PIN;
            Delay_ms(1000);
        }

        else if(BUTTON0_PRESSED){
            rotateClockwise();
        }

        else if(BUTTON1_PRESSED){
            rotateCounterClockwise();
        }

        else {
            PORTA &= ~CLOCKWISE_PIN;
            PORTA &= ~COUNTERCW_PIN;
            Delay_ms(200);
        }
    }
}