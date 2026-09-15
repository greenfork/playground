(import spork/http)

(defn- prefixes-match?
  ``Checks if prefixes of two arrays/tuples match.
  Outputs: whether prefixes matched, whether length of two inds is the same
  and how many elements matched.``
  [ind1 ind2]
  (let [l1 (length ind1) l2 (length ind2)]
    (var idx 0)
    (while (and (< idx l1) (< idx l2) (= (get ind1 idx) (get ind2 idx)))
      (++ idx))
    (def matches? (or (= idx l1) (= idx l2)))
    [matches? (= l1 l2) idx]))

(defn- copy-array [dst src]
  (var idx 0)
  (def len (length src))
  (array/clear dst)
  (when (zero? len) (break))
  (array/ensure dst len 1)
  (while (< idx len)
    (put dst idx (get src idx))
    (++ idx)))

(defn- count-keywords-in-matcher [matcher]
  (defn walker [form]
    (if (or (array? form) (tuple? form))
      (sum (walk walker form))
      (if (keyword? form) 1 0)))
  (walker matcher))

(def +default-headers+
  {"Server" "rtree"
   "Content-Type" "text/html; charset=utf8"})

# req:
# * `:head-size` - number of bytes in the http header.
# * `:headers` - table mapping header names to header values.
# * `:connection` - the connection stream for the header.
# * `:buffer` - the buffer instance that may contain extra bytes.
# * `:path` - HTTP path.
# * `:method` - HTTP method, as a string.``
(defn- return-to-response-mw [nextmw]
  (fn [req]
    (try
      (let [app-fun-res (nextmw req)
            res (case (type app-fun-res)
                  :string @{:status 200 :body app-fun-res :headers +default-headers+}
                  :buffer @{:status 200 :body app-fun-res :headers +default-headers+}
                  :struct (update (struct/to-table app-fun-res) :headers |(merge +default-headers+ $))
                  :table (update app-fun-res :headers |(merge +default-headers+ $))
                  @{:status 404 :body "Not found"})]
        (when (= (memcmp (req :method) "HEAD") 0)
          (put res :body nil))
        res)

      ([err fib]
        (debug/stacktrace fib err "ERROR ")
        {:status 500 :body "Internal Server Error"}))))

(def- +default-middlwares+ [return-to-response-mw])

(defn- app [app-fn middlewares peg-grammar]
  (def app-fn-mw (reduce (fn [app-fn mw] (mw app-fn))
                         app-fn
                         [;+default-middlwares+ ;middlewares]))
  (fn [req]
    (setdyn :peg-grammar peg-grammar)
    (setdyn :rtree/req req)
    (setdyn :rtree/matches @[])
    (setdyn :rtree/match-depth 0)
    (setdyn :rtree/tracing-enabled? false)
    (def route (req :route))
    (put req :rtree/remaining-segments
         (if (and (= (length route) 1) (= (memcmp route "/") 0))
           @[]
           (string/split "/" (string/slice route 1) 0)))
    (app-fn-mw req)))

(defn run-app [f &named middlewares host port]
  (default middlewares [])
  (http/server (app f middlewares (dyn *peg-grammar*)) host port))

(defn- string-matches?
  ``Matches route segments "foo", "foo/bar" etc.``
  [str remaining]
  # Emptry string matches anything.
  (when (empty? str) (break true))
  # Empty remaining route doesn't match anything.
  (when (empty? remaining) (break false))

  (when-let [str (if (string/has-prefix? "/" str) (string/slice str 1) str)
             str (if (string/has-suffix? "/" str) (string/slice str 0 -2) str)
             num-slashes (count |(= (chr "/") $) str)
             _ (< num-slashes (length remaining))
             route-to-match (if (zero? num-slashes)
                              (first remaining)
                              (string/join (array/slice remaining 0 (inc num-slashes)) "/"))
             [matches? in-full?] (prefixes-match? str route-to-match)]
    (when (and matches? in-full?)
      (array/remove remaining 0 (inc num-slashes)))))

(var- matcher-matches? nil) # forward declaration

(defn- array-matches?
  ``Matches route segments ["foo"], @["foo" "bar"] etc.``
  [arr remaining]
  # Emptry array matches anything.
  (when (empty? arr) (break true))
  # Empty remaining route doesn't match anything.
  (when (empty? remaining) (break false))

  (let [remaining-copy (array/slice remaining)
        all-match? (all |(matcher-matches? $ remaining-copy) arr)]
    (if all-match?
      (do
        (copy-array remaining remaining-copy)
        true)
      false)))

(defn- keyword-matches?
  ``Matches a keyword: PEG pattern, special keywords :number or :string.``
  [kw remaining]
  (when-let [segment (first remaining)]
    (case kw
      :number (when (peg/match '(* :d+ -1) segment)
                (array/remove remaining 0)
                (array/push (dyn :rtree/matches) (scan-number segment)))
      :string (do
                (array/remove remaining 0)
                (array/push (dyn :rtree/matches) segment))
      (errorf "Unrecognized keyword pattern: '%s'" kw))))

(varfn matcher-matches?
  ``Matches a `matcher` on the remaining route segments.
  `matcher` can be a string/buffer, which matches literally, a tuple/array, which
  matches sequentially each matcher within.
  When `full` is truthy, the string must mutch the entire remaining segments.
  When `full` is falsey, the match happens only on a substring.``
  [matcher remaining &named full-match?]
  (let [matches? (case (type matcher)
                   :string (string-matches? matcher remaining)
                   :buffer (string-matches? matcher remaining)
                   :number (string-matches? (string matcher) remaining)
                   :tuple (array-matches? matcher remaining)
                   :array (array-matches? matcher remaining)
                   :keyword (keyword-matches? matcher remaining)
                   (errorf "Cannot match with matcher %q" matcher))
        res (and matches? (or (not full-match?) (empty? remaining)))]
    res))

(defmacro match-route
  ``Match a route segment.``
  [options matcher & body]
  (def keywords-count (count-keywords-in-matcher matcher))
  (unless (> (length body) keywords-count)
    (errorf "There must be %d free variables to match" keywords-count))
  (def bindings (tuple/brackets ;(slice body 0 keywords-count)))
  (def body (slice body keywords-count))
  (defn method-matches? []
    (let [req-method ((dyn :rtree/req) :method)
          opt-method (options :method)]
      (or
        (not (has-key? options :method))
        (= (memcmp opt-method req-method) 0)
        # Treat HEAD as GET without response body.
        (and (= (memcmp req-method "HEAD") 0) (= (memcmp opt-method "GET") 0)))))
  (def tracing/qualifier-name (get options :qualifier-name "match-route"))

  (with-syms [$matches]
    ~(if-let [_ (,method-matches?)
              _ (,matcher-matches? ,matcher ((dyn :rtree/req) :rtree/remaining-segments)
                                   :full-match? (,options :full-match?))
              ,$matches (dyn :rtree/matches)
              ,bindings ,$matches]
       (do
         ,(when (dyn :rtree/tracing-enabled?)
            ~(do
               (eprintf "%s %s: %s%s %q matched"
                        ((dyn :rtree/req) :method) ((dyn :rtree/req) :route)
                        (string/repeat " " (* 2 (dyn :rtree/match-depth)))
                        ,tracing/qualifier-name ,matcher)
               (setdyn :rtree/match-depth (inc (dyn :rtree/match-depth)))))
         (return :rtree/return (do ,;body)))
       (do
         ,(when (dyn :rtree/tracing-enabled?)
            ~(do
               (eprintf "%s %s: %s%s %q did not match"
                        ((dyn :rtree/req) :method) ((dyn :rtree/req) :route)
                        (string/repeat " " (* 2 (dyn :rtree/match-depth)))
                        ,tracing/qualifier-name ,matcher)))
         (array/clear (dyn :rtree/matches))))))

(defmacro route
  ``Start routing by defining a return point when the route matches.``
  [& body]
  (apply prompt :rtree/return body))

(defmacro is
  ``Full match``
  [matcher & body]
  (apply match-route {:qualifier-name "is" :full-match? true} matcher body))
(defmacro on
  ``Partial match``
  [matcher & body]
  (apply match-route {:qualifier-name "on"} matcher body))
(defmacro GET
  ``Match GET HTTP method.``
  [matcher & body]
  (apply match-route {:qualifier-name "GET" :method "GET"} matcher body))
(defmacro POST
  ``Match POST HTTP method.``
  [matcher & body]
  (apply match-route {:qualifier-name "POST" :method "POST"} matcher body))

(defn redirect
  ``Redirect to path with status. Default is current path and status 303.``
  [&opt path status]
  (default path ((dyn :rtree/req) :route))
  (default status 303)
  @{:status status
    :body (string "You are being redirected to " path)
    :headers @{"Location" path}})

(defn- read-form-data [body]
  (def m (peg/match http/query-string-grammar (string/trim body)))
  (assert m "Invalid form data")
  (in m 0))

(defn- keys-to-keywords [dict]
  (def res @{})
  (loop [[k v] :pairs dict]
    (put res (keyword k) v))
  res)

(defn params
  ``Fetch all query and form parameters into a single table with keyword keys.``
  []
  (let [req (dyn :rtree/req)
        query (get req :query @{})
        form (if-let [content-type ((req :headers) "content-type")
                      _ (= (memcmp content-type "application/x-www-form-urlencoded"))
                      body (http/read-body req)]
               (read-form-data body)
               @{})
        params (merge query form)]
    (keys-to-keywords params)))

(defn enable-tracing
  ``Enable tracing for each matcher function. Must be called at the top level
  before the routing function begins.``
  []
  (setdyn :rtree/tracing-enabled? true))
