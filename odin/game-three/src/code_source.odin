package main

// import "base:runtime"

Code_Source :: struct {
	kind: Code_Source_Kind,
	src: string,
}

Code_Source_Kind :: enum { Pcelka_Server }

CODE_SOURCES :: [?]Code_Source{
	Code_Source{
		kind = .Pcelka_Server,
		src = #load("../assets/code_source/pcelka_server.rb", string) ,
	}
}

code_source_get :: proc(kind: Code_Source_Kind) -> Code_Source {
	for cs in CODE_SOURCES {
		if cs.kind == kind {
			return cs
		}
	}
	panic("code_source_get must find something")
}
