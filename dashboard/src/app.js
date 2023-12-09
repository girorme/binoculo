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

        if(item.response.length > 10) item.response = item.response.substring(0,250) + "..."
        return item
      });
    },
    templates: {
      item(hit, { html, components, sendEvent }) {
        return `
          <div class="max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700">
              <a href="#">
                  <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
                    ${hit.host}:${hit.port}
                  </h5>
              </a>
              <p class="mb-3 text-slate-400">
                ${hit.response}
              </p>
          </div>
        `;
      },
    }
  }),
  instantsearch.widgets.pagination({
    container: "#pagination"
  })
]);

search.start();
