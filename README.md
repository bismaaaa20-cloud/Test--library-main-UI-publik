# Quasar-X Public v2.0

Library UI Roblox yang responsif untuk perangkat mobile dan desktop.

## Load

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bismaaaa20-cloud/Test--library-main-UI-publik/main/Test"))()

local Window = Library:CreateWindow({
    Title = "My UI",
    ToggleKey = Enum.KeyCode.RightControl,
    Performance = "Auto", -- "Auto", "High", atau "Low"
})

local Main = Window:AddTab({
    Name = "Main",
})

Main:AddSection("Contoh")

Main:AddToggle({
    Name = "Aktifkan fitur",
    Default = false,
    Flag = "FeatureEnabled",
    Callback = function(value)
        print("Toggle:", value)
    end,
})

Main:AddButton({
    Name = "Aksi",
    Text = "Jalankan",
    Callback = function()
        Window:Notify({
            Title = "Berhasil",
            Content = "Tombol ditekan.",
            Type = "success",
        })
    end,
})

Main:AddParagraph({
    Title = "Informasi",
    Content = "Gunakan bagian ini untuk menjelaskan fitur atau memberi petunjuk.",
})

Main:AddDivider()

local Progress = Main:AddProgressBar({
    Name = "Progress",
    Min = 0,
    Max = 100,
    Default = 35,
    Suffix = "%",
})

-- Ubah progress kapan saja:
Progress:Set(75)
```

## Diagnostik kompatibilitas executor

Gunakan pemeriksaan ini untuk melihat API yang terdeteksi pada executor saat ini. Pemeriksaan bersifat pasif dan tidak mencoba mengirim HTTP, menulis/menghapus file, atau mengakses data akun.

```lua
local report = Library:CheckCompatibility()

print("Executor:", report.Executor)
print("Versi Quasar-X:", report.Version)

for _, name in ipairs(report.Supported) do
    print("[OK]", name)
end

for _, name in ipairs(report.Unsupported) do
    warn("[TIDAK TERSEDIA]", name)
end
```

API dideteksi ulang saat fitur terkait dipakai, sehingga API yang muncul terlambat dapat dikenali. Hasil deteksi hanya menunjukkan keberadaan fungsi; bukan bukti bahwa API pasti berhasil pada semua versi executor atau semua perangkat.

## Webhook support

Quasar-X dapat mengirim JSON ke endpoint HTTPS menggunakan HTTP request API milik executor. Tidak semua executor menyediakan API tersebut; cek dahulu dengan `Library:IsWebhookSupported()`.

### Webhook umum

```lua
if Library:IsWebhookSupported() then
    local ok, response = Library:SendWebhook("https://your-webhook-endpoint.example/webhook", {
        event = "button_clicked",
        message = "Halo dari Quasar-X",
    })

    print("Webhook terkirim:", ok)
    if not ok then
        warn("Webhook gagal:", response)
    end
else
    warn("Executor ini tidak mendukung HTTP request API.")
end
```

### Discord webhook (embed)

```lua
local ok, response = Library:SendDiscordWebhook("YOUR_DISCORD_WEBHOOK_URL", {
    Username = "Quasar-X",
    Content = "Notifikasi dari UI",
    Embed = {
        Title = "Status",
        Description = "Fitur berhasil dijalankan.",
        Color = 5793266,
        Footer = "Quasar-X Public",
        Fields = {
            { Name = "Status", Value = "Success", Inline = true },
            { Name = "Version", Value = Library.Version, Inline = true },
        },
    },
})

if not ok then
    warn("Discord webhook gagal:", response)
end
```

**Keamanan:** URL Discord webhook adalah rahasia seperti password. Jangan membagikannya di script publik atau repository publik. Jangan kirim password, cookie, token, atau data pribadi pemain. Pengiriman webhook hanya berjalan saat fungsi dipanggil secara eksplisit. Webhook Discord dapat membalas HTTP 204 saat berhasil, yang dianggap sukses oleh library.

## Anti-Scam scanner

Quasar-X menyediakan pemeriksaan pola mencurigakan pada source yang diberikan oleh pemanggil. Scanner ini hanya membaca teks; **tidak menjalankan source dan tidak otomatis memblokir script**. Hasilnya adalah petunjuk untuk ditinjau pengguna/executor, bukan vonis bahwa script pasti scam atau aman.

```lua
local sourceToCheck = [[
-- Tempel source yang ingin diperiksa di sini
]]

local ok, result = Library:ScanScript(sourceToCheck)
if not ok then
    warn("Pemeriksaan gagal:", result)
else
    print("Risk:", result.Risk) -- low, review, high
    print("Score:", result.Score)
    print("Recommendation:", result.Recommendation)

    for _, finding in ipairs(result.Findings) do
        warn(finding.Severity .. ": " .. finding.Indicator)
    end
end
```

Scanner mencari beberapa indikator seperti referensi cookie/token, klaim Robux gratis/generator, endpoint webhook, dan pola loader internet. HTTP request, webhook, atau `loadstring` tidak otomatis berarti scam. Pemeriksaan pola bisa melewatkan ancaman atau memberi peringatan keliru; jangan pernah memasukkan password, cookie, token, atau data akun ke script yang tidak dipercaya.

## Fitur

- Layout responsif untuk HP portrait, HP landscape, dan desktop.
- Floating button bulat di tengah atas; bisa digeser dan digunakan untuk menyembunyikan atau membuka UI.
- Floating button kembali ke tengah atas saat orientasi layar berubah.
- Tombol toggle keyboard yang bisa diatur.
- Tab, section, pencarian kontrol, toggle, slider, dropdown, input, keybind, button, dan label.
- Paragraph untuk informasi dengan judul dan deskripsi.
- Divider untuk memisahkan kelompok kontrol.
- Progress bar yang nilainya bisa diubah melalui `Set()`.
- Notifikasi dengan tipe `info`, `success`, `warning`, dan `error`.
- Penyimpanan konfigurasi otomatis (jika fungsi file tersedia di executor).
- Pengaturan skala, tema, RGB, dan mode performa.

## API tambahan

### Window

```lua
Window:Show()                         -- tampilkan UI
Window:Hide()                         -- sembunyikan UI
Window:Toggle()                       -- ubah status tampil/sembunyi
local visible = Window:IsVisible()    -- cek status UI
Window:SetToggleKey(Enum.KeyCode.F4)  -- ganti tombol keyboard
Window:SetScale("Large")              -- "Small", "Medium", "Large", atau angka
Window:SetMaximized(true)
Window:Destroy()
```

### Notifikasi

```lua
Window:Notify({
    Title = "Peringatan",
    Content = "Contoh pesan.",
    Type = "warning", -- info, success, warning, error
    Duration = 4,
})
```

### Progress bar

```lua
local Progress = Main:AddProgressBar({
    Name = "Download",
    Min = 0,
    Max = 100,
    Default = 0,
    Suffix = "%",
    Callback = function(value)
        print(value)
    end,
})

Progress:Set(50)
print(Progress:Get())
```

### Paragraph dinamis

```lua
local Info = Main:AddParagraph({
    Title = "Status",
    Content = "Menunggu...",
})

Info:SetTitle("Selesai")
Info:SetContent("Proses berhasil.")
```

## Catatan

Fitur penyimpanan konfigurasi bergantung pada dukungan fungsi file executor. Uji script di lingkungan Roblox milik sendiri dan gunakan hanya untuk kebutuhan yang diizinkan.
