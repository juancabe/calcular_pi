; -----------------------------------------------------------------------------
; Practica DLX 2024-2025: Calculo de Pi (Formula BBP)
; Version Normal (sin optimizar)
; Calcula la suma para k=0 hasta k=4
; Pi = Sum[k=0 to 4] (1/16^k) * (4/(8k+1) - 2/(8k+4) - 1/(8k+5) - 1/(8k+6))
; -----------------------------------------------------------------------------

        .data
        .align 2         ; Alineacion a palabra (4 bytes)

; --- Constantes ---
k_limit: .word 5          ; Limite superior para k (calculamos 0, 1, 2, 3, 4)

; Constantes enteras
int_0:   .word 0
int_1:   .word 1
int_2:   .word 2
int_4:   .word 4
int_5:   .word 5
int_6:   .word 6
int_8:   .word 8
int_16:  .word 16

; Constantes flotantes
float_0: .float 0.0
float_1: .float 1.0
float_2: .float 2.0
float_4: .float 4.0
float_16:.float 16.0

; --- Variables y Arrays para Resultados (5 elementos cada uno) ---
; Variables escalares para el bucle
k:           .word 0          ; Valor actual de k

; Arrays para almacenar resultados intermedios y finales por iteracion
; El tamano es 5 elementos * 4 bytes/elemento = 20 bytes
potencias16: .space 20      ; 16^k (word)
calculoA:    .space 20      ; 1/16^k (float)
kpor8:       .space 20      ; 8k (word)
term1_den:   .space 20      ; 8k+1 (word)
term2_den:   .space 20      ; 8k+4 (word)
term3_den:   .space 20      ; 8k+5 (word)
term4_den:   .space 20      ; 8k+6 (word)
term1:       .space 20      ; 4/(8k+1) (float)
term2:       .space 20      ; 2/(8k+4) (float)
term3:       .space 20      ; 1/(8k+5) (float)
term4:       .space 20      ; 1/(8k+6) (float)
suma_terms:  .space 20      ; term1 - term2 - term3 - term4 (float)
calculoB:    .space 20      ; (1/16^k) * suma_terms (float)

; Variable para el resultado final acumulado
suma_total:  .float 0.0      ; Acumulador de Pi (float)

; Mensajes (opcional, para debug)
; msg_iter: .asciiz "Iteracion k="
; msg_nl:   .asciiz "\n"

        .text
        .global main

main:
        ; --- Inicializacion ---
        ; Cargar constantes enteras a registros
        lw      r1, int_1(r0)       ; r1 = 1
        lw      r2, int_2(r0)       ; r2 = 2
        lw      r4, int_4(r0)       ; r4 = 4
        lw      r5, int_5(r0)       ; r5 = 5
        lw      r6, int_6(r0)       ; r6 = 6
        lw      r8, int_8(r0)       ; r8 = 8
        lw      r16, int_16(r0)     ; r16 = 16

        ; Cargar constantes flotantes a registros FP
        lf      f0, float_0(r0)     ; f0 = 0.0
        lf      f1, float_1(r0)     ; f1 = 1.0
        lf      f2, float_2(r0)     ; f2 = 2.0
        lf      f4, float_4(r0)     ; f4 = 4.0
        lf      f16, float_16(r0)   ; f16 = 16.0

        ; Cargar valor inicial de k (r10) y limite (r11)
        lw      r10, k(r0)          ; r10 = k = 0
        lw      r11, k_limit(r0)    ; r11 = 5

        ; Cargar direcciones base de los arrays de resultados
        la      r20, potencias16    ; r20 -> &potencias16[0]
        la      r21, calculoA       ; r21 -> &calculoA[0]
        la      r22, kpor8          ; r22 -> &kpor8[0]
        la      r23, term1_den      ; r23 -> &term1_den[0]
        la      r24, term2_den      ; r24 -> &term2_den[0]
        la      r25, term3_den      ; r25 -> &term3_den[0]
        la      r26, term4_den      ; r26 -> &term4_den[0]
        la      r27, term1          ; r27 -> &term1[0]
        la      r28, term2          ; r28 -> &term2[0]
        la      r29, term3          ; r29 -> &term3[0]
        la      r15, term4          ; r15 -> &term4[0] ; Reutilizando r15
        la      r14, suma_terms     ; r14 -> &suma_terms[0] ; Reutilizando r14
        la      r13, calculoB       ; r13 -> &calculoB[0] ; Reutilizando r13

        ; Inicializar suma_total (en f30)
        addf    f30, f0, f0         ; f30 = 0.0 (registro acumulador de Pi)

        ; --- Bucle Principal (para k=0 hasta 4) ---
loop_start:
        ; Comprobar condicion del bucle: ¿ r10 (k) < r11 (limite)?
        slt     r3, r10, r11        ; r3 = 1 si k < 5, sino 0
        beq     r3, r0, loop_end    ; Si k >= 5, saltar al final

        ; --- Calculo de 16^k (word: potencias16) ---
        ; Se necesita un pequeño bucle o subrutina. Usaremos bucle interno.
        ; r12: contador para la potencia (desde k hasta 0)
        ; r17: resultado parcial de 16^k
        add     r12, r10, r0        ; r12 = k
        add     r17, r0, r1         ; r17 = 1 (resultado inicial)
power_loop:
        beq     r12, r0, power_end  ; Si contador == 0, fin potencia
        mult    r17, r17, r16       ; resultado = resultado * 16
        subi    r12, r12, 1         ; contador--
        j       power_loop
power_end:
        ; Guardar 16^k
        sw      r17, 0(r20)         ; potencias16[k] = r17

        ; --- Calculo de 1/16^k (float: calculoA) ---
        ; Convertir 16^k (r17) a float (f17)
        cvti2f  f17, r17
        ; Dividir 1.0 (f1) por 16^k (f17) -> f18
        divf    f18, f1, f17
        ; Guardar 1/16^k
        sf      f18, 0(r21)         ; calculoA[k] = f18

        ; --- Calculo de 8k (word: kpor8) ---
        mult    r19, r10, r8        ; r19 = k * 8
        ; Guardar 8k
        sw      r19, 0(r22)         ; kpor8[k] = r19

        ; --- Calculo de denominadores (8k+1, 8k+4, 8k+5, 8k+6) ---
        ; r30, r31, r9, r7 son registros temporales para denominadores
        add     r30, r19, r1        ; r30 = 8k + 1
        sw      r30, 0(r23)         ; term1_den[k] = r30

        add     r31, r19, r4        ; r31 = 8k + 4
        sw      r31, 0(r24)         ; term2_den[k] = r31

        add     r9, r19, r5         ; r9 = 8k + 5
        sw      r9, 0(r25)          ; term3_den[k] = r9

        add     r7, r19, r6         ; r7 = 8k + 6
        sw      r7, 0(r26)          ; term4_den[k] = r7

        ; --- Calculo de los terminos (4/(8k+1), etc.) ---
        ; Convertir denominadores a float
        cvti2f  f23, r30            ; f23 = float(8k+1)
        cvti2f  f24, r31            ; f24 = float(8k+4)
        cvti2f  f25, r9             ; f25 = float(8k+5)
        cvti2f  f26, r7             ; f26 = float(8k+6)

        ; Calcular termino 1: 4 / (8k+1) -> f27
        divf    f27, f4, f23
        sf      f27, 0(r27)         ; term1[k] = f27

        ; Calcular termino 2: 2 / (8k+4) -> f28
        divf    f28, f2, f24
        sf      f28, 0(r28)         ; term2[k] = f28

        ; Calcular termino 3: 1 / (8k+5) -> f29
        divf    f29, f1, f25
        sf      f29, 0(r29)         ; term3[k] = f29

        ; Calcular termino 4: 1 / (8k+6) -> f15 (reutilizando registro FP)
        divf    f15, f1, f26
        sf      f15, 0(r15)         ; term4[k] = f15

        ; --- Calculo de la suma de terminos (term1 - term2 - term3 - term4) ---
        ; f14: resultado parcial de la suma (reutilizando registro FP)
        subf    f14, f27, f28       ; f14 = term1 - term2
        subf    f14, f14, f29       ; f14 = (term1 - term2) - term3
        subf    f14, f14, f15       ; f14 = (term1 - term2 - term3) - term4
        ; Guardar suma de terminos
        sf      f14, 0(r14)         ; suma_terms[k] = f14

        ; --- Calculo B: (1/16^k) * suma_terminos ---
        ; f13: resultado final de la iteracion (reutilizando registro FP)
        ; f18 tiene 1/16^k, f14 tiene suma_terms
        multf   f13, f18, f14
        ; Guardar calculo B
        sf      f13, 0(r13)         ; calculoB[k] = f13

        ; --- Acumular el resultado de la iteracion en suma_total ---
        addf    f30, f30, f13       ; suma_total = suma_total + calculoB[k]

        ; --- Actualizar para la siguiente iteracion ---
        ; Incrementar k
        addi    r10, r10, 1         ; k++

        ; Incrementar punteros a los arrays (avanzar 4 bytes)
        addi    r20, r20, 4
        addi    r21, r21, 4
        addi    r22, r22, 4
        addi    r23, r23, 4
        addi    r24, r24, 4
        addi    r25, r25, 4
        addi    r26, r26, 4
        addi    r27, r27, 4
        addi    r28, r28, 4
        addi    r29, r29, 4
        addi    r15, r15, 4
        addi    r14, r14, 4
        addi    r13, r13, 4

        ; Saltar al inicio del bucle
        j       loop_start

loop_end:
        ; --- Finalizacion ---
        ; Guardar el valor final acumulado de Pi (f30) en memoria
        la      r3, suma_total      ; Cargar direccion de suma_total
        sf      f30, 0(r3)          ; Guardar el resultado final

        ; Terminar el programa
        trap    0                   ; Fin de la ejecucion