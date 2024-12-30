script({ title: "summarize-files" })

def("FILE", env.files)

$`Given the paper in FILE, write a 140 character summary of the paper
that makes the paper sound exciting and encourages readers to look at it.`