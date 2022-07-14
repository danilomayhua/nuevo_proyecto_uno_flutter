enum ActividadRequisitoRepuesta {SIN_RESPONDER, SI, NO}

class ActividadRequisito {
  final String pregunta;
  ActividadRequisitoRepuesta? respuesta;

  ActividadRequisito({required this.pregunta,
    this.respuesta = ActividadRequisitoRepuesta.SIN_RESPONDER});
}