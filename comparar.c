#include <stdio.h>
#include <stdint.h>

#define WITER 5

/**
 * Convierte un float (IEEE‑754 de 32 bits) en su representación
 * de 32 bits sin signo (uint32_t) conservando el patrón de bits.
 */
static uint32_t float_to_uint32(float f) {
    union {
        float    f;
        uint32_t u;
    } conv;
    conv.f = f;
    return conv.u;
}

int main(void) {
    /* Variables de entrada/salida simuladas */
    uint32_t wIteraciones = WITER;

    /* 1) Arrays de enteros (32 bits) */
    uint32_t potencias16[WITER] = {0};
    uint32_t kpor8[WITER]       = {0};
    uint32_t kpor8mas1[WITER]   = {0};
    uint32_t kpor8mas4[WITER]   = {0};
    uint32_t kpor8mas5[WITER]   = {0};
    uint32_t kpor8mas6[WITER]   = {0};

    /* 2) Arrays de floats (almacenamos como uint32_t) */
    uint32_t calculoA   [WITER] = {0};
    uint32_t calculoB   [WITER] = {0};
    uint32_t calculoC   [WITER] = {0};
    uint32_t calculoD   [WITER] = {0};
    uint32_t calculoE   [WITER] = {0};
    uint32_t calculoBCDE[WITER] = {0};
    uint32_t calculoITE [WITER] = {0};
    uint32_t calculoPI  [WITER] = {0};

    /* Rellenar arrays de enteros */
    for (int k = 0; k < WITER; ++k) {
        potencias16[k] = 1u << (4*k);        // 16^k = 2^(4k)
        kpor8[k]       = 8u * k;
        kpor8mas1[k]   = 8u * k + 1u;
        kpor8mas4[k]   = 8u * k + 4u;
        kpor8mas5[k]   = 8u * k + 5u;
        kpor8mas6[k]   = 8u * k + 6u;
    }

    /* Rellenar arrays de cálculo BBP y acumulado de PI */
    float pi_acumulado = 0.0f;
    for (int k = 0; k < WITER; ++k) {
        float pot16f    = (float)potencias16[k];          // 16^k
        float A         = 1.0f / pot16f;                  // calculoA
        float B         = 4.0f / (8.0f * k + 1.0f);       // calculoB
        float C         = 2.0f / (8.0f * k + 4.0f);       // calculoC
        float D         = 1.0f / (8.0f * k + 5.0f);       // calculoD
        float E         = 1.0f / (8.0f * k + 6.0f);       // calculoE
        float BCDE      = B - C - D - E;                  // calculoBCDE
        float ITE       = A * BCDE;                       // calculoITE

        pi_acumulado   += ITE;                            // acumulado

        calculoA   [k] = float_to_uint32(A);
        calculoB   [k] = float_to_uint32(B);
        calculoC   [k] = float_to_uint32(C);
        calculoD   [k] = float_to_uint32(D);
        calculoE   [k] = float_to_uint32(E);
        calculoBCDE[k] = float_to_uint32(BCDE);
        calculoITE [k] = float_to_uint32(ITE);
        calculoPI  [k] = float_to_uint32(pi_acumulado);
    }

    /* 3) Escribir CSV en el mismo orden de .data del PDF */
    FILE *csv = fopen("memoria_practica2.csv", "w");
    if (!csv) {
        perror("fopen");
        return 1;
    }

    fprintf(csv, "label,index,valor_uint32\n");

    /* wIteraciones */
    fprintf(csv, "wIteraciones,,%u\n", wIteraciones);

    /* Arrays de enteros */
    const char *word_names[] = {
        "potencias16", "kpor8", "kpor8mas1",
        "kpor8mas4",   "kpor8mas5", "kpor8mas6"
    };
    uint32_t *word_arrays[] = {
        potencias16, kpor8, kpor8mas1,
        kpor8mas4,   kpor8mas5, kpor8mas6
    };
    for (int a = 0; a < 6; ++a) {
        for (int k = 0; k < WITER; ++k) {
            fprintf(csv, "%s,%d,%u\n",
                    word_names[a], k, word_arrays[a][k]);
        }
    }

    /* Arrays de floats */
    const char *flt_names[] = {
        "calculoA", "calculoB", "calculoC", "calculoD",
        "calculoE", "calculoBCDE", "calculoITE", "calculoPI"
    };
    uint32_t *flt_arrays[] = {
        calculoA, calculoB, calculoC, calculoD,
        calculoE, calculoBCDE, calculoITE, calculoPI
    };
    for (int a = 0; a < 8; ++a) {
        for (int k = 0; k < WITER; ++k) {
            fprintf(csv, "%s,%d,%u\n",
                    flt_names[a], k, flt_arrays[a][k]);
        }
    }

    fclose(csv);
    return 0;
}
