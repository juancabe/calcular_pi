.data
; --- Variables de Entrada y Salida (No modificar orden) ---
; Numero de iteraciones a realizar (0 a 4)
wIteraciones:    .word   4       

; --- Constantes en Punto Flotante ---

const1_0:        .float  1.0     
const2_0:        .float  2.0     
const4_0:        .float  4.0     
const16_0:       .float  16.0    

; --- Arrays para almacenar resultados (5 elementos de 32 bits) ---

; 16^k 
potencias16:     .space 5*4      
; 1 / 16^k
calculoA:        .space 5*4      
; 8*k (entero)
kpor8:           .space 5*4      
; 8*k+1 (entero)
kpor8mas1:       .space 5*4      
; 8*k+4 (entero)
kpor8mas4:       .space 5*4      
; 8*k+5 (entero)
kpor8mas5:       .space 5*4      
; 8*k+6 (entero)
kpor8mas6:       .space 5*4      
; 4/(8k+1)
calculoB:        .space 5*4      
; 2/(8k+4)
calculoC:        .space 5*4      
; 1/(8k+5)
calculoD:        .space 5*4      
; 1/(8k+6)
calculoE:        .space 5*4      
; B - C - D - E
calculoBCDE:     .space 5*4      
; (1/16^k) * BCDE
calculoITE:      .space 5*4      
; Valor acumulado de PI
calculoPI:       .space 5*4      

; --- Plan de Asignación de Registros (Actualizado) --- 
; Registros de propósito general: 
; r0: Registro cero (siempre con valor 0). 
; r1: Contiene constante 1 (entero). (Iniciado con addi r1, r0, 1) 
; r2: Contiene constante 2 (entero). (addi r2, r0, 2) 
; r3: Contiene constante 4 (entero). (addi r3, r0, 4) 
; r4: Contiene constante 8 (entero). (addi r4, r0, 8) 
; 
; r5: Almacena el valor actual de 16^k en forma entera. Se actualiza cada 
; iteración (r5 = 16^k), y luego se convierte a float para usar en la división. 
; r6: Contiene constante 16 (entero), calculada como (1 << 4). Se usa para 
; actualizar r5: r5 = r5 * 16. 
; 
; r10: Número de iteraciones (cargado desde wIteraciones). 
; r11: Índice o contador de iteraciones, k. 
; r13: Acumulador del desplazamiento base para los arrays, en bytes (k4). 
; 
; r20: Registro temporal para el resultado de la comparación (k < iteraciones). 
; r25: Almacena el valor 8k, calculado como r11 * r4. 
; r26: Almacena 8k + 1 (r25 + 1)
; se usa para convertir a float. 
; r27: Almacena 8k + 4 (r25 + 4)
; se usa para convertir a float. 
; r28: Almacena 8k + 5 (r25 + 5)
; se usa para convertir a float. 
; r29: Almacena 8k + 6 (r25 + 6)
; se usa para convertir a float. 
; 
; Otros registros de propósito general (no listados en el plan original) 
; se usan para operaciones temporales, según sea necesario. 
; 
; Registros de punto flotante: 
; f1: Contiene la constante 1.0. 
; f2: Contiene la constante 2.0. 
; f3: Contiene la constante 4.0. 
; f4: Contiene la constante 16.0. 
; 
; f31: Acumulador de la suma para el cálculo de π. 
; 
; f5 - f8: Uso temporal para almacenar la conversión a float de (8k+1), 
; (8k+4), (8k+5) y (8k+6) respectivamente. 
; 
; f9: Almacena el resultado de 1.0 / (16^k)
; se obtiene convirtiendo r5 a float. 
; f10: Almacena el resultado de 4.0 / (8k+1). 
; f11: Almacena el resultado de 2.0 / (8k+4). 
; f12: Almacena el resultado de 1.0 / (8k+5). 
; f13: Almacena el resultado de 1.0 / (8k+6). 
; 
; f14: Acumula la operación (B – C – D – E), es decir, f10 – f11 – f12 – f13. 
; f15: Almacena el resultado de (1/16^k) * (B – C – D – E), que se suma al acumulador f31. 
; 
; f20: Registro temporal para la conversión a float del valor entero 16^k (r5) 
; y así poder realizar la división 1.0/(16^k). 
; 
; Nota: 
; El registro f30 estaba contemplado para transportar el valor en punto flotante de 16^k, 
; pero en el código se utiliza el entero en r5 y se convierte a float en f20, por lo que 
; f30 no se emplea.

.text
.global main

main:
    addi r1, r0, 1              ; Cargar 1 en r1
    addi r2, r0, 2              ; Cargar 2 en r2
    addi r3, r0, 4              ; Cargar 4 en r3
    addi r4, r0, 8              ; Cargar 8 en r4

    lf f1, const1_0             ; Cargar 1.0 en f1
    lf f2, const2_0             ; Cargar 2.0 en f2
    lf f3, const4_0             ; Cargar 4.0 en f3
    lf f4, const16_0            ; Cargar 16.0 en f4

    lw r10, wIteraciones        ; Cargar número de iteraciones en r10
    beqz r10, exit              ; Si iteraciones 0, saltar al final

    add r11, r0, r0             ; Inicializar k = 0
    addf f31, f0, f0            ; Inicializar pi = 0.0
    add r13, r0, r0             ; Inicializar desplazamiento = 0

    addi r5, r0, 1              ; Inicializar acumulador de 16^k = 1 (entero)
    slli r6, r1, 4              ; Calcular constante entera 16: 1 << 4 = 16

; --- Inicio del bucle principal ---
loop: 
    slt r20, r11, r10           ; r20 = 1 si k < iteraciones, 0 en otro caso
    beqz r20, exit              ; Si ya no hay iteraciones, salir

    slli r25, r11, 3           ; r25 = k * 8

    addi r26, r25, 1            ; r26 = 8*k + 1
    addi r27, r25, 4            ; r27 = 8*k + 4
    addi r28, r25, 5            ; r28 = 8*k + 5
    addi r29, r25, 6            ; r29 = 8*k + 6

    movi2fp f5, r26             ; Convertir 8*k+1 a flotante
    cvti2f f5, f5               ; f5 = float(8*k+1)
    movi2fp f6, r27             ; Convertir 8*k+4 a flotante
    cvti2f f6, f6               ; f6 = float(8*k+4)
    movi2fp f7, r28             ; Convertir 8*k+5 a flotante
    cvti2f f7, f7               ; f7 = float(8*k+5)
    movi2fp f8, r29             ; Convertir 8*k+6 a flotante
    cvti2f f8, f8               ; f8 = float(8*k+6)
    movi2fp f20, r5             ; f20 = entero 16^k
    cvti2f f20, f20             ; f20 = float(16^k)

    divf f9, f1, f20            ; f9 = 1.0 / (16^k)
    divf f10, f3, f5            ; f10 = 4.0 / (8*k+1)
    divf f11, f2, f6            ; f11 = 2.0 / (8*k+4)
    divf f12, f1, f7            ; f12 = 1.0 / (8*k+5)
    divf f13, f1, f8            ; f13 = 1.0 / (8*k+6)

    slli r5, r5, 4              ; Actualizar 16^k: r5 = r5 * 16 (para (k+1))
    addi r11, r11, 1            ; Incrementar k
    addi r13, r13, 4            ; Actualizar desplazamiento para el siguiente elemento

    subf f14, f10, f11          ; f14 = B - C
    subf f14, f14, f12          ; f14 = (B - C) - D
    subf f14, f14, f13          ; f14 = (B - C - D) - E
    multf f15, f9, f14          ; f15 = (1/16^k) * BCDE

    addf f31, f31, f15          ; Acumular pi

    sf calculoA-4(r13), f9      ; Almacenar calculoA[k]
    sf calculoB-4(r13), f10     ; Almacenar calculoB[k]
    sf calculoC-4(r13), f11     ; Almacenar calculoC[k]
    sf calculoD-4(r13), f12     ; Almacenar calculoD[k]
    sf calculoE-4(r13), f13     ; Almacenar calculoE[k]
    sw kpor8(r13), r25          ; Almacenar 8*k en kpor8[k]
    sw kpor8mas1(r13), r26      ; Almacenar 8*k+1 en kpor8mas1[k]
    sw kpor8mas4(r13), r27      ; Almacenar 8*k+4 en kpor8mas4[k]
    sw kpor8mas5(r13), r28      ; Almacenar 8*k+5 en kpor8mas5[k]
    sw kpor8mas6(r13), r29      ; Almacenar 8*k+6 en kpor8mas6[k]
    sw potencias16(r13), r5     ; Almacenar 16^k (entero) en potencias16[k]
    sf calculoBCDE-4(r13), f14  ; Almacenar calculoBCDE[k]
    sf calculoITE-4(r13), f15   ; Almacenar calculoITE[k]
    sf calculoPI-4(r13), f31    ; Almacenar calculoPI[k]


    j loop               ; Volver al inicio del bucle

exit:
    trap 0                      ; Finalizar el programa