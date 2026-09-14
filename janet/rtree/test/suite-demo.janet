(use spork/test)
(import spork/http)
(import ../main :as r)

(start-suite)

(defn my-app [req]
  # GET / request
  (r/is ""
    (r/redirect "/hello"))

  # /hello branch
  (r/on "hello"
    # Set variable for all routes in /hello branch
    (def greeting "Hello")

    # GET /hello/world request
    (r/GET "world"
      (string/format "%s world!" greeting))

    # /hello request
    (r/is ""
      # GET /hello request
      (r/GET ""
        (string/format "%s!" greeting))

      # POST /hello request
      (r/POST ""
        (printf "Someone said %s!" greeting)
        (r/redirect)))))

(def server (r/run-app my-app :host "127.0.0.1" :port 9816))
(defn GET [path] (http/request "GET" (string "http://127.0.0.1:9816" path)))
(defn POST [path] (http/request "POST" (string "http://127.0.0.1:9816" path)))

(let [{:status status :headers {"location" location}} (GET "/")]
  (assert (= status 303))
  (assert (= (memcmp location "/hello") 0)))
(let [{:status status :body body} (GET "/hello/world")]
  (assert (= status 200))
  (assert (= (memcmp body "Hello world!") 0)))
(let [{:status status :body body} (GET "/hello")]
  (assert (= status 200))
  (assert (= (memcmp body "Hello!") 0)))
(let [{:status status :headers {"location" location}} (POST "/hello")]
  (assert (= status 303))
  (assert (= (memcmp location "/hello") 0)))

(:close server)
(end-suite)
