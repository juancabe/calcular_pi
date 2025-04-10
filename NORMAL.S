.data
wIteraciones:    .word 5
const16punto0:   .float 16.0
; Constante 16.0 en formato flotante
potencias16:     .space 5*4
calculoA:        .space 5*4
kpor8:           .space 5*4
kpor8mas1:       .space 5*4
kpor8mas4:       .space 5*4
kpor8mas5:       .space 5*4
kpor8mas6:       .space 5*4
calculoB:        .space 5*4
calculoC:        .space 5*4
calculoD:        .space 5*4
calculoE:        .space 5*4
calculoBCDE:     .space 5*4
calculoITE:      .space 5*4
calculoPI:       .space 5*4

.text
.global main

main:
    
; Cargar constantes en registros
    addi r1, r0, 1       
    addi r2, r0, 2       
    addi r3, r0, 4       
    addi r4, r0, 8       
    addi r5, r0, 16      
    
    
; Convertir constantes enteras a punto flotante
    movi2fp f1, r1; f1 = 1.0
    cvti2f f1, f1
    movi2fp f2, r2; f2 = 2.0
    cvti2f f2, f2
    movi2fp f3, r3; f3 = 4.0
    cvti2f f3, f3


; Cargar constante 16.0 en punto flotante
    lf f4, const16punto0 
    
    
; Cargar wIteraciones
    lw r10, wIteraciones  
    
    
; Comprobar si wIteraciones es 0, si es así salimos
    beqz r10, exit
    
    
; Inicializar k y pi
    addi r11, r0, 0       
    ; f31 = pi = 0.0
    addf f31, f0, f0      
    
loop:
    
; Comprobar si hemos hecho todas las iteraciones
    ; r20 = (k < wIteraciones)
    slt r20, r11, r10     
    ; si no (k < wIteraciones), salir
    beqz r20, exit
    
    
; Calcular desplazamientos de memoria para arrays (k*4)
    ; r21 = k*4
    slli r21, r11, 2
    
    
; a. Calcular 16^k usando punto flotante directamente
    ; si k=0, potencia = 1
    beqz r11, potencia_zero  
    
; Para k > 0
    ; r22 = (k-1)*4
    subi r22, r21, 4 ; f5 = potencias16[k-1] (en flotante)
    lw r20, potencias16(r22) ; f6 = potencias16[k-1] * 16.0
    mult r20, r20, r5 ; potencias16[k] = f6
    sw potencias16(r21), r20   
    j potencia_done
    
potencia_zero:
    addi r20, r0, 1              ; r20 = 1
    sw potencias16(r21), r20      ; potencias16[0] = 1
    
potencia_done:
; b. Calcular 1/16^k convirtiendo el entero a flotante
    lw r20, potencias16(r21)      ; cargar 16^k (entero)
    movi2fp f16, r20            
    cvti2f f16, f16             ; convertir entero a flotante
    divf f6, f1, f16            ; f6 = 1.0 / (16^k)
    sf calculoA(r21), f6        ; almacenar calculoA[k]
    
    
; c. Calcular 8k y guardar en kpor8[k]
    mult r25, r11, r4 ; r25 = 8*k
    sw kpor8(r21), r25 ; kpor8[k] = 8*k
    
    
; d. Calcular 8k+1 y guardar en kpor8mas1[k]
    addi r26, r25, 1 ; r26 = 8*k + 1
    sw kpor8mas1(r21), r26 ; kpor8mas1[k] = 8*k + 1
    
    
; e. Calcular 8k+4 y guardar en kpor8mas4[k]
    addi r27, r25, 4 ; r27 = 8*k + 4
    sw kpor8mas4(r21), r27 ; kpor8mas4[k] = 8*k + 4
    
    
; f. Calcular 8k+5 y guardar en kpor8mas5[k]
    addi r28, r25, 5 ; r28 = 8*k + 5
    sw kpor8mas5(r21), r28 ; kpor8mas5[k] = 8*k + 5
    
    
; g. Calcular 8k+6 y guardar en kpor8mas6[k]
    addi r29, r25, 6 ; r29 = 8*k + 6
    sw kpor8mas6(r21), r29 ; kpor8mas6[k] = 8*k + 6
    
    
; h. Calcular 4/(8k+1) y guardar en calculoB[k]
    movi2fp f7, r26
    cvti2f f7, f7 ; f7 = float(8*k + 1)
    divf f8, f3, f7 ; f8 = 4.0 / (8*k + 1)
    sf calculoB(r21), f8 ; calculoB[k] = f8
    
    
; i. Calcular 2/(8k+4) y guardar en calculoC[k]
    movi2fp f9, r27
    cvti2f f9, f9 ; f9 = float(8*k + 4)
    divf f10, f2, f9 ; f10 = 2.0 / (8*k + 4)
    sf calculoC(r21), f10 ; calculoC[k] = f10
    
    
; j. Calcular 1/(8k+5) y guardar en calculoD[k]
    movi2fp f11, r28
    cvti2f f11, f11 ; f11 = float(8*k + 5)
    divf f12, f1, f11 ; f12 = 1.0 / (8*k + 5)
    sf calculoD(r21), f12 ; calculoD[k] = f12
    
    
; k. Calcular 1/(8k+6) y guardar en calculoE[k]
    movi2fp f13, r29
    cvti2f f13, f13 ; f13 = float(8*k + 6)
    divf f14, f1, f13 ; f14 = 1.0 / (8*k + 6)
    sf calculoE(r21), f14 ; calculoE[k] = f14
    
    
; l. Calcular 4/(8k+1)-2/(8k+4)-1/(8k+5)-1/(8k+6) y guardar en calculoBCDE[k]
    subf f15, f8, f10 ; f15 = 4/(8k+1) - 2/(8k+4)
    subf f16, f15, f12 ; f16 = f15 - 1/(8k+5)
    subf f17, f16, f14 ; f17 = f16 - 1/(8k+6)
    sf calculoBCDE(r21), f17 ; calculoBCDE[k] = f17
    
    
; m. Calcular (1/16^k)*(4/(8k+1)-2/(8k+4)-1/(8k+5)-1/(8k+6)) y guardar en calculoITE[k]
    multf f18, f6, f17 ; f18 = (1/16^k) * (calculoBCDE)
    sf calculoITE(r21), f18 ; calculoITE[k] = f18
    
    
; n. Actualizar el valor acumulado de π y guardar en calculoPI[k]
    addf f31, f31, f18 ; f31 = π_previo + término_k
    sf calculoPI(r21), f31 ; calculoPI[k] = f31
    
    
; Incrementar k y repetir
    addi r11, r11, 1 ; k++
    j loop
    
exit:
    trap 0                    
; Finalizar programa
