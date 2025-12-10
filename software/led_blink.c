// led_blink.c
// simple led blinker to prove cpu works on fpga
#include <stdint.h>

// memory mapped gpio
#define GPIO_BASE  0x80000000
#define GPIO_LED   (*(volatile uint32_t*)(GPIO_BASE + 0x00))
#define GPIO_SW    (*(volatile uint32_t*)(GPIO_BASE + 0x04))
#define GPIO_BTN   (*(volatile uint32_t*)(GPIO_BASE + 0x08))

// simple delay function
void delay(uint32_t count) {
    for (volatile uint32_t i = 0; i < count; i++) {
        __asm__ volatile ("nop");
    }
}

int main(void) {
    uint32_t counter = 0;
    
    while (1) {
        // read switches
        uint32_t sw_val = GPIO_SW;
        
        // blink pattern based on counter
        uint32_t led_pattern = (counter >> 20) & 0xF;
        
        // if button 0 pressed show switch values on leds
        uint32_t btn_val = GPIO_BTN;
        if (btn_val & 0x1) {
            led_pattern = sw_val;
        }
        
        // write to leds lower 4 bits and rgb led bits 4 to 6
        GPIO_LED = led_pattern | ((counter >> 18) & 0x70);
        
        counter++;
        
        // small delay
        delay(1000);
    }
    
    return 0;
}