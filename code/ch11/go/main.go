// Capítulo 11: Búsqueda con opensearch-go
package main

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"

	opensearch "github.com/opensearch-project/opensearch-go/v2"
)

func main() {
	client, err := opensearch.NewClient(opensearch.Config{
		Addresses: []string{"https://localhost:9200"},
		Username:  "admin",
		Password:  "Admin123!",
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		},
	})
	if err != nil {
		log.Fatalf("Error creating client: %s", err)
	}

	// Búsqueda
	query := `{"query": {"match": {"nombre": "laptop"}}, "size": 5}`
	res, err := client.Search(
		client.Search.WithContext(context.Background()),
		client.Search.WithIndex("productos"),
		client.Search.WithBody(strings.NewReader(query)),
	)
	if err != nil {
		log.Fatalf("Search error: %s", err)
	}
	defer res.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(res.Body).Decode(&result); err != nil {
		log.Fatalf("Decode error: %s", err)
	}

	hits := result["hits"].(map[string]interface{})
	total := hits["total"].(map[string]interface{})
	fmt.Printf("Total hits: %v\n", total["value"])

	for _, hit := range hits["hits"].([]interface{}) {
		h := hit.(map[string]interface{})
		source := h["_source"].(map[string]interface{})
		fmt.Printf("  %s: %s - $%v\n", h["_id"], source["nombre"], source["precio"])
	}
}
