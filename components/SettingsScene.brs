sub init()
    m.top.backgroundColor = "0x0B0F1AFF"
    m.top.backgroundURI = ""
    m.title = m.top.findNode("title")
    m.list = m.top.findNode("list")
    m.list.observeField("itemSelected", "onItem")
    m.cfg = rcLoad()
    m.results = []
    showMain()
end sub

sub setItems(titles as object)
    c = CreateObject("roSGNode", "ContentNode")
    for each t in titles
        it = c.CreateChild("ContentNode")
        it.title = t
    end for
    m.list.content = c
end sub

sub showMain()
    m.mode = "main"
    m.title.text = "Ubicación del clima"
    titles = []
    for i = 0 to m.cfg.locations.Count() - 1
        l = m.cfg.locations[i]
        t = l.name + "  ·  " + l.detail
        if i = m.cfg.selected then t = t + "   (en uso)"
        titles.Push(t)
    end for
    titles.Push("+ Agregar ubicación")
    titles.Push("Ver protector de pantalla")
    setItems(titles)
    m.list.jumpToItem = m.cfg.selected
    m.list.setFocus(true)
end sub

sub onItem()
    i = m.list.itemSelected
    if m.mode = "main"
        n = m.cfg.locations.Count()
        if i < n
            askLocation(i)
        else if i = n
            askSearch()
        else
            showPreview()
        end if
    else if m.mode = "results"
        if i < m.results.Count()
            m.cfg.locations.Push(m.results[i])
            m.cfg.selected = m.cfg.locations.Count() - 1
            rcSave(m.cfg.locations, m.cfg.selected)
        end if
        showMain()
    end if
end sub

' --- Elegir / eliminar una ubicación guardada ---
sub askLocation(i as integer)
    m.pending = i
    l = m.cfg.locations[i]
    d = CreateObject("roSGNode", "StandardMessageDialog")
    d.title = l.name
    d.message = [l.detail]
    if m.cfg.locations.Count() > 1
        d.buttons = ["Usar esta ubicación", "Eliminar", "Cancelar"]
    else
        d.buttons = ["Usar esta ubicación", "Cancelar"]
    end if
    d.observeField("buttonSelected", "onLocDialog")
    d.observeField("wasClosed", "onDialogClosed")
    m.top.dialog = d
end sub

sub onLocDialog()
    d = m.top.dialog
    label = d.buttons[d.buttonSelected]
    i = m.pending
    if label = "Usar esta ubicación"
        m.cfg.selected = i
    else if label = "Eliminar"
        m.cfg.locations.Delete(i)
        if m.cfg.selected = i
            m.cfg.selected = 0
        else if m.cfg.selected > i
            m.cfg.selected = m.cfg.selected - 1
        end if
    end if
    rcSave(m.cfg.locations, m.cfg.selected)
    d.close = true
    showMain()
end sub

sub onDialogClosed()
    m.list.setFocus(true)
end sub

' --- Buscar una nueva ---
sub askSearch()
    d = CreateObject("roSGNode", "StandardKeyboardDialog")
    d.title = "Buscar ciudad o pueblo"
    d.message = ["Por ejemplo: Montevideo, Atlántida, Salto"]
    d.buttons = ["Buscar", "Cancelar"]
    d.observeField("buttonSelected", "onSearchDialog")
    d.observeField("wasClosed", "onDialogClosed")
    m.top.dialog = d
end sub

sub onSearchDialog()
    d = m.top.dialog
    q = d.text
    d.close = true
    if d.buttonSelected <> 0 or q = invalid or q.Trim() = "" then
        m.list.setFocus(true)
        return
    end if
    m.mode = "searching"
    m.title.text = "Buscando “" + q.Trim() + "”…"
    setItems([])
    m.search = CreateObject("roSGNode", "SearchTask")
    m.search.query = q.Trim()
    m.search.observeField("results", "onResults")
    m.search.control = "RUN"
end sub

sub onResults()
    if m.mode <> "searching" then return
    m.results = m.search.results
    m.mode = "results"
    titles = []
    for each r in m.results
        titles.Push(r.name + "  ·  " + r.detail)
    end for
    if m.results.Count() = 0
        m.title.text = "Nada para “" + m.search.query + "”"
        titles.Push("Volver")
    else
        m.title.text = "¿Cuál es?"
    end if
    setItems(titles)
    m.list.jumpToItem = 0
    m.list.setFocus(true)
end sub

' --- Vista previa ---
sub showPreview()
    m.mode = "preview"
    m.preview = CreateObject("roSGNode", "RelojClimaView")
    m.top.appendChild(m.preview)
    m.preview.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back"
        if m.mode = "preview"
            m.top.removeChild(m.preview)
            m.preview = invalid
            showMain()
            return true
        else if m.mode = "results" or m.mode = "searching"
            showMain()
            return true
        end if
    end if
    return false
end function
