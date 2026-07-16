*** Settings ***
Documentation       Test E2E Pendaftaran User & Informasi Toko pada aplikasi MyBoss
...                 ⚠️ WAJIB jalankan Appium Server dengan flag: appium --relaxed-security

Library             AppiumLibrary


*** Variables ***
# Konfigurasi Koneksi & Capabilities
${REMOTE_URL}                           http://127.0.0.1:4723
${ANDROID_AUTOMATION_NAME}              UiAutomator2
${ANDROID_PLATFORM_NAME}                Android
${ANDROID_DEVICE_NAME}                  Android Device
${ANDROID_APP_PACKAGE}                  lpi.myboss.staging
${ANDROID_APP_ACTIVITY}                 lpi.myboss.staging.MainActivity
${ANDROID_APP_WAIT_ACTIVITY}            *
${ANDROID_NO_RESET}                     ${TRUE}

# Timeout Utama & Penstabil Koneksi
${ANDROID_NEW_COMMAND_TIMEOUT}          ${600}
${ANDROID_ADB_EXEC_TIMEOUT}             ${120000}
${ANDROID_WAIT_FOR_IDLE_TIMEOUT}        ${15000}
${ANDROID_DISABLE_WINDOW_ANIMATION}     ${TRUE}

# Data Dummy Pendaftaran User
${NO_HP}                                081398277390
${EMAIL_GOOGLE}                         ibnusanjaya2006@gmail.com
${NAMA_LENGKAP}                         Ibnu Sanjaya
${KATA_SANDI}                           Passw0rd
${PIN}                                  112233

# Data Dummy Informasi Toko
${NAMA_TOKO}                            Toko Ibnu

# Data Dummy Grosir
${KODE_GROSIR}                          CPABTN


*** Test Cases ***
E2E Pendaftaran User Hingga Informasi Toko
    [Documentation]    Melakukan pendaftaran user baru, mengisi form, melengkapi informasi toko, dan akses grosir hingga kembali ke halaman login.
    Open MyBoss Application
    Navigate To Register Page
    Fill Registration Form
    Handle Success Dialog
    Verify Store Information Page

    # === ALUR PENDAFTARAN INFORMASI TOKO ===
    Fill Store Information
    Select Map Location
    Agree To Privacy Policy
    Agree To Terms And Conditions
    Finalize Store Registration

    # === ALUR AKSES GROSIR ===
    Handle Akses Grosir Page
    Search And Enter Wholesale Code
    Handle Wholesale Success Dialog
    Verify Login Page Reached


*** Keywords ***
Open MyBoss Application
    [Documentation]    Membuka aplikasi dan mengambil alih sesi (noReset)
    Open Application    ${REMOTE_URL}
    ...    platformName=${ANDROID_PLATFORM_NAME}
    ...    deviceName=${ANDROID_DEVICE_NAME}
    ...    appPackage=${ANDROID_APP_PACKAGE}
    ...    appActivity=${ANDROID_APP_ACTIVITY}
    ...    appWaitActivity=${ANDROID_APP_WAIT_ACTIVITY}
    ...    automationName=${ANDROID_AUTOMATION_NAME}
    ...    noReset=${ANDROID_NO_RESET}
    ...    newCommandTimeout=${ANDROID_NEW_COMMAND_TIMEOUT}
    ...    adbExecTimeout=${ANDROID_ADB_EXEC_TIMEOUT}
    ...    disableWindowAnimation=${ANDROID_DISABLE_WINDOW_ANIMATION}
    Wait Until Page Contains Element    accessibility_id=Daftar    timeout=15s
    # 🚨 SLEEP 5s: Tunggu halaman Login dimuat sempurna
    Sleep    5s

Navigate To Register Page
    [Documentation]    Klik tombol Daftar dari halaman Login
    Click Element    accessibility_id=Daftar
    Wait Until Page Contains Element    accessibility_id=Pendaftaran    timeout=15s
    # 🚨 SLEEP 5s: Tunggu halaman Pendaftaran dimuat sempurna
    Sleep    5s

Type Into Field
    [Documentation]    Helper untuk klik, input teks, dan sembunyikan keyboard secara aman (Mencegah EditText bandel)
    [Arguments]    ${hint_text}    ${input_value}
    ${locator}=    Set Variable    xpath=//android.widget.EditText[contains(@hint, '${hint_text}')]
    Wait Until Page Contains Element    ${locator}    timeout=10s
    Click Element    ${locator}
    Sleep    0.5s
    Input Text    ${locator}    ${input_value}
    Run Keyword And Ignore Error    Hide Keyboard
    Sleep    0.5s

Fill Registration Form
    [Documentation]    Mengisi seluruh form pendaftaran user
    Type Into Field    Isi Nomor Handphone    ${NO_HP}

    ${email_picker}=    Set Variable
    ...    xpath=//android.view.View[@hint='Masukkan Email']/following-sibling::android.view.View[@clickable='true']
    Wait Until Page Contains Element    ${email_picker}    timeout=10s
    Click Element    ${email_picker}

    Wait Until Page Contains Element    xpath=//android.widget.TextView[@text='${EMAIL_GOOGLE}']    timeout=15s
    Click Element    xpath=//android.widget.TextView[@text='${EMAIL_GOOGLE}']/ancestor::android.widget.LinearLayout

    Wait Until Page Contains Element    xpath=//android.view.View[@text='${EMAIL_GOOGLE}']    timeout=15s
    Sleep    1s

    Type Into Field    Masukkan Nama lengkap    ${NAMA_LENGKAP}
    Type Into Field    Masukkan Password baru    ${KATA_SANDI}
    Type Into Field    Masukkan Konfirmasi Kata Sandi    ${KATA_SANDI}
    Type Into Field    Masukkan PIN    ${PIN}

    Execute Adb Shell    input swipe 360 1200 360 400 500
    Sleep    1s
    Type Into Field    Masukkan Konfirmasi PIN    ${PIN}

    Execute Adb Shell    input swipe 360 1200 360 400 500
    Sleep    1s

    Wait Until Page Contains Element    accessibility_id=Berikutnya    timeout=15s
    Click Element    accessibility_id=Berikutnya
    # 🚨 SLEEP 5s: Tunggu sistem memproses form dan pindah ke Success Dialog
    Sleep    5s

Handle Success Dialog
    [Documentation]    Menutup dialog notifikasi pendaftaran berhasil (Aman dari ValueError / Element Not Found)
    Sleep    2s

    # 1. Cek apakah halaman Informasi Toko sudah langsung terbuka (berarti tidak ada dialog)
    ${store_page_status}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[contains(@hint, 'Masukkan Nama Toko')]
    ...    timeout=3s
    IF    ${store_page_status} == ${TRUE}
        Log    Langsung masuk ke halaman Informasi Toko tanpa dialog.
        RETURN
    END

    # 2. Jika belum, coba tutup dialog dengan atribut dismissable
    ${dismiss_status}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    xpath=//android.view.View[@dismissable='true']
    ...    timeout=3s
    IF    ${dismiss_status} == ${TRUE}
        Click Element    xpath=//android.view.View[@dismissable='true']
        Sleep    1s
        RETURN
    END

    # 3. Coba cari tombol umum seperti OK, Lanjut, atau Tutup
    ${btn_status}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    xpath=//android.widget.Button[contains(@content-desc, 'OK') or contains(@content-desc, 'Lanjut') or contains(@content-desc, 'Tutup') or contains(@text, 'OK') or contains(@text, 'Lanjut')]
    ...    timeout=3s
    IF    ${btn_status} == ${TRUE}
        Click Element
        ...    xpath=//android.widget.Button[contains(@content-desc, 'OK') or contains(@content-desc, 'Lanjut') or contains(@content-desc, 'Tutup') or contains(@text, 'OK') or contains(@text, 'Lanjut')]
        Sleep    1s
        RETURN
    END

    # 4. Fallback: Tap area kosong / tengah layar untuk menutup overlay
    Run Keyword And Ignore Error    Execute Adb Shell    input tap 360 1200
    Sleep    1s

Verify Store Information Page
    [Documentation]    Memastikan masuk ke halaman Informasi Toko
    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[contains(@hint, 'Masukkan Nama Toko')]
    ...    timeout=15s
    # 🚨 SLEEP 5s: Tunggu halaman Informasi Toko stabil
    Sleep    5s

Fill Store Information
    [Documentation]    Mengisi Nama Toko
    Type Into Field    Masukkan Nama Toko    ${NAMA_TOKO}

Select Map Location
    [Documentation]    Membuka peta, memilih lokasi, dan kembali ke form
    Click Element    accessibility_id=Map location
    # 🚨 SLEEP 5s: Tunggu GPS / Maps loading
    Sleep    5s

    # CHECKPOINT: Tunggu halaman peta terbuka
    Wait Until Page Contains Element
    ...    xpath=//android.widget.Button[contains(@content-desc, 'Pilih Lokasi')]
    ...    timeout=15s
    Sleep    1s

    Click Element    xpath=//android.widget.Button[contains(@content-desc, 'Pilih Lokasi')]
    # 🚨 SLEEP 5s: Tunggu proses injection koordinat dan kembali ke form
    Sleep    5s

    # CHECKPOINT: Tunggu kembali ke halaman Informasi Toko (Menggunakan field Kode Pos yang terisi otomatis)
    # Wait Until Page Contains Element    xpath=//android.widget.EditText[contains(@text, '15143')]    timeout=15s

    # 🚨 FIX: Tutup keyboard jika muncul setelah kembali dari GPS ke form
    Run Keyword And Ignore Error    Hide Keyboard
    Sleep    1s

Agree To Privacy Policy
    [Documentation]    Buka Kebijakan Privasi, klik panah bawah webview, setujui, dan kembali
    # Scroll ke bawah untuk melihat Link
    Execute Adb Shell    input swipe 360 1200 360 400 500
    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, 'Kebijakan Privasi')]
    ...    timeout=10s

    Click Element    xpath=//android.view.View[contains(@content-desc, 'Kebijakan Privasi')]
    # 🚨 SLEEP 5s: Tunggu WebView Kebijakan Privasi di-render
    Sleep    5s

    # CHECKPOINT: Tunggu halaman Webview Privasi terbuka
    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, 'Kebijakan Privasi')]
    ...    timeout=15s
    Sleep    5s

    # Tap Panah Bawah (Tombol Overlay di pojok kanan atas) menggunakan koordinat ADB
    Execute Adb Shell    input tap 642 227
    Sleep    3s

    Wait Until Page Contains Element    xpath=//android.widget.Button[contains(@content-desc, 'Setuju')]    timeout=10s
    Click Element    xpath=//android.widget.Button[contains(@content-desc, 'Setuju')]
    # 🚨 SLEEP 5s: Tunggu aplikasi menutup WebView dan kembali ke form
    Sleep    5s

    # CHECKPOINT: Tunggu kembali ke halaman Informasi Toko
    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, 'Syarat dan Ketentuan')]
    ...    timeout=15s

    # 🚨 FIX: Sembunyikan keyboard jika muncul setelah kembali dari WebView
    Run Keyword And Ignore Error    Hide Keyboard
    Sleep    1s

Agree To Terms And Conditions
    [Documentation]    Buka S&K, klik panah bawah webview, setujui, dan kembali
    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, 'Syarat dan Ketentuan')]
    ...    timeout=10s

    Click Element    xpath=//android.view.View[contains(@content-desc, 'Syarat dan Ketentuan')]
    # 🚨 SLEEP 5s: Tunggu WebView S&K di-render
    Sleep    5s

    # CHECKPOINT: Tunggu halaman Webview S&K terbuka
    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, 'Syarat dan Ketentuan')]
    ...    timeout=15s
    Sleep    5s

    # Tap Panah Bawah (Tombol Overlay di pojok kanan atas) menggunakan koordinat ADB
    Execute Adb Shell    input tap 642 227
    Sleep    3s

    Wait Until Page Contains Element    xpath=//android.widget.Button[contains(@content-desc, 'Setuju')]    timeout=10s
    Click Element    xpath=//android.widget.Button[contains(@content-desc, 'Setuju')]
    # 🚨 SLEEP 5s: Tunggu aplikasi menutup WebView dan kembali ke form
    Sleep    5s

    # 🚨 FIX: Sembunyikan keyboard jika muncul setelah kembali dari WebView
    Sleep    2s
    Run Keyword And Ignore Error    Hide Keyboard
    Sleep    1s

    # CHECKPOINT: Tunggu kembali ke halaman Informasi Toko (Fokus ke tombol Daftar di bawah)
    Wait Until Page Contains Element    xpath=//android.widget.Button[contains(@content-desc, 'Daftar')]    timeout=15s

Finalize Store Registration
    [Documentation]    Centang persetujuan utama (jika belum) dan klik Daftar
    # Amankan klik checkbox (hanya klik jika statusnya belum dicentang oleh sistem)
    ${is_checked}=    Get Element Attribute    xpath=//android.widget.CheckBox    checked
    IF    '${is_checked}' == 'false'
        Click Element    xpath=//android.widget.CheckBox
    END

    # 🚨 FIX: Sembunyikan keyboard setelah centang checkbox sebelum klik tombol Daftar
    Run Keyword And Ignore Error    Hide Keyboard
    Sleep    0.5s

    # Validasi tombol Daftar aktif (enabled) menggunakan Custom Keyword
    Wait Until Element Is Enabled Custom
    ...    xpath=//android.widget.Button[contains(@content-desc, 'Daftar')]
    ...    timeout=15s
    Click Element    xpath=//android.widget.Button[contains(@content-desc, 'Daftar')]
    # 🚨 SLEEP 5s: Tunggu server memproses registrasi toko dan pindah ke Akses Grosir
    Sleep    5s

    # CHECKPOINT: Validasi Notifikasi Sukses Akhir
    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, 'Pendaftaran Berhasil')]
    ...    timeout=15s
    Log    Pendaftaran E2E Berhasil!

Wait Until Element Is Enabled Custom
    [Documentation]    Menunggu tombol yang awalnya disabled menjadi aktif (enabled=true)
    [Arguments]    ${locator}    ${timeout}=15s
    Wait Until Keyword Succeeds    ${timeout}    1s    Verify Element Enabled    ${locator}

Verify Element Enabled
    [Arguments]    ${locator}
    ${enabled}=    Get Element Attribute    ${locator}    enabled
    Should Be Equal As Strings    ${enabled}    true

# ==========================================
# 🚀 KODE LANJUTAN (ALUR GROSIR) 🚀
# ==========================================

Handle Akses Grosir Page
    [Documentation]    Menangani halaman awal Akses Grosir dan masuk ke halaman pencarian manual
    Wait Until Page Contains Element    accessibility_id=Akses Grosir    timeout=15s
    # 🚨 SLEEP 5s: Tunggu halaman Akses Grosir stabil
    Sleep    5s

    # 🚨 FIX: Klik area card/tombol input kode referensi manual
    ${manual_entry_btn}=    Set Variable
    ...    xpath=//android.view.View[@content-desc='Tidak ada Grosir yang ditemukan disekitar Toko Anda. Masukan Nomor Kode Referensi Grosir untuk akses ke halaman belanja']/following-sibling::android.view.View
    Wait Until Page Contains Element    ${manual_entry_btn}    timeout=10s
    Click Element    ${manual_entry_btn}
    # 🚨 SLEEP 5s: Tunggu halaman pencarian grosir manual terbuka
    Sleep    5s

    # CHECKPOINT: Tunggu halaman pencarian grosir terbuka
    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[contains(@hint, 'Cari atau ketik kode referensi')]
    ...    timeout=15s

Search And Enter Wholesale Code
    [Documentation]    Memasukkan kode referensi grosir testing dan menekan tombol masuk
    # Input kode grosir menggunakan helper Type Into Field
    Type Into Field    Cari atau ketik kode referensi    ${KODE_GROSIR}

    # Klik tombol MASUK di bagian atas (dalam halaman pencarian) untuk memproses kode
    Click Element    xpath=//android.widget.Button[@content-desc='MASUK']
    # 🚨 SLEEP 5s: Tunggu server memvalidasi kode dan memunculkan dialog sukses
    Sleep    5s

Handle Wholesale Success Dialog
    [Documentation]    Menutup notifikasi sukses penambahan grosir (Aman dari ValueError)
    Sleep    2s

    # 1. Cek apakah notifikasi sukses muncul
    ${success_status}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, 'Anda berhasil mendaftarkan grosir')]
    ...    timeout=5s
    IF    ${success_status} == ${TRUE}    Log    Dialog sukses grosir muncul.

    # 2. Coba klik overlay dismissable (tanpa bergantung pada content-desc='Dismiss' yang sering hilang)
    # Berdasarkan XML, overlay sukses memiliki atribut dismissable='true'
    ${dismiss_status}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    xpath=//android.view.View[@dismissable='true']
    ...    timeout=5s
    IF    ${dismiss_status} == ${TRUE}
        Click Element    xpath=//android.view.View[@dismissable='true']
        Sleep    2s
        RETURN
    END

    # 3. Fallback: Tap area luar dialog untuk menutup (dialog berada di tengah layar [75,475][645,1035])
    Run Keyword And Ignore Error    Execute Adb Shell    input tap 360 1400
    Sleep    2s

    # 🚨 SLEEP 5s: Tunggu aplikasi kembali ke halaman Login
    Sleep    5s

Verify Login Page Reached
    [Documentation]    Memastikan aplikasi berhasil kembali ke halaman Login setelah grosir ditambahkan (Tanpa ikut campur proses login)
    Wait Until Page Contains Element    accessibility_id=Welcome    timeout=15s
    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[contains(@hint, 'Isi Nomor Handphone')]
    ...    timeout=10s
    Log    Berhasil mencapai halaman Login. Test E2E Selesai.
