/* FIFO statique, contexte unique : producteurs et consommateur dans main. */
#include "evq.h"
_Static_assert(EVQ_CAPACITE > 0u, "capacite non nulle");
static evq_event_t file[EVQ_CAPACITE];
static uint32_t tete, queue, nombre, debordements, total;
void evq_init(void) { tete = queue = nombre = debordements = total = 0u; }
bool evq_push(evq_type_t type, uint32_t valeur, uint32_t t_ms)
{
    if (nombre == EVQ_CAPACITE) { debordements++; return false; }
    file[queue] = (evq_event_t){type, valeur, t_ms};
    queue = (queue + 1u) % EVQ_CAPACITE;
    nombre++; total++; return true;
}
bool evq_pop(evq_event_t *e)
{
    if (!e || !nombre) return false;
    *e = file[tete]; tete = (tete + 1u) % EVQ_CAPACITE;
    nombre--; return true;
}
uint32_t evq_count(void) { return nombre; }
uint32_t evq_debordements(void) { return debordements; }
uint32_t evq_total(void) { return total; }
