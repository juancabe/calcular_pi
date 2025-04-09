.data
; --- Variables de Entrada y Salida (No modificar orden) ---
wIteraciones:    .word   5       
; Número de iteraciones a realizar (0 a 4) -> k=0,1,2,3,4

; --- Constantes en Punto Flotante ---
const1_0:        .float  1.0
const2_0:        .float  2.0
const4_0:        .float  4.0
const16_0:       .float  16.0

; --- Arrays para almacenar resultados (Espacio para 5 elementos de 32 bits = 20 bytes) ---
potencias16:     .space 5*4     
; Salida: 16^k (float para precisión/rango)
calculoA:        .space 5*4     
; Salida: 1 / 16^k
kpor8:           .space 5*4     
; Salida: 8*k (entero)
kpor8mas1:       .space 5*4     
; Salida: 8*k+1 (entero)
kpor8mas4:       .space 5*4     
; Salida: 8*k+4 (entero)
kpor8mas5:       .space 5*4     
; Salida: 8*k+5 (entero)
kpor8mas6:       .space 5*4     
; Salida: 8*k+6 (entero)
calculoB:        .space 5*4     
; Salida: 4/(8k+1)
calculoC:        .space 5*4     
; Salida: 2/(8k+4)
calculoD:        .space 5*4     
; Salida: 1/(8k+5)
calculoE:        .space 5*4     
; Salida: 1/(8k+6)
calculoBCDE:     .space 5*4     
; Salida: B - C - D - E
calculoITE:      .space 5*4     
; Salida: (1/16^k) * BCDE
calculoPI:       .space 5*4     
; Salida: Valor acumulado de PI para la iteración k

; --- Plan de Asignación de Registros (Parcial) ---
; r1: constante 1 (entero)
; r2: constante 2 (entero)
; r3: constante 4 (entero)
; r4: constante 8 (entero)
; r10: wIteraciones (límite del bucle)
; r11: k (índice del bucle actual)
; r13: desplazamiento base para almacenamiento en arrays (k*4)

; f1: constante 1.0
; f2: constante 2.0
; f3: constante 4.0
; f4: constante 16.0
; f30: valor actual de 16^k (float, transportado entre iteraciones)
; f31: acumulador de pi

; f5-f8: Floats temporales para conversiones de 8k+x para iteración k
; f9: Temporal para 1/16^k
; f10-f13: Temporales para resultados de divisiones B, C, D, E
; f14: Temporal para cálculo BCDE
; f15: Temporal para cálculo ITE

.text
.global main

main:
    ; Cargar constantes enteras a registros
    addi r1, r0, 1
    addi r2, r0, 2
    addi r3, r0, 4
    addi r4, r0, 8

    ; Cargar constantes flotantes a registros FP
    lf f1, const1_0
    lf f2, const2_0
    lf f3, const4_0
    lf f4, const16_0

    ; Cargar el número de iteraciones a realizar
    lw r10, wIteraciones

    ; Comprobar si el número de iteraciones es 0
    beqz r10, exit
    ; Si wIteraciones es 0, saltar directamente al final

    ; Inicializar k = 0
    add r11, r0, r0         
    ; k = 0
    ; Inicializar pi = 0.0
    addf f31, f0, f0        
    ; pi = 0.0
    ; Inicializar 16^k = 16^0 = 1.0
    addf f30, f0, f1        
    ; f30 (potencia actual de 16) = 1.0

    ; Inicializar desplazamiento base = 0
    add r13, r0, r0         
    ; desplazamiento = k*4 = 0

; Etiqueta de inicio del bucle (aunque no está desenrollado, se optimiza internamente)
unroll_loop: 
    ; Condición del bucle: ¿Hemos completado las iteraciones? k < wIteraciones ?
    slt r20, r11, r10       
    ; r20 = 1 si k < wIteraciones, 0 si no
    beqz r20, exit        
    ; Si r20 es 0 (k >= wIteraciones), salir del bucle

    ; --- Inicio del procesamiento para la iteración k ---

    ; c. Calcular 8*k
    mult r25, r11, r4         
    ; r25 = k * 8
    ; Almacenar 8*k en kpor8[k]
    sw kpor8(r13), r25

    ; d. Calcular 8*k+1
    addi r26, r25, 1          
    ; r26 = 8*k + 1
    ; Almacenar 8*k+1 en kpor8mas1[k]
    sw kpor8mas1(r13), r26

    ; e. Calcular 8*k+4
    addi r27, r25, 4          
    ; r27 = 8*k + 4
    ; Almacenar 8*k+4 en kpor8mas4[k]
    sw kpor8mas4(r13), r27

    ; f. Calcular 8*k+5
    addi r28, r25, 5          
    ; r28 = 8*k + 5
    ; Almacenar 8*k+5 en kpor8mas5[k]
    sw kpor8mas5(r13), r28

    ; g. Calcular 8*k+6
    addi r29, r25, 6          
    ; r29 = 8*k + 6
    ; Almacenar 8*k+6 en kpor8mas6[k]
    sw kpor8mas6(r13), r29

    ; Convertir los términos enteros 8k+x a punto flotante para la iteración k
    ; Mover entero a registro FP
    movi2fp f5, r26
    ; Convertir entero en FP a float
    cvti2f f5, f5             
    ; f5 = float(k*8+1)
    ; Mover entero a registro FP
    movi2fp f6, r27
    ; Convertir entero en FP a float
    cvti2f f6, f6             
    ; f6 = float(k*8+4)
    ; Mover entero a registro FP
    movi2fp f7, r28
    ; Convertir entero en FP a float
    cvti2f f7, f7             
    ; f7 = float(k*8+5)
    ; Mover entero a registro FP
    movi2fp f8, r29
    ; Convertir entero en FP a float
    cvti2f f8, f8             
    ; f8 = float(k*8+6)

    ; a. Almacenar 16^k (f30 contiene el valor actual calculado en la iteración anterior o inicial)
    sf potencias16(r13), f30

    ; b. Calcular 1/16^k
    divf f9, f1, f30          
    ; f9 = 1.0 / 16^k  -- INICIO DIV 1 (larga latencia)
    ; El almacenamiento de calculoA[k] se hará más tarde, cuando f9 esté listo

    ; h. Iniciar cálculo de 4/(8k+1)
    divf f10, f3, f5          
    ; f10 = 4.0 / (k*8+1) -- INICIO DIV 2 (larga latencia)
    ; i. Iniciar cálculo de 2/(8k+4)
    divf f11, f2, f6          
    ; f11 = 2.0 / (k*8+4) -- INICIO DIV 3 (larga latencia)
    ; j. Iniciar cálculo de 1/(8k+5)
    divf f12, f1, f7          
    ; f12 = 1.0 / (k*8+5) -- INICIO DIV 4 (larga latencia)
    ; k. Iniciar cálculo de 1/(8k+6)
    divf f13, f1, f8          
    ; f13 = 1.0 / (k*8+6) -- INICIO DIV 5 (larga latencia)
    ; Los almacenamientos de B, C, D, E se harán más tarde

    ; --- Trabajo Independiente (mientras las divisiones se calculan) ---

    ; Calcular la siguiente potencia: 16^(k+1) para la *próxima* iteración
    ; El resultado se guarda en f30 para el siguiente paso del bucle
    multf f30, f30, f4       
    ; f30 ahora guarda 16^(k+1) -- INICIO MUL 1 (latencia media)

    ; Incrementar k para la próxima iteración
    addi r11, r11, 1          
    ; k++

    ; Actualizar el desplazamiento de memoria para los almacenamientos de la próxima iteración
    addi r13, r13, 4          
    ; desplazamiento += 4

    ; --- Intentar usar los resultados de las divisiones ---
    ; Se necesita esperar ~19 ciclos desde el inicio de divf.
    ; Las instrucciones multf, addi, addi toman pocos ciclos. Se necesitarían muchos NOPs
    ; sin forwarding o un mejor entrelazado para evitar stalls.
    ; Este código sufrirá stalls aquí esperando los resultados.

    ; Almacenar calculoA[k] - requiere f9 (resultado de DIV 1)
    ; Usamos desplazamiento -4(r13) porque r13 ya apunta a k+1
    sf calculoA-4(r13), f9     
    ; Guarda calculoA[k]

    ; Almacenar calculoB[k] - requiere f10 (resultado de DIV 2)
    sf calculoB-4(r13), f10    
    ; Guarda calculoB[k]

    ; Almacenar calculoC[k] - requiere f11 (resultado de DIV 3)
    sf calculoC-4(r13), f11    
    ; Guarda calculoC[k]

    ; Almacenar calculoD[k] - requiere f12 (resultado de DIV 4)
    sf calculoD-4(r13), f12    
    ; Guarda calculoD[k]

    ; Almacenar calculoE[k] - requiere f13 (resultado de DIV 5)
    sf calculoE-4(r13), f13    
    ; Guarda calculoE[k]


    ; l. Calcular calculoBCDE[k] = B - C - D - E
    ; Requiere f10, f11, f12, f13 (resultados de DIV 2,3,4,5)
    ; Resultado en f14
    subf f14, f10, f11        
    ; f14 = B - C
    subf f14, f14, f12        
    ; f14 = (B - C) - D
    subf f14, f14, f13        
    ; f14 = (B - C - D) - E
    ; Almacenar calculoBCDE[k]
    sf calculoBCDE-4(r13), f14 
    ; Guarda calculoBCDE[k]

    ; m. Calcular calculoITE[k] = (1/16^k) * BCDE
    ; Requiere f9 (resultado DIV 1) y f14 (resultado BCDE)
    ; Resultado en f15
    multf f15, f9, f14        
    ; f15 = (1/16^k) * BCDE -- INICIO MUL 2 (latencia media)
    ; Almacenar calculoITE[k] (debe esperar a que multf termine)
    sf calculoITE-4(r13), f15  
    ; Guarda calculoITE[k]

    ; n. Acumular pi
    ; Requiere f15 (resultado ITE)
    addf f31, f31, f15        
    ; pi = pi_anterior + ITE[k]
    ; Almacenar el valor acumulado de pi para esta iteración k
    sf calculoPI-4(r13), f31   
    ; Guarda calculoPI[k]

    ; Volver al inicio del bucle para la siguiente iteración
    j unroll_loop

exit:
    ; f31 contiene la aproximación final de pi
    ; Finalizar el programa
    trap 0