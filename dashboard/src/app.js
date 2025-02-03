import { instantMeiliSearch } from "@meilisearch/instant-meilisearch";

const search = instantsearch({
  indexName: "hosts",
  routing: true,
  searchClient: instantMeiliSearch("http://localhost:7700"),
});

search.addWidgets([
  instantsearch.widgets.searchBox({
    container: "#searchbox",
  }),
  instantsearch.widgets.clearRefinements({
    container: "#clear-refinements",
  }),
  instantsearch.widgets.refinementList({
    container: "#port-list",
    attribute: "port",
  }),
  instantsearch.widgets.refinementList({
    container: "#technology-list",
    attribute: "http_response.Server",
  }),
  instantsearch.widgets.configure({
    hitsPerPage: 8,
    snippetEllipsisText: "...",
    attributesToSnippet: ["description:50"],
  }),
  instantsearch.widgets.hits({
    container: "#hits",
    transformItems(items) {
      return items.map((item) => {
        item.response = item.response
          .split("\r\n")
          .map((item) => `<p>${item}</p>`)
          .join("");

        return item;
      });
    },
    templates: {
      item(hit, { html, components, sendEvent }) {
        return `
          <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300">
            <a href="#">
              <h5 class="mb-2 text-xl font-semibold text-gray-900 dark:text-white">
                ${hit.host}:${hit.port}
              </h5>
            </a>
            <div class="mb-3 text-sm text-gray-500 dark:text-gray-400">
              ${hit.http_response
                ? Object.entries(hit._highlightResult.http_response).map(
                    ([key, field]) =>
                      `<span class="font-bold">${key}:</span> ${field.value}`
                  ).join("<br/>")
                : hit._highlightResult.response.value}
            </div>
          </div>
        `;
      },
    },
  }),
  instantsearch.widgets.pagination({
    container: "#pagination",
  }),
]);

search.start();
