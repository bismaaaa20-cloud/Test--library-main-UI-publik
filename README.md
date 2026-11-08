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
