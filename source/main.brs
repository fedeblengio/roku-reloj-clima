' Protector de pantalla
sub RunScreenSaver()
    showScene("RelojClimaScene")
end sub

' Configuración desde Ajustes > Protector de pantalla
sub RunScreenSaverSettings()
    showScene("SettingsScene")
end sub

' Al abrir la app desde el inicio: configuración
sub Main()
    showScene("SettingsScene")
end sub

sub showScene(name as string)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.CreateScene(name)
    screen.Show()
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then return
    end while
end sub
