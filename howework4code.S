.text
.set noreorder
.globl main
.ent main

#include <xc.h>

main:
    # ... (provided code for port configuration)
    sw	    zero, TRISA		    ## TRISA = 0  --> all PORTA bits = output
    sw	    zero, ANSELA	    ## ANSELA = 0 --> all PORTA bits digital
    not	    t0, zero		    
    sw	    t0, TRISB		    ## TRISB = 0xFFFFFFFF --> all PORTB bits = input
    sw	    zero, ANSELB	    ## ANSELB = 0 --> all PORTB bits digital  
    sw	    zero, TRISC		    ## TRISC = 0  --> all PORTC bits = output
    sw	    zero, ANSELC	    ## ANSELC = 0 --> all PORTC bits digital

    li     t0, _PORTA_RA0_MASK
    li     t1, _PORTC_RC9_MASK
    li     t5, _PORTB_RB7_MASK
    li     t6, _PORTB_RB13_MASK

    sw     t0, LATASET
    sw     t1, LATCSET

    # Set initial blinking period to 1 second (10000000 cycles)
    li     s1, 10000000

    j     toggle
    nop

# Default blinking
toggle:
    move   t8, s1          # Set delay counter

delayblink:
    addi   t8, t8, -1       # Decrement counter
    bne    t8, zero, delayblink   # Continue until counter hits 0
    nop

    sw     t0, LATAINV
    sw     t1, LATCINV
    j      toggle          # Reset delay counter and start again
    nop

# Check state of S1
pollS1:
    lw     t2, PORTB         # Read Port B

    andi   t3, t2, _PORTB_RB7_MASK   # Check S1

    beq    t3, zero, pollS2     # If button not pressed, check S2
    nop

    bne    t3, t5, pollS2     # If button pressed but hasn't changed, check S2
    nop

    jal    delay         # Call debounce function for delay
    nop

    lw     t2, PORTB
    andi   t3, t2, _PORTB_RB7_MASK
    bne    t3, zero, copyS1
    nop
    clrLED1:    // If you get here, S1 isn't pressed--turn LED1 off
    sw	    t0, LATACLR

    # Write code to decrease blinking period by 0.5s
sub5:
    li     t9, 5000000      # 0.5 seconds in cycles
    sub    s1, s1, t9
    j      delayblink
    nop

copyS1:
    add    t5, t3, zero     # t5 = saved state of S1
    j      pollS2
    nop

# Check state of S2
pollS2:
    andi   t4, t2, _PORTB_RB13_MASK   # Check S2

    beq    t4, zero, pollS1     # If button not pressed, check S1
    nop

    bne    t4, t6, pollS1     # If button pressed but hasn't changed, check S1
    nop

    jal    delay         # Call debounce function for delay
    nop

    lw     t2, PORTB
    andi   t4, t2, _PORTB_RB13_MASK
    bne    t4, zero, copyS2
    nop

    # Write code to increase blinking period by 0.5s
    add    t9, s1, 5000000  # 0.5 seconds in cycles
    bge    t9, 20000000, max_period  # Check if it reaches the max period
    add    s1, s1, 5000000
    j      delayblink
    nop

max_period:
    li     s1, 20000000     # Set blinking period to the max
    j      delayblink
    nop

copyS2:
    add    t6, t4, zero     # t6 = saved state of S2
    j      pollS1
    nop

spin:
    j      spin
    nop

.end main

.ent delay
delay:
    li     t7, 25000         # Set delay counter to 25000

loop:
    addi   t7, t7, -1        # Decrement counter
    bne    t7, zero, loop    # Continue until counter hits 0
    nop

    jr     ra
    nop
.end delay