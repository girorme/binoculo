import { instantMeiliSearch } from "@meilisearch/instant-meilisearch";

const search = instantsearch({
  indexName: "hosts",
  routing: true,
  searchClient: instantMeiliSearch(
      "http://localhost:7700"
    )
});

search.addWidgets([
  instantsearch.widgets.searchBox({
    container: "#searchbox"
  }),
  instantsearch.widgets.clearRefinements({
    container: "#clear-refinements"
  }),
  instantsearch.widgets.refinementList({
    container: "#port-list",
    attribute: "port"
  }),
  instantsearch.widgets.refinementList({
    container: "#product-list",
    attribute: "http_response.Server"
  }),
  instantsearch.widgets.configure({
    hitsPerPage: 8,
    snippetEllipsisText: "...",
    attributesToSnippet: ["description:50"]
  }),
  instantsearch.widgets.hits({
    container: "#hits",
    transformItems(items) {
      return items.map(item => {
        item.response = item.response.split("\r\n").map((item) => `<p>${item}</p>`).join("")
        return item
      });
    },
    templates: {
      item(hit, { html, components, sendEvent }) {
        return `
          <p>Host: ${hit.host}</p>
          <p>Port: ${hit.port}</p>
          <br>
          <p>Response</p>
          <hr>
          <p>${hit.response}</p>
        `;
      },
    }
  }),
  instantsearch.widgets.pagination({
    container: "#pagination"
  })
]);

search.start();
