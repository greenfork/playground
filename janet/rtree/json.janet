(import spork/json)

(defn json
  ``Send JSON response.``
  [payload &opt status]
  (default status 200)
  @{:status status
    :body (json/encode payload)
    :headers @{"Content-Type" "application/json"}})
