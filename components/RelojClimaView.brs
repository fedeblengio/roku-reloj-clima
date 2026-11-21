sub init()
    cfg = rcLoad()
    m.loc = cfg.locations[cfg.selected]
    m.top.findNode("place").text = m.loc.name

    m.hm = m.top.findNode("hm")
    m.sec = m.top.findNode("sec")
    m.dateLbl = m.top.findNode("date")

    m.icon = m.top.findNode("icon")
    m.tempLbl = m.top.findNode("temp")
    m.descLbl = m.top.findNode("desc")
    m.extraRow = m.top.findNode("extraRow")
    m.maxLbl = m.top.findNode("max")
    m.minLbl = m.top.findNode("min")
    m.humLbl = m.top.findNode("hum")
    m.hasWeather = false

    m.days = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
    m.months = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]

    ' Reloj
    m.lastSec = -1
    updateClock()
    m.tick = m.top.findNode("tick")
    m.tick.observeField("fire", "updateClock")
    m.tick.control = "start"

    ' Corrimiento suave
    m.clockWrap = m.top.findNode("clockWrap")
    m.weatherWrap = m.top.findNode("weatherWrap")
    m.drift = m.top.findNode("driftAnim")
    m.driftClock = m.top.findNode("driftClock")
    m.driftWeather = m.top.findNode("driftWeather")
    m.driftTimer = m.top.findNode("driftTimer")
    m.driftTimer.observeField("fire", "doDrift")
    m.driftTimer.control = "start"

    ' Clima
    fetchWeather()
    m.weatherTimer = m.top.findNode("weatherTimer")
    m.weatherTimer.observeField("fire", "fetchWeather")
    m.weatherTimer.control = "start"
end sub

function pad2(n as integer) as string
    s = n.ToStr()
    if n < 10 then s = "0" + s
    return s
end function

sub updateClock()
    dt = CreateObject("roDateTime")
    dt.ToLocalTime()
    s = dt.GetSeconds()
    if s = m.lastSec then return
    m.lastSec = s
    m.hm.text = pad2(dt.GetHours()) + ":" + pad2(dt.GetMinutes())
    m.sec.text = pad2(s)
    m.dateLbl.text = m.days[dt.GetDayOfWeek()] + " " + dt.GetDayOfMonth().ToStr() + " de " + m.months[dt.GetMonth() - 1]
end sub

function randOffset(r as integer) as integer
    return Rnd(2 * r + 1) - r - 1
end function

sub doDrift()
    m.driftClock.keyValue = [m.clockWrap.translation, [randOffset(14), randOffset(14)]]
    m.driftWeather.keyValue = [m.weatherWrap.translation, [-(Rnd(18) - 1), -(Rnd(18) - 1)]]
    m.drift.control = "start"
end sub

sub fetchWeather()
    task = CreateObject("roSGNode", "WeatherTask")
    task.lat = m.loc.lat
    task.lon = m.loc.lon
    task.observeField("result", "onWeather")
    task.control = "RUN"
    m.weatherTask = task
end sub

sub onWeather()
    r = m.weatherTask.result
    if r = invalid or r.ok <> true
        if not m.hasWeather then m.descLbl.text = "Sin datos del clima"
        return
    end if
    m.hasWeather = true
    m.icon.uri = "pkg:/images/" + r.icon + ".png"
    m.tempLbl.text = r.temp.ToStr() + "°"
    m.descLbl.text = r.desc
    m.maxLbl.text = "Máx " + r.max.ToStr() + "°"
    m.minLbl.text = "Mín " + r.min.ToStr() + "°"
    m.humLbl.text = "Humedad " + r.hum.ToStr() + "%"
    m.extraRow.visible = true

    if r.days <> invalid and r.days.Count() > 0
        for i = 0 to 4
            col = m.top.findNode("f" + i.ToStr())
            if i < r.days.Count()
                d = r.days[i]
                m.top.findNode("f" + i.ToStr() + "day").text = d.day
                m.top.findNode("f" + i.ToStr() + "icon").uri = "pkg:/images/" + d.icon + ".png"
                m.top.findNode("f" + i.ToStr() + "temp").text = d.max.ToStr() + "° / " + d.min.ToStr() + "°"
                col.visible = true
            else
                col.visible = false
            end if
        end for
        m.top.findNode("forecast").visible = true
    end if
end sub
