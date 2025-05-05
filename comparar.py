import struct
import csv


def float_to_uint32(x: float) -> int:
    """
    Convierte un float Python en su representación IEEE‑754 de 32 bits
    y devuelve ese patrón de bits como unsigned int.
    """
    return struct.unpack("I", struct.pack("f", x))[0]


wIter = 5

# 1) Creamos los arrays de longitud wIter con ceros
arrays_word = {
    "potencias16": [0] * wIter,
    "kpor8": [0] * wIter,
    "kpor8mas1": [0] * wIter,
    "kpor8mas4": [0] * wIter,
    "kpor8mas5": [0] * wIter,
    "kpor8mas6": [0] * wIter,
}

arrays_float = {
    "calculoA": [0] * wIter,
    "calculoB": [0] * wIter,
    "calculoC": [0] * wIter,
    "calculoD": [0] * wIter,
    "calculoE": [0] * wIter,
    "calculoBCDE": [0] * wIter,
    "calculoITE": [0] * wIter,
    "calculoPI": [0] * wIter,
}

# 2) Rellenamos los arrays word
for k in range(wIter):
    arrays_word["potencias16"][k] = 16**k
    arrays_word["kpor8"][k] = 8 * k
    arrays_word["kpor8mas1"][k] = 8 * k + 1
    arrays_word["kpor8mas4"][k] = 8 * k + 4
    arrays_word["kpor8mas5"][k] = 8 * k + 5
    arrays_word["kpor8mas6"][k] = 8 * k + 6

# 3) Calculamos y rellenamos los arrays de floats (convertidos a uint32)
pi_acumulado = 0.0
for k in range(wIter):
    pot16 = 16**k
    calcA = 1.0 / pot16
    calcB = 4.0 / (8 * k + 1)
    calcC = 2.0 / (8 * k + 4)
    calcD = 1.0 / (8 * k + 5)
    calcE = 1.0 / (8 * k + 6)
    calcBCDE = calcB - calcC - calcD - calcE
    calcITE = calcA * calcBCDE
    pi_acumulado += calcITE

    arrays_float["calculoA"][k] = float_to_uint32(calcA)
    arrays_float["calculoB"][k] = float_to_uint32(calcB)
    arrays_float["calculoC"][k] = float_to_uint32(calcC)
    arrays_float["calculoD"][k] = float_to_uint32(calcD)
    arrays_float["calculoE"][k] = float_to_uint32(calcE)
    arrays_float["calculoBCDE"][k] = float_to_uint32(calcBCDE)
    arrays_float["calculoITE"][k] = float_to_uint32(calcITE)
    arrays_float["calculoPI"][k] = float_to_uint32(pi_acumulado)

# 4) Volcamos todo a CSV en el orden de memoria (.data)
with open("memoria_practica2.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["label", "index", "valor_uint32"])

    # wIteraciones (índice en blanco)
    writer.writerow(["wIteraciones", "", wIter])

    # todos los arrays word, en el orden indicado en el PDF
    for name in [
        "potencias16",
        "kpor8",
        "kpor8mas1",
        "kpor8mas4",
        "kpor8mas5",
        "kpor8mas6",
    ]:
        for idx, val in enumerate(arrays_word[name]):
            writer.writerow([name, idx, val])

    # todos los arrays float (ya convertidos), en el mismo orden del PDF
    for name in [
        "calculoA",
        "calculoB",
        "calculoC",
        "calculoD",
        "calculoE",
        "calculoBCDE",
        "calculoITE",
        "calculoPI",
    ]:
        for idx, val in enumerate(arrays_float[name]):
            writer.writerow([name, idx, val])

print("→ memoria_practica2.csv generado correctamente (5×14 + 1 palabras).")
