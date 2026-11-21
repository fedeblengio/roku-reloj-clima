' Ubicaciones guardadas en la memoria de la Roku
function rcLoad() as object
    sec = CreateObject("roRegistrySection", "relojclima")
    locs = invalid
    if sec.Exists("locations") then locs = ParseJson(sec.Read("locations"))
    if locs = invalid or locs.Count() = 0
        locs = [{ name: "Montevideo", detail: "Montevideo, Uruguay", lat: -34.9033, lon: -56.1882 }]
    end if
    sel = 0
    if sec.Exists("selected") then sel = sec.Read("selected").ToInt()
    if sel < 0 or sel >= locs.Count() then sel = 0
    return { locations: locs, selected: sel }
end function

sub rcSave(locs as object, sel as integer)
    sec = CreateObject("roRegistrySection", "relojclima")
    sec.Write("locations", FormatJson(locs))
    sec.Write("selected", sel.ToStr())
    sec.Flush()
end sub
