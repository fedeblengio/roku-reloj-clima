sub init()
    m.top.functionName = "search"
end sub

function geocode(q as string) as object
    port = CreateObject("roMessagePort")
    xfer = CreateObject("roUrlTransfer")
    xfer.SetMessagePort(port)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.SetUrl("https://geocoding-api.open-meteo.com/v1/search?count=10&language=es&name=" + xfer.Escape(q))
    if not xfer.AsyncGetToString() then return []
    msg = wait(20000, port)
    if type(msg) <> "roUrlEvent" or msg.GetResponseCode() <> 200 then return []
    json = ParseJson(msg.GetString())
    if json = invalid or json.results = invalid then return []
    return json.results
end function

function norm(s as string) as string
    s = LCase(s)
    pairs = [["á","a"],["é","e"],["í","i"],["ó","o"],["ú","u"],["ü","u"],["ñ","n"]]
    for each p in pairs
        s = s.Replace(p[0], p[1])
    end for
    return s
end function

sub search()
    ' "Las Piedras Canelones" o "Atlántida, Canelones": busca el nombre y usa el resto para priorizar
    q = m.top.query.Replace(",", " ")
    words = []
    for each w in q.Split(" ")
        if w.Trim() <> "" then words.Push(w.Trim())
    end for

    raw = []
    hints = []
    n = words.Count()
    while n > 0 and raw.Count() = 0
        name = ""
        for i = 0 to n - 1
            if i > 0 then name = name + " "
            name = name + words[i]
        end for
        raw = geocode(name)
        if raw.Count() = 0
            n = n - 1
        end if
    end while
    for i = n to words.Count() - 1
        hints.Push(norm(words[i]))
    end for

    best = []
    uy = []
    other = []
    for each r in raw
        admin = ""
        if r.admin1 <> invalid then admin = r.admin1
        admin = admin.Replace("Departamento de ", "").Replace("Provincia de ", "")
        country = ""
        if r.country <> invalid then country = r.country
        detail = admin
        if detail <> "" and country <> "" then detail = detail + ", "
        detail = detail + country
        item = { name: r.name, detail: detail, lat: r.latitude, lon: r.longitude }

        matchesHints = hints.Count() > 0
        nd = norm(detail)
        for each h in hints
            if Instr(1, nd, h) = 0 then matchesHints = false
        end for

        if matchesHints
            best.Push(item)
        else if r.country_code = "UY"
            uy.Push(item)
        else
            other.Push(item)
        end if
    end for
    out = []
    out.Append(best)
    out.Append(uy)
    out.Append(other)
    m.top.results = out
end sub
