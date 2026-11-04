(def contents (slurp "mimes.txt"))
(def mimes @{})
(as-> contents _
      (string/split "\n" _)
      (drop 1 _)
      (drop -1 _)
      (map (fn [line]
             (let [[extensions description mime-type] (string/split "\t" line)
                   extensions (map string/trim (string/split "," extensions))
                   mime-type (string/trim mime-type)]
               (each ext extensions
                 (put mimes ext mime-type))))
           _))

(printf "%j" mimes)
