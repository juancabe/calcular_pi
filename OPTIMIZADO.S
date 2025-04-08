.data
wIteraciones:    .word   5       
const1_0:        .float  1.0
const2_0:        .float  2.0
const4_0:        .float  4.0
const16_0:       .float  16.0

potencias16:     .space 40     
calculoA:        .space 40     
kpor8:           .space 40     
kpor8mas1:       .space 40     
kpor8mas4:       .space 40     
kpor8mas5:       .space 40     
kpor8mas6:       .space 40     
calculoB:        .space 40     
calculoC:        .space 40     
calculoD:        .space 40     
calculoE:        .space 40     
calculoBCDE:     .space 40     
calculoITE:      .space 40     
calculoPI:       .space 40     

.text
.global main

main:
    
    addi r1, r0, 1
    addi r2, r0, 2
    addi r3, r0, 4
    addi r4, r0, 8
    

    
    lf f1, const1_0
    lf f2, const2_0
    lf f3, const4_0
    lf f4, const16_0

    
    lw r10, wIteraciones

    
    beqz r10, exit

    
    add r11, r0, r0         
    
    addf f31, f0, f0        
    
    addf f30, f0, f1        

    
    add r13, r0, r0         

unroll_loop:
    
    slt r20, r11, r10       
    beqz r20, exit        

    

    
    mult r25, r11, r4         
    addi r26, r25, 1          
    addi r27, r25, 4          
    addi r28, r25, 5          
    addi r29, r25, 6          

    
    sw kpor8(r13), r25
    sw kpor8mas1(r13), r26
    sw kpor8mas4(r13), r27
    sw kpor8mas5(r13), r28
    sw kpor8mas6(r13), r29

    
    movi2fp f5, r26
    cvti2f f5, f5             
    movi2fp f6, r27
    cvti2f f6, f6             
    movi2fp f7, r28
    cvti2f f7, f7             
    movi2fp f8, r29
    cvti2f f8, f8             

    
    sf potencias16(r13), f30

    
    divf f9, f1, f30          
    

    
    divf f10, f3, f5          
    divf f11, f2, f6          
    divf f12, f1, f7          
    divf f13, f1, f8          

    

    
    
    multf f30, f30, f4       

    
    addi r11, r11, 1          

    
    addi r13, r13, 4          

    
    sf calculoA-4(r13), f9     

    
    sf calculoB-4(r13), f10    

    
    sf calculoC-4(r13), f11    

    
    sf calculoD-4(r13), f12    

    
    sf calculoE-4(r13), f13    


    
    
    subf f14, f10, f11        
    subf f14, f14, f12        
    subf f14, f14, f13        
    sf calculoBCDE-4(r13), f14 

    
    
    multf f15, f9, f14        
    sf calculoITE-4(r13), f15  

    
    addf f31, f31, f15        
    sf calculoPI-4(r13), f31   

    
    j unroll_loop

exit:
    
    trap 0