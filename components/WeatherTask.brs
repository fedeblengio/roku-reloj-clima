sub init()
    m.top.functionName = "fetch"
end sub

sub fetch()
    url = "https://api.open-meteo.com/v1/forecast?latitude=" + m.top.lat.ToStr() + "&longitude=" + m.top.lon.ToStr()
    url = url + "&current=temperature_2m,relative_humidity_2m,weather_code,is_day"
    url = url + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=America%2FMontevideo&forecast_days=6"

    port = CreateObject("roMessagePort")
    xfer = CreateObject("roUrlTransfer")
    xfer.SetMessagePort(port)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.SetUrl(url)

    if not xfer.AsyncGetToString()
        m.top.result = { ok: false }
        return
    end if
    msg = wait(20000, port)
    if type(msg) <> "roUrlEvent" or msg.GetResponseCode() <> 200
        xfer.AsyncCancel()
        m.top.result = { ok: false }
        return
    end if

    json = ParseJson(msg.GetString())
    if json = invalid or json.current = invalid
        m.top.result = { ok: false }
        return
    end if

    c = json.current
    d = json.daily

    ' Próximos días (desde mañana)
    names = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
    days = []
    n = d.time.Count()
    for i = 1 to n - 1
        dt = CreateObject("roDateTime")
        dt.FromISO8601String(d.time[i] + "T12:00:00")
        days.Push({
            day: names[dt.GetDayOfWeek()]
            icon: iconFor(Int(d.weather_code[i]), true)
            max: rnd1(d.temperature_2m_max[i])
            min: rnd1(d.temperature_2m_min[i])
        })
    end for
    m.top.result = {
        ok: true
        temp: rnd1(c.temperature_2m)
        hum: Int(c.relative_humidity_2m)
        desc: describe(Int(c.weather_code))
        icon: iconFor(Int(c.weather_code), c.is_day = 1)
        max: rnd1(d.temperature_2m_max[0])
        min: rnd1(d.temperature_2m_min[0])
        days: days
    }
end sub

function rnd1(v) as integer
    return Cint(v)
end function

function describe(code as integer) as string
    if code = 0 then return "Despejado"
    if code = 1 then return "Mayormente despejado"
    if code = 2 then return "Parcialmente nublado"
    if code = 3 then return "Nublado"
    if code = 45 or code = 48 then return "Niebla"
    if code >= 51 and code <= 55 then return "Llovizna"
    if code = 56 or code = 57 then return "Llovizna helada"
    if code = 61 then return "Lluvia débil"
    if code = 63 then return "Lluvia"
    if code = 65 then return "Lluvia fuerte"
    if code = 66 or code = 67 then return "Lluvia helada"
    if code >= 71 and code <= 77 then return "Nieve"
    if code = 80 or code = 81 then return "Chaparrones"
    if code = 82 then return "Chaparrones fuertes"
    if code = 85 or code = 86 then return "Nieve"
    if code = 95 then return "Tormenta"
    if code = 96 or code = 99 then return "Tormenta con granizo"
    return ""
end function

function iconFor(code as integer, isDay as boolean) as string
    if isDay then dn = "day" else dn = "night"
    if code = 0 then return "clear-" + dn
    if code = 1 or code = 2 then return "partly-cloudy-" + dn
    if code = 3 then return "cloudy"
    if code = 45 or code = 48 then return "fog-" + dn
    if code >= 51 and code <= 57 then return "drizzle"
    if code = 66 or code = 67 then return "sleet"
    if (code >= 71 and code <= 77) or code = 85 or code = 86 then return "snow"
    if code = 95 then return "thunderstorms-" + dn + "-rain"
    if code = 96 or code = 99 then return "hail"
    if (code >= 61 and code <= 65) or (code >= 80 and code <= 82) then return "rain"
    return "cloudy"
end function
