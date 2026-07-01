// Capítulo 11: Búsqueda tipada con opensearch-java
// Requiere: org.opensearch.client:opensearch-java:2.8.0

import org.opensearch.client.opensearch.OpenSearchClient;
import org.opensearch.client.opensearch.core.SearchResponse;
import org.opensearch.client.opensearch.core.search.Hit;

public class SearchExample {

    // Clase POJO para deserialización
    public record Product(String nombre, String categoria, float precio, boolean disponible) {}

    public static void main(String[] args) throws Exception {
        // Asume client ya configurado con RestClient + transport
        OpenSearchClient client = createClient();

        SearchResponse<Product> response = client.search(s -> s
            .index("productos")
            .query(q -> q
                .match(m -> m
                    .field("nombre")
                    .query("laptop")
                )
            )
            .size(5),
            Product.class
        );

        System.out.printf("Total: %d hits%n", response.hits().total().value());
        for (Hit<Product> hit : response.hits().hits()) {
            Product p = hit.source();
            System.out.printf("  %s: %s - $%.2f%n", hit.id(), p.nombre(), p.precio());
        }
    }

    private static OpenSearchClient createClient() {
        // Configuración omitida por brevedad — ver documentación oficial
        // https://opensearch.org/docs/latest/clients/java/
        throw new UnsupportedOperationException("Configure RestClient + transport");
    }
}
