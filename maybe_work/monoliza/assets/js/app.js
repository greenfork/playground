function runLogsSSE(elem) {
  const sse = new EventSource("/logs");
  let counter = 0;
  sse.onmessage = (event) => {
    const newElement = document.createElement("div");

    newElement.textContent = `message: ${event.data}`;
    elem.appendChild(newElement);

    // if (counter++ === 3) sse.close();
  };
}

document.addEventListener("DOMContentLoaded", (event) => {
  document.querySelectorAll('[data-sse="logs"]').forEach((e) => runLogsSSE(e));
});
