--// Quasar-X Tester v1.0.0
--// Tester terpisah untuk Quasar-X Public v2.0.1
--// Aman lintas-game: tidak memakai PlaceId khusus dan tidak membaca data akun.
--// Masukkan Discord webhook melalui kotak di UI tester; jangan commit URL rahasia ke repo.

local TESTER_VERSION = "1.0.0"
local LIBRARY_URL = "https://raw.githubusercontent.com/bismaaaa20-cloud/Test--library-main-UI-publik/main/Test"
local WEBHOOK_URL = "" -- Opsional: isi di sini hanya pada salinan pribadi, atau masukkan lewat jendela tester.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local function firstFunction(...)
    for i = 1, select("#", ...) do
        local candidate = select(i, ...)
        if type(candidate) == "function" then
            return candidate
        end
    end
    return nil
end

local requestFn = firstFunction(
    request,
    http_request,
    syn and syn.request,
    http and http.request,
    fluxus and fluxus.request,
    electron and electron.request
)

local function detectExecutor()
    local identifyFn = firstFunction(identifyexecutor, getexecutorname, getexecutor)
    if identifyFn then
        local ok, name = pcall(identifyFn)
        if ok and name ~= nil then
            return tostring(name)
        end
    end
    return "Tidak terdeteksi"
end

local executorName = detectExecutor()
local gameName = "Tidak diketahui"
local placeId = "Tidak diketahui"

pcall(function()
    gameName = tostring(game.Name)
    placeId = tostring(game.PlaceId)
end)

local results = {}
local Library = nil
local compatibility = nil
local memoryBeforeKB = nil
local memoryAfterKB = nil
local manualKeyPressCount = 0
local manualButtonClicks = 0
local callbackValues = {}

local function shortText(value, limit)
    local text = tostring(value or "-")
    text = text:gsub("[%c]", " ")
    limit = limit or 260
    if #text > limit then
        text = text:sub(1, limit) .. "..."
    end
    return text
end

local function addResult(name, status, detail)
    table.insert(results, {
        Name = tostring(name),
        Status = status,
        Detail = shortText(detail or (status == "PASS" and "OK" or "-"), 320),
    })
end

local function traceback(err)
    local message = tostring(err)
    if debug and type(debug.traceback) == "function" then
        local ok, trace = pcall(debug.traceback, message, 2)
        if ok then
            return shortText(trace, 320)
        end
    end
    return shortText(message, 320)
end

local function runCase(name, callback)
    local ok, value = pcall(callback)
    if ok then
        addResult(name, "PASS", value or "Berhasil")
    else
        addResult(name, "FAIL", traceback(value))
    end
    return ok, value
end

local function countStatuses()
    local passed, failed, info = 0, 0, 0
    for _, item in ipairs(results) do
        if item.Status == "PASS" then
            passed = passed + 1
        elseif item.Status == "FAIL" then
            failed = failed + 1
        else
            info = info + 1
        end
    end
    return passed, failed, info
end

local function buildReport()
    local passed, failed, info = countStatuses()
    local lines = {
        "Quasar-X Tester v" .. TESTER_VERSION,
        "Executor: " .. executorName,
        "Game: " .. gameName,
        "PlaceId: " .. placeId,
        "Quasar-X: " .. tostring(Library and Library.Version or "Gagal dimuat"),
        "Perangkat: Touch=" .. tostring(UserInputService.TouchEnabled)
            .. " | Keyboard=" .. tostring(UserInputService.KeyboardEnabled)
            .. " | Mouse=" .. tostring(UserInputService.MouseEnabled),
        "Hasil: " .. passed .. " PASS | " .. failed .. " FAIL | " .. info .. " INFO",
        "--------------------------------",
    }

    if memoryBeforeKB then
        table.insert(lines, "Memori Lua sebelum tes: " .. string.format("%.1f KB", memoryBeforeKB))
    end
    if memoryAfterKB then
        table.insert(lines, "Memori Lua sesudah tes: " .. string.format("%.1f KB", memoryAfterKB))
    end
    if compatibility then
        table.insert(lines, "API terdeteksi: " .. table.concat(compatibility.Supported or {}, ", "))
        if compatibility.Unsupported and #compatibility.Unsupported > 0 then
            table.insert(lines, "API tidak tersedia: " .. table.concat(compatibility.Unsupported, ", "))
        end
    end

    table.insert(lines, "--------------------------------")
    for _, item in ipairs(results) do
        local icon = item.Status == "PASS" and "[PASS]"
            or item.Status == "FAIL" and "[FAIL]" or "[INFO]"
        table.insert(lines, icon .. " " .. item.Name .. ": " .. item.Detail)
    end

    table.insert(lines, "--------------------------------")
    table.insert(lines, "Keybind F8: " .. tostring(manualKeyPressCount) .. " kali ditekan secara manual.")
    table.insert(lines, "Tombol manual: " .. tostring(manualButtonClicks) .. " kali ditekan.")
    table.insert(lines, "Laporan tidak memuat nama akun, UserId, JobId, cookie, atau token.")

    local description = table.concat(lines, "\n")
    if #description > 3900 then
        description = description:sub(1, 3800) .. "\n...laporan dipotong agar sesuai batas Discord."
    end
    return description, failed
end

local function postRawDiscord(description, failed)
    if type(WEBHOOK_URL) ~= "string" or not WEBHOOK_URL:match("^https://") then
        return false, "WEBHOOK_URL belum diisi dengan URL HTTPS."
    end
    if not requestFn then
        return false, "HTTP request API tidak tersedia pada executor ini."
    end

    local payload = {
        username = "Quasar-X Tester",
        embeds = {{
            title = failed > 0 and "Quasar-X Test — Ada Error" or "Quasar-X Test — Laporan",
            description = description,
            color = failed > 0 and 15158332 or 3066993,
            footer = { text = "Quasar-X Tester v" .. TESTER_VERSION },
        }},
        allowed_mentions = { parse = {} },
    }

    local encodeOK, body = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    if not encodeOK then
        return false, "JSONEncode gagal: " .. tostring(body)
    end

    local requestOK, response = pcall(requestFn, {
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
        },
        Body = body,
    })

    if not requestOK then
        return false, "Request webhook gagal: " .. tostring(response)
    end

    if type(response) == "table" then
        local statusCode = tonumber(response.StatusCode or response.Status)
        if response.Success == false or (statusCode and (statusCode < 200 or statusCode >= 300)) then
            return false, "Discord menolak laporan (HTTP " .. tostring(statusCode or "unknown") .. ")."
        end
    end
    return true, "Laporan terkirim."
end

local function sendReport()
    if type(WEBHOOK_URL) ~= "string" or not WEBHOOK_URL:match("^https://") then
        addResult("Discord webhook report", "INFO", "Isi WEBHOOK_URL dengan URL Discord webhook HTTPS milikmu.")
        return false, "Webhook belum diatur. Isi WEBHOOK_URL di bagian atas file tester."
    end

    local description, failed = buildReport()

    if Library and type(Library.SendDiscordWebhook) == "function" then
        local callOK, sent, response = pcall(function()
            return Library:SendDiscordWebhook(WEBHOOK_URL, {
                Username = "Quasar-X Tester",
                Embed = {
                    Title = failed > 0 and "Quasar-X Test — Ada Error" or "Quasar-X Test — Laporan",
                    Description = description,
                    Color = failed > 0 and 15158332 or 3066993,
                    Footer = "Quasar-X Tester v" .. TESTER_VERSION,
                },
            })
        end)

        if callOK and sent == true then
            addResult("Pengiriman laporan melalui Library:SendDiscordWebhook", "PASS", "Laporan terkirim.")
            return true, "Laporan berhasil dikirim ke Discord."
        end

        addResult(
            "Library:SendDiscordWebhook",
            "FAIL",
            callOK and tostring(response or sent) or tostring(sent)
        )
    end

    local fallbackOK, fallbackMessage = postRawDiscord(buildReport(), select(2, buildReport()))
    if fallbackOK then
        addResult("Pengiriman laporan melalui HTTP fallback", "PASS", fallbackMessage)
        return true, fallbackMessage
    end

    addResult("Pengiriman laporan", "FAIL", fallbackMessage)
    return false, fallbackMessage
end

local function fetchLibrarySource()
    local httpOK, source = pcall(function()
        return game:HttpGet(LIBRARY_URL)
    end)
    if httpOK and type(source) == "string" and #source > 100 then
        return source
    end

    if requestFn then
        local requestOK, response = pcall(requestFn, {
            Url = LIBRARY_URL,
            Method = "GET",
            Headers = { ["Accept"] = "text/plain" },
        })
        if requestOK and type(response) == "table" then
            local body = response.Body or response.body
            local statusCode = tonumber(response.StatusCode or response.Status)
            if type(body) == "string" and #body > 100 and (not statusCode or statusCode < 400) then
                return body
            end
        end
    end

    return nil, "Library tidak berhasil diunduh. HttpGet dan request GET gagal."
end

local source, fetchError = fetchLibrarySource()
if not source then
    addResult("Memuat file Quasar-X", "FAIL", fetchError)
    warn("[Quasar-X Tester] " .. fetchError)
    local sent, message = sendReport()
    warn("[Quasar-X Tester] " .. tostring(message))
    return
end

local compiler = firstFunction(loadstring, load)
if not compiler then
    addResult("Compiler loadstring/load", "FAIL", "Executor tidak menyediakan loadstring atau load.")
    local sent, message = sendReport()
    warn("[Quasar-X Tester] " .. tostring(message))
    return
end

local compileOK, chunkOrError = pcall(compiler, source)
if not compileOK or type(chunkOrError) ~= "function" then
    addResult("Compile file Quasar-X", "FAIL", tostring(chunkOrError))
    local sent, message = sendReport()
    warn("[Quasar-X Tester] " .. tostring(message))
    return
end

local loadOK, loadedLibrary = pcall(chunkOrError)
if not loadOK or type(loadedLibrary) ~= "table" then
    addResult("Menjalankan file Quasar-X", "FAIL", tostring(loadedLibrary))
    local sent, message = sendReport()
    warn("[Quasar-X Tester] " .. tostring(message))
    return
end

Library = loadedLibrary
addResult("Memuat file Quasar-X", "PASS", "Quasar-X v" .. tostring(Library.Version or "unknown"))

local createOK, Window = pcall(function()
    return Library:CreateWindow({
        Title = "Quasar-X Tester",
        Icon = false,
        Performance = "Low",
        RGB = false,
        AutoLoad = false,
        AutoSave = false,
        ToggleKey = Enum.KeyCode.RightControl,
    })
end)

if not createOK or not Window then
    addResult("CreateWindow / pemasangan PlayerGui", "FAIL", tostring(Window or "CreateWindow mengembalikan nil."))
    local sent, message = sendReport()
    warn("[Quasar-X Tester] " .. tostring(message))
    return
end
addResult("CreateWindow / pemasangan PlayerGui", "PASS", "ScreenGui berhasil dibuat.")

local tabOK, Tab = pcall(function()
    return Window:AddTab({ Name = "Diagnostic" })
end)

if not tabOK or not Tab then
    addResult("Window:AddTab", "FAIL", tostring(Tab or "AddTab mengembalikan nil."))
    local sent, message = sendReport()
    warn("[Quasar-X Tester] " .. tostring(message))
    return
end
addResult("Window:AddTab", "PASS", "Tab Diagnostic berhasil dibuat.")

pcall(function()
    Tab:AddSection("Pemeriksaan Komponen")
    Tab:AddLabel("Quasar-X Tester v" .. TESTER_VERSION, 30)
    Tab:AddDivider()
end)

local statusParagraph
pcall(function()
    statusParagraph = Tab:AddParagraph({
        Title = "Status pengujian",
        Content = "Menyiapkan pemeriksaan...",
        Height = 72,
    })
end)

local toggleObject, sliderObject, inputObject, dropdownObject
local progressObject, keybindObject, testButtonObject
local runTests

local function safeCreate(name, callback)
    local ok, object = pcall(callback)
    if ok and object ~= nil then
        addResult(name .. " dibuat", "PASS", "Komponen berhasil dibuat.")
        return object
    end
    addResult(name .. " dibuat", "FAIL", tostring(object or "Komponen mengembalikan nil."))
    return nil
end

toggleObject = safeCreate("AddToggle", function()
    return Tab:AddToggle({
        Name = "Toggle callback test",
        Default = false,
        Callback = function(value)
            callbackValues.Toggle = value
        end,
    })
end)

sliderObject = safeCreate("AddSlider", function()
    return Tab:AddSlider({
        Name = "Slider callback test",
        Min = 0,
        Max = 100,
        Default = 25,
        Increment = 1,
        Callback = function(value)
            callbackValues.Slider = value
        end,
    })
end)

inputObject = safeCreate("AddInput", function()
    return Tab:AddInput({
        Name = "Input callback test",
        Placeholder = "Input test",
        Callback = function(value)
            callbackValues.Input = value
        end,
    })
end)

dropdownObject = safeCreate("AddDropdown", function()
    return Tab:AddDropdown({
        Name = "Dropdown callback test",
        Options = { "Option A", "Option B", "Option C" },
        Callback = function(value)
            callbackValues.Dropdown = value
        end,
    })
end)

progressObject = safeCreate("AddProgressBar", function()
    return Tab:AddProgressBar({
        Name = "Progress callback test",
        Min = 0,
        Max = 100,
        Default = 20,
        Suffix = "%",
        Callback = function(value)
            callbackValues.Progress = value
        end,
    })
end)

local keybindChanged = nil
keybindObject = safeCreate("AddKeybind", function()
    return Tab:AddKeybind({
        Name = "Tekan F8 untuk tes keyboard",
        Default = Enum.KeyCode.F8,
        Changed = function(key)
            keybindChanged = key
        end,
        Callback = function(key)
            manualKeyPressCount = manualKeyPressCount + 1
            callbackValues.Keybind = key
            if statusParagraph then
                pcall(function()
                    statusParagraph:SetContent("F8 terdeteksi. Callback keyboard berhasil dipanggil.")
                end)
            end
        end,
    })
end)

testButtonObject = safeCreate("AddButton", function()
    return Tab:AddButton({
        Name = "Tes callback tombol",
        Text = "Klik / Fire",
        Callback = function()
            manualButtonClicks = manualButtonClicks + 1
            callbackValues.Button = "FIRED"
        end,
    })
end)

pcall(function()
    Tab:AddParagraph({
        Title = "Petunjuk",
        Content = "Tekan F8 pada keyboard untuk tes keybind. Kamu juga bisa mencoba Toggle, Slider, Input, dan Dropdown. Tekan tombol Kirim Laporan untuk mengirim hasil terbaru.",
        Height = 86,
    })
end)

local function addReportButton()
    pcall(function()
        Tab:AddInput({
            Name = "Discord Webhook URL",
            Placeholder = "Tempel URL webhook di sini",
            Callback = function(value)
                WEBHOOK_URL = tostring(value or ""):gsub("%s+$", "")
            end,
        })
    end)

    pcall(function()
        Tab:AddButton({
            Name = "Kirim laporan terbaru ke Discord",
            Text = "Kirim",
            Callback = function()
                local ok, message = sendReport()
                if statusParagraph then
                    pcall(function()
                        statusParagraph:SetContent(message)
                    end)
                end
                Window:Notify({
                    Title = ok and "Laporan terkirim" or "Gagal mengirim laporan",
                    Content = tostring(message),
                    Type = ok and "success" or "error",
                    Duration = 5,
                })
            end,
        })
    end)
end

local function addRerunButton()
    pcall(function()
        Tab:AddButton({
            Name = "Jalankan ulang semua tes",
            Text = "Tes Ulang",
            Callback = function()
                if runTests then
                    runTests(true)
                end
            end,
        })
    end)
end

runTests = function(sendAfter)
    results = {}
    addResult("Memuat file Quasar-X", "PASS", "Quasar-X v" .. tostring(Library.Version or "unknown"))
    addResult("CreateWindow / pemasangan PlayerGui", "PASS", "ScreenGui berhasil dibuat.")
    addResult("Window:AddTab", "PASS", "Tab Diagnostic berhasil dibuat.")

    if type(collectgarbage) == "function" then
        local memOK, mem = pcall(collectgarbage, "count")
        if memOK and type(mem) == "number" then
            memoryBeforeKB = mem
            addResult("Memory snapshot", "PASS", string.format("collectgarbage('count') = %.1f KB", mem))
        else
            addResult("Memory snapshot", "INFO", "API memori tidak bisa dibaca pada executor ini.")
        end
    else
        addResult("Memory snapshot", "INFO", "collectgarbage tidak tersedia.")
    end

    local compatOK, compat = pcall(function()
        return Library:CheckCompatibility()
    end)
    if compatOK and type(compat) == "table" then
        compatibility = compat
        executorName = tostring(compat.Executor or executorName)
        addResult("Library:CheckCompatibility", "PASS", "Nama executor: " .. executorName)
        addResult(
            "PlayerGui tersedia",
            compat.Capabilities and compat.Capabilities.PlayerGui == true and "PASS" or "FAIL",
            tostring(compat.Capabilities and compat.Capabilities.PlayerGui)
        )
    else
        addResult("Library:CheckCompatibility", "FAIL", tostring(compat))
    end

    addResult("Game-agnostic environment", "INFO", "Tidak memakai PlaceId khusus. Tetap perlu diuji di tiap game karena proteksi dan izin executor berbeda.")

    local synDetails = {}
    local synTablePresent = type(syn) == "table"
    table.insert(synDetails, "syn=" .. tostring(synTablePresent))
    table.insert(synDetails, "syn.request=" .. tostring(synTablePresent and type(syn.request) == "function"))
    table.insert(synDetails, "gethui=" .. tostring(type(gethui) == "function"))
    table.insert(synDetails, "getgenv=" .. tostring(type(getgenv) == "function"))
    table.insert(synDetails, "cloneref=" .. tostring(type(cloneref) == "function"))
    table.insert(synDetails, "hookfunction=" .. tostring(type(hookfunction) == "function"))
    table.insert(synDetails, "checkcaller=" .. tostring(type(checkcaller) == "function"))
    addResult("Syn / executor API snapshot", "INFO", table.concat(synDetails, " | "))

    local webhookSupported = false
    if type(Library.IsWebhookSupported) == "function" then
        local webhookOK, value = pcall(function()
            return Library:IsWebhookSupported()
        end)
        webhookSupported = webhookOK and value == true
        local webhookStatus = not webhookOK and "FAIL" or (webhookSupported and "PASS" or "INFO")
        local webhookDetail = not webhookOK and tostring(value)
            or (webhookSupported and "HTTP request tersedia." or "Executor tidak menyediakan request API yang dikenali.")
        addResult("Library:IsWebhookSupported", webhookStatus, webhookDetail)
    else
        addResult("Library:IsWebhookSupported", "FAIL", "Method tidak ditemukan.")
    end

    runCase("AddSection / AddLabel / AddDivider / AddParagraph", function()
        Tab:AddSection("Tes komponen informasi")
        Tab:AddLabel("Quasar-X label test", 30)
        Tab:AddDivider()
        local paragraph = Tab:AddParagraph({ Title = "Paragraph test", Content = "Konten awal." })
        assert(paragraph and type(paragraph.SetTitle) == "function", "Paragraph:SetTitle tidak ditemukan.")
        assert(type(paragraph.SetContent) == "function", "Paragraph:SetContent tidak ditemukan.")
        paragraph:SetTitle("Paragraph OK")
        paragraph:SetContent("SetTitle dan SetContent berhasil.")
        return "Section, Label, Divider, Paragraph, SetTitle, dan SetContent berhasil."
    end)

    runCase("AddToggle: Set / Get / Callback", function()
        assert(toggleObject, "AddToggle gagal dibuat.")
        toggleObject:Set(true)
        assert(toggleObject:Get() == true, "Get() tidak mengembalikan true.")
        assert(callbackValues.Toggle == true, "Callback tidak menerima nilai true.")
        toggleObject:Set(false)
        assert(toggleObject:Get() == false, "Get() tidak mengembalikan false.")
        assert(callbackValues.Toggle == false, "Callback tidak menerima nilai false.")
        return "Get() dan callback menerima true lalu false."
    end)

    runCase("AddSlider: Set / Get / Callback", function()
        assert(sliderObject, "AddSlider gagal dibuat.")
        sliderObject:Set(70)
        assert(sliderObject:Get() == 70, "Get() tidak mengembalikan 70.")
        assert(callbackValues.Slider == 70, "Callback tidak menerima nilai 70.")
        return "Nilai 70 diterima oleh Get() dan callback."
    end)

    runCase("AddInput: Set / Get / Callback", function()
        assert(inputObject, "AddInput gagal dibuat.")
        inputObject:Set("QUASAR_CALLBACK_TEST")
        assert(inputObject:Get() == "QUASAR_CALLBACK_TEST", "Get() tidak cocok.")
        assert(callbackValues.Input == "QUASAR_CALLBACK_TEST", "Callback tidak menerima teks uji.")
        return "Teks uji diterima oleh Get() dan callback."
    end)

    runCase("AddDropdown: Set / Get / Callback", function()
        assert(dropdownObject, "AddDropdown gagal dibuat.")
        dropdownObject:Set("Option B")
        assert(dropdownObject:Get() == "Option B", "Get() tidak mengembalikan Option B.")
        assert(callbackValues.Dropdown == "Option B", "Callback tidak menerima Option B.")
        return "Option B diterima oleh Get() dan callback."
    end)

    runCase("AddProgressBar: Set / Get / Callback", function()
        assert(progressObject, "AddProgressBar gagal dibuat.")
        progressObject:Set(80)
        assert(progressObject:Get() == 80, "Get() tidak mengembalikan 80.")
        assert(callbackValues.Progress == 80, "Callback tidak menerima nilai 80.")
        return "Nilai 80 diterima oleh Get() dan callback."
    end)

    runCase("AddButton: Fire / Callback", function()
        assert(testButtonObject, "AddButton gagal dibuat.")
        local before = manualButtonClicks
        testButtonObject:Fire()
        assert(manualButtonClicks == before + 1, "Fire() tidak memanggil callback.")
        return "Fire() berhasil memanggil callback."
    end)

    runCase("AddKeybind: Set / Get / Changed", function()
        assert(keybindObject, "AddKeybind gagal dibuat.")
        keybindObject:Set(Enum.KeyCode.F8)
        assert(keybindObject:Get() == Enum.KeyCode.F8, "Get() tidak mengembalikan F8.")
        assert(keybindChanged == Enum.KeyCode.F8, "Changed tidak menerima F8.")
        return "Set(), Get(), dan Changed berhasil. Tekan F8 untuk tes input fisik."
    end)

    runCase("Window: Show / Hide / IsVisible", function()
        assert(type(Window.Show) == "function", "Show tidak ditemukan.")
        assert(type(Window.Hide) == "function", "Hide tidak ditemukan.")
        assert(type(Window.IsVisible) == "function", "IsVisible tidak ditemukan.")
        Window:Hide()
        assert(Window:IsVisible() == false, "Window masih terlihat setelah Hide().")
        Window:Show()
        assert(Window:IsVisible() == true, "Window tidak terlihat setelah Show().")
        return "Hide() dan Show() berjalan."
    end)

    runCase("Window: Notify", function()
        Window:Notify({
            Title = "Tes selesai",
            Content = "Pemeriksaan Quasar-X selesai. Lihat laporan untuk detail.",
            Type = "success",
            Duration = 4,
        })
        return "Notifikasi berhasil dipanggil."
    end)

    if type(collectgarbage) == "function" then
        local memOK, mem = pcall(collectgarbage, "count")
        if memOK and type(mem) == "number" then
            memoryAfterKB = mem
        end
    end

    if UserInputService.KeyboardEnabled then
        addResult("Keybind callback fisik F8", "INFO", "Belum diuji otomatis. Tekan F8, lalu kirim laporan terbaru.")
    else
        addResult("Keybind callback fisik F8", "INFO", "Perangkat tidak melaporkan keyboard aktif; tes ini opsional.")
    end

    if statusParagraph then
        local passed, failed, info = countStatuses()
        pcall(function()
            statusParagraph:SetContent(
                "Tes selesai: " .. passed .. " PASS | " .. failed .. " FAIL | " .. info
                    .. " INFO. Tempel URL Discord webhook pada kotak di bawah, lalu tekan Kirim Laporan. F8 opsional."
            )
        end)
    end

    if sendAfter then
        local ok, message = sendReport()
        if statusParagraph then
            pcall(function()
                statusParagraph:SetContent(tostring(message))
            end)
        end
        warn("[Quasar-X Tester] " .. tostring(message))
    end
end

addReportButton()
addRerunButton()

-- Tes berjalan otomatis satu kali setelah UI berhasil dibuat.
-- Laporan langsung dikirim hanya jika WEBHOOK_URL sudah diatur di salinan pribadi.
-- Jika kosong, masukkan URL melalui kotak di UI lalu tekan tombol Kirim Laporan.
local autoSendConfigured = type(WEBHOOK_URL) == "string" and WEBHOOK_URL:match("^https://") ~= nil
task.spawn(function()
    runTests(autoSendConfigured)
end)

print("[Quasar-X Tester] UI diagnostic dibuat.")
print("[Quasar-X Tester] Executor: " .. executorName .. " | Game: " .. gameName .. " | PlaceId: " .. placeId)
print("[Quasar-X Tester] Tes keyboard opsional: tekan F8, lalu kirim laporan terbaru.")
