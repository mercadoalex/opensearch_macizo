"""Capítulo 15: Enviar traces de ejemplo con OTEL SDK."""
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
import time

# Configurar recurso y exportador
resource = Resource.create({"service.name": "order-service"})
exporter = OTLPSpanExporter(endpoint="http://localhost:21890", insecure=True)
provider = TracerProvider(resource=resource)
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("opensearch-macizo-ch15")

# Simular 5 traces de procesamiento de órdenes
for i in range(5):
    with tracer.start_as_current_span("process-order") as parent:
        parent.set_attribute("order.id", f"ORD-{1000 + i}")
        parent.set_attribute("customer.id", f"CUST-{i % 3}")
        time.sleep(0.01)

        with tracer.start_as_current_span("validate-payment") as child:
            child.set_attribute("payment.method", "credit_card")
            time.sleep(0.02)

        with tracer.start_as_current_span("check-inventory") as child:
            child.set_attribute("warehouse", "CDMX")
            time.sleep(0.015)

        with tracer.start_as_current_span("send-notification") as child:
            child.set_attribute("channel", "email")
            time.sleep(0.005)

print("5 traces enviados a Data Prepper (localhost:21890)")
print("Verifica en OpenSearch: GET otel-v1-apm-span-*/_search")
