





; -----------------------------------------------------------------------------






; Practica DLX 2024-2025: Calculo de Pi (Formula BBP)






; Version Optimizada (Loop Unrolling + Scheduling)






; Calcula la suma para k=0 hasta k=4






; -----------------------------------------------------------------------------

        .data
        .align 2         





; Alineacion a palabra (4 bytes)







; --- Constantes (minimizamos accesos a memoria cargandolas a registros) ---
float_0: .float 0.0
float_1: .float 1.0
float_2: .float 2.0
float_4: .float 4.0






; float_16: .float 16.0 





; No es necesaria si calculamos 16^k directamente







; --- Arrays para Resultados (5 elementos cada uno, 20 bytes) ---
potencias16: .space 20
calculoA:    .space 20
kpor8:       .space 20
term1_den:   .space 20
term2_den:   .space 20
term3_den:   .space 20
term4_den:   .space 20
term1:       .space 20
term2:       .space 20
term3:       .space 20
term4:       .space 20
suma_terms:  .space 20
calculoB:    .space 20







; --- Resultado final ---
suma_total:  .float 0.0

        .text
        .global main

main:
        





; --- Inicializacion Optimizada ---
        





; Cargar constantes flotantes esenciales a registros FP
        lf      f0, float_0(r0)     





; f0 = 0.0
        lf      f1, float_1(r0)     





; f1 = 1.0
        lf      f2, float_2(r0)     





; f2 = 2.0
        lf      f4, float_4(r0)     





; f4 = 4.0
        





; Constantes enteras 1, 16 usadas para calculo de potencias
        addi    r1, r0, 1           





; r1 = 1
        addi    r16, r0, 16         





; r16 = 16

        





; Cargar direcciones base de los arrays de resultados (una sola vez)
        la      r20, potencias16    





; r20 -> &potencias16
        la      r21, calculoA       





; r21 -> &calculoA
        la      r22, kpor8          





; r22 -> &kpor8
        la      r23, term1_den      





; r23 -> &term1_den
        la      r24, term2_den      





; r24 -> &term2_den
        la      r25, term3_den      





; r25 -> &term3_den
        la      r26, term4_den      





; r26 -> &term4_den
        la      r27, term1          





; r27 -> &term1
        la      r28, term2          





; r28 -> &term2
        la      r29, term3          





; r29 -> &term3
        la      r15, term4          





; r15 -> &term4 





; Reuse r15 pointer base
        la      r14, suma_terms     





; r14 -> &suma_terms 





; Reuse r14 pointer base
        la      r13, calculoB       





; r13 -> &calculoB 





; Reuse r13 pointer base

        





; Inicializar suma_total (en f30)
        addf    f30, f0, f0         





; f30 = 0.0 (Pi accumulator)

        





; ==============================================================
        





; Iteracion k=0 (Desenroscada)
        





; ==============================================================
        





; Constantes para k=0: 16^0=1, 8k=0, 8k+1=1, 8k+4=4, 8k+5=5, 8k+6=6
        





; --- Calculos k=0 (Integer parts first) ---
        addi    r17, r0, 1          





; r17 = 16^0 = 1
        sw      r17, 0(r20)         





; potencias16[0] = 1
        addi    r19, r0, 0          





; r19 = 8k = 0
        sw      r19, 0(r22)         





; kpor8[0] = 0
        addi    r30, r0, 1          





; r30 = 8k+1 = 1
        sw      r30, 0(r23)         





; term1_den[0] = 1
        addi    r31, r0, 4          





; r31 = 8k+4 = 4
        sw      r31, 0(r24)         





; term2_den[0] = 4
        addi    r9, r0, 5           





; r9 = 8k+5 = 5
        sw      r9, 0(r25)          





; term3_den[0] = 5
        addi    r7, r0, 6           





; r7 = 8k+6 = 6
        sw      r7, 0(r26)          





; term4_den[0] = 6

        





; --- Conversiones a Float k=0 (Schedule early) ---
        cvti2f  f17, r17            





; f17 = float(16^0) = 1.0
        cvti2f  f23, r30            





; f23 = float(8k+1) = 1.0
        cvti2f  f24, r31            





; f24 = float(8k+4) = 4.0
        cvti2f  f25, r9             





; f25 = float(8k+5) = 5.0
        cvti2f  f26, r7             





; f26 = float(8k+6) = 6.0

        





; --- Calculos Float k=0 (Schedule divides early, separate dependencies) ---
        divf    f18, f1, f17        





; f18 = 1/16^k = 1/1 = 1.0 (calculoA)
        divf    f27, f4, f23        





; f27 = 4/(8k+1) = 4/1 = 4.0 (term1)
        divf    f28, f2, f24        





; f28 = 2/(8k+4) = 2/4 = 0.5 (term2)
        divf    f29, f1, f25        





; f29 = 1/(8k+5) = 1/5 = 0.2 (term3)
        divf    f15, f1, f26        





; f15 = 1/(8k+6) = 1/6 ~ 0.1667 (term4)

        





; --- Stores Float k=0 (Can be scheduled after divides start) ---
        sf      f18, 0(r21)         





; calculoA[0] = f18
        sf      f27, 0(r27)         





; term1[0] = f27
        sf      f28, 0(r28)         





; term2[0] = f28
        sf      f29, 0(r29)         





; term3[0] = f29
        sf      f15, 0(r15)         





; term4[0] = f15

        





; --- Sumas / Restas / Mult k=0 (Wait for divides) ---
        subf    f14, f27, f28       





; f14 = term1 - term2
        subf    f14, f14, f29       





; f14 = (t1-t2) - term3
        subf    f14, f14, f15       





; f14 = (t1-t2-t3) - term4 (suma_terms)
        sf      f14, 0(r14)         





; suma_terms[0] = f14
        multf   f13, f18, f14       





; f13 = (1/16^k) * suma_terms (calculoB)
        sf      f13, 0(r13)         





; calculoB[0] = f13
        addf    f30, f30, f13       





; Acumular Pi = Pi + calculoB[0]

        





; ==============================================================
        





; Iteracion k=1 (Desenroscada)
        





; ==============================================================
        





; Constantes para k=1: 16^1=16, 8k=8, 8k+1=9, 8k+4=12, 8k+5=13, 8k+6=14
        





; --- Calculos k=1 (Integer parts first) ---
        addi    r17, r0, 16         





; r17 = 16^1 = 16  (Directly, was r1*r16)
        sw      r17, 4(r20)         





; potencias16[1] = 16 (Offset 4)
        addi    r19, r0, 8          





; r19 = 8k = 8
        sw      r19, 4(r22)         





; kpor8[1] = 8
        addi    r30, r19, 1         





; r30 = 8k+1 = 9
        sw      r30, 4(r23)         





; term1_den[1] = 9
        addi    r31, r19, 4         





; r31 = 8k+4 = 12
        sw      r31, 4(r24)         





; term2_den[1] = 12
        addi    r9, r19, 5          





; r9 = 8k+5 = 13
        sw      r9, 4(r25)          





; term3_den[1] = 13
        addi    r7, r19, 6          





; r7 = 8k+6 = 14
        sw      r7, 4(r26)          





; term4_den[1] = 14

        





; --- Conversiones a Float k=1 (Schedule early) ---
        cvti2f  f17, r17            





; f17 = float(16^1) = 16.0
        cvti2f  f23, r30            





; f23 = float(8k+1) = 9.0
        cvti2f  f24, r31            





; f24 = float(8k+4) = 12.0
        cvti2f  f25, r9             





; f25 = float(8k+5) = 13.0
        cvti2f  f26, r7             





; f26 = float(8k+6) = 14.0

        





; --- Calculos Float k=1 (Schedule divides early, separate dependencies) ---
        divf    f18, f1, f17        





; f18 = 1/16^k = 1/16 (calculoA)
        divf    f27, f4, f23        





; f27 = 4/(8k+1) = 4/9 (term1)
        divf    f28, f2, f24        





; f28 = 2/(8k+4) = 2/12 (term2)
        divf    f29, f1, f25        





; f29 = 1/(8k+5) = 1/13 (term3)
        divf    f15, f1, f26        





; f15 = 1/(8k+6) = 1/14 (term4)

        





; --- Stores Float k=1 (Can be scheduled after divides start) ---
        sf      f18, 4(r21)         





; calculoA[1] = f18
        sf      f27, 4(r27)         





; term1[1] = f27
        sf      f28, 4(r28)         





; term2[1] = f28
        sf      f29, 4(r29)         





; term3[1] = f29
        sf      f15, 4(r15)         





; term4[1] = f15

        





; --- Sumas / Restas / Mult k=1 (Wait for divides) ---
        subf    f14, f27, f28       





; f14 = term1 - term2
        subf    f14, f14, f29       





; f14 = (t1-t2) - term3
        subf    f14, f14, f15       





; f14 = (t1-t2-t3) - term4 (suma_terms)
        sf      f14, 4(r14)         





; suma_terms[1] = f14
        multf   f13, f18, f14       





; f13 = (1/16^k) * suma_terms (calculoB)
        sf      f13, 4(r13)         





; calculoB[1] = f13
        addf    f30, f30, f13       





; Acumular Pi = Pi + calculoB[1]

        





; ==============================================================
        





; Iteracion k=2 (Desenroscada)
        





; ==============================================================
        





; Constantes para k=2: 16^2=256, 8k=16, 8k+1=17, 8k+4=20, 8k+5=21, 8k+6=22
        





; --- Calculos k=2 (Integer parts first) ---
        mult    r17, r16, r16       





; r17 = 16*16 = 256
        sw      r17, 8(r20)         





; potencias16[2] = 256 (Offset 8)
        addi    r19, r0, 16         





; r19 = 8k = 16
        sw      r19, 8(r22)         





; kpor8[2] = 16
        addi    r30, r19, 1         





; r30 = 8k+1 = 17
        sw      r30, 8(r23)         





; term1_den[2] = 17
        addi    r31, r19, 4         





; r31 = 8k+4 = 20
        sw      r31, 8(r24)         





; term2_den[2] = 20
        addi    r9, r19, 5          





; r9 = 8k+5 = 21
        sw      r9, 8(r25)          





; term3_den[2] = 21
        addi    r7, r19, 6          





; r7 = 8k+6 = 22
        sw      r7, 8(r26)          





; term4_den[2] = 22

        





; --- Conversiones a Float k=2 (Schedule early) ---
        cvti2f  f17, r17            





; f17 = float(16^2) = 256.0
        cvti2f  f23, r30            





; f23 = float(8k+1) = 17.0
        cvti2f  f24, r31            





; f24 = float(8k+4) = 20.0
        cvti2f  f25, r9             





; f25 = float(8k+5) = 21.0
        cvti2f  f26, r7             





; f26 = float(8k+6) = 22.0

        





; --- Calculos Float k=2 (Schedule divides early) ---
        divf    f18, f1, f17        





; f18 = 1/16^k = 1/256 (calculoA)
        divf    f27, f4, f23        





; f27 = 4/(8k+1) = 4/17 (term1)
        divf    f28, f2, f24        





; f28 = 2/(8k+4) = 2/20 (term2)
        divf    f29, f1, f25        





; f29 = 1/(8k+5) = 1/21 (term3)
        divf    f15, f1, f26        





; f15 = 1/(8k+6) = 1/22 (term4)

        





; --- Stores Float k=2 (Schedule after divides start) ---
        sf      f18, 8(r21)         





; calculoA[2] = f18
        sf      f27, 8(r27)         





; term1[2] = f27
        sf      f28, 8(r28)         





; term2[2] = f28
        sf      f29, 8(r29)         





; term3[2] = f29
        sf      f15, 8(r15)         





; term4[2] = f15

        





; --- Sumas / Restas / Mult k=2 (Wait for divides) ---
        subf    f14, f27, f28       





; f14 = term1 - term2
        subf    f14, f14, f29       





; f14 = (t1-t2) - term3
        subf    f14, f14, f15       





; f14 = (t1-t2-t3) - term4 (suma_terms)
        sf      f14, 8(r14)         





; suma_terms[2] = f14
        multf   f13, f18, f14       





; f13 = (1/16^k) * suma_terms (calculoB)
        sf      f13, 8(r13)         





; calculoB[2] = f13
        addf    f30, f30, f13       





; Acumular Pi = Pi + calculoB[2]


        





; ==============================================================
        





; Iteracion k=3 (Desenroscada)
        





; ==============================================================
        





; Constantes para k=3: 16^3=4096, 8k=24, 8k+1=25, 8k+4=28, 8k+5=29, 8k+6=30
        





; --- Calculos k=3 (Integer parts first) ---
        





; r17 already has 256 from k=2
        mult    r17, r17, r16       





; r17 = 256 * 16 = 4096
        sw      r17, 12(r20)        





; potencias16[3] = 4096 (Offset 12)
        addi    r19, r0, 24         





; r19 = 8k = 24
        sw      r19, 12(r22)        





; kpor8[3] = 24
        addi    r30, r19, 1         





; r30 = 8k+1 = 25
        sw      r30, 12(r23)        





; term1_den[3] = 25
        addi    r31, r19, 4         





; r31 = 8k+4 = 28
        sw      r31, 12(r24)        





; term2_den[3] = 28
        addi    r9, r19, 5          





; r9 = 8k+5 = 29
        sw      r9, 12(r25)         





; term3_den[3] = 29
        addi    r7, r19, 6          





; r7 = 8k+6 = 30
        sw      r7, 12(r26)         





; term4_den[3] = 30

        





; --- Conversiones a Float k=3 ---
        cvti2f  f17, r17            





; f17 = float(16^3) = 4096.0
        cvti2f  f23, r30            





; f23 = float(8k+1) = 25.0
        cvti2f  f24, r31            





; f24 = float(8k+4) = 28.0
        cvti2f  f25, r9             





; f25 = float(8k+5) = 29.0
        cvti2f  f26, r7             





; f26 = float(8k+6) = 30.0

        





; --- Calculos Float k=3 ---
        divf    f18, f1, f17        





; f18 = 1/16^k = 1/4096 (calculoA)
        divf    f27, f4, f23        





; f27 = 4/(8k+1) = 4/25 (term1)
        divf    f28, f2, f24        





; f28 = 2/(8k+4) = 2/28 (term2)
        divf    f29, f1, f25        





; f29 = 1/(8k+5) = 1/29 (term3)
        divf    f15, f1, f26        





; f15 = 1/(8k+6) = 1/30 (term4)

        





; --- Stores Float k=3 ---
        sf      f18, 12(r21)        





; calculoA[3] = f18
        sf      f27, 12(r27)        





; term1[3] = f27
        sf      f28, 12(r28)        





; term2[3] = f28
        sf      f29, 12(r29)        





; term3[3] = f29
        sf      f15, 12(r15)        





; term4[3] = f15

        





; --- Sumas / Restas / Mult k=3 ---
        subf    f14, f27, f28       





; f14 = term1 - term2
        subf    f14, f14, f29       





; f14 = (t1-t2) - term3
        subf    f14, f14, f15       





; f14 = (t1-t2-t3) - term4 (suma_terms)
        sf      f14, 12(r14)        





; suma_terms[3] = f14
        multf   f13, f18, f14       





; f13 = (1/16^k) * suma_terms (calculoB)
        sf      f13, 12(r13)        





; calculoB[3] = f13
        addf    f30, f30, f13       





; Acumular Pi = Pi + calculoB[3]


        





; ==============================================================
        





; Iteracion k=4 (Desenroscada)
        





; ==============================================================
        





; Constantes para k=4: 16^4=65536, 8k=32, 8k+1=33, 8k+4=36, 8k+5=37, 8k+6=38
        





; --- Calculos k=4 (Integer parts first) ---
        





; r17 already has 4096 from k=3
        mult    r17, r17, r16       





; r17 = 4096 * 16 = 65536
        sw      r17, 16(r20)        





; potencias16[4] = 65536 (Offset 16)
        addi    r19, r0, 32         





; r19 = 8k = 32
        sw      r19, 16(r22)        





; kpor8[4] = 32
        addi    r30, r19, 1         





; r30 = 8k+1 = 33
        sw      r30, 16(r23)        





; term1_den[4] = 33
        addi    r31, r19, 4         





; r31 = 8k+4 = 36
        sw      r31, 16(r24)        





; term2_den[4] = 36
        addi    r9, r19, 5          





; r9 = 8k+5 = 37
        sw      r9, 16(r25)         





; term3_den[4] = 37
        addi    r7, r19, 6          





; r7 = 8k+6 = 38
        sw      r7, 16(r26)         





; term4_den[4] = 38

        





; --- Conversiones a Float k=4 ---
        cvti2f  f17, r17            





; f17 = float(16^4) = 65536.0
        cvti2f  f23, r30            





; f23 = float(8k+1) = 33.0
        cvti2f  f24, r31            





; f24 = float(8k+4) = 36.0
        cvti2f  f25, r9             





; f25 = float(8k+5) = 37.0
        cvti2f  f26, r7             





; f26 = float(8k+6) = 38.0

        





; --- Calculos Float k=4 ---
        divf    f18, f1, f17        





; f18 = 1/16^k = 1/65536 (calculoA)
        divf    f27, f4, f23        





; f27 = 4/(8k+1) = 4/33 (term1)
        divf    f28, f2, f24        





; f28 = 2/(8k+4) = 2/36 (term2)
        divf    f29, f1, f25        





; f29 = 1/(8k+5) = 1/37 (term3)
        divf    f15, f1, f26        





; f15 = 1/(8k+6) = 1/38 (term4)

        





; --- Stores Float k=4 ---
        sf      f18, 16(r21)        





; calculoA[4] = f18
        sf      f27, 16(r27)        





; term1[4] = f27
        sf      f28, 16(r28)        





; term2[4] = f28
        sf      f29, 16(r29)        





; term3[4] = f29
        sf      f15, 16(r15)        





; term4[4] = f15

        





; --- Sumas / Restas / Mult k=4 ---
        subf    f14, f27, f28       





; f14 = term1 - term2
        subf    f14, f14, f29       





; f14 = (t1-t2) - term3
        subf    f14, f14, f15       





; f14 = (t1-t2-t3) - term4 (suma_terms)
        sf      f14, 16(r14)        





; suma_terms[4] = f14
        multf   f13, f18, f14       





; f13 = (1/16^k) * suma_terms (calculoB)
        sf      f13, 16(r13)        





; calculoB[4] = f13
        addf    f30, f30, f13       





; Acumular Pi = Pi + calculoB[4]


        





; --- Finalizacion ---
        





; Guardar el valor final acumulado de Pi (f30) en memoria
        la      r3, suma_total      





; Cargar direccion de suma_total
        sf      f30, 0(r3)          





; Guardar el resultado final

        





; Terminar el programa
        trap    0                   





; Fin de la ejecucion