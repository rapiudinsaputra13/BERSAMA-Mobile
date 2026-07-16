*** Settings ***
Documentation       Test pembelian Produk PPOB dan proses checkout pada aplikasi MyBoss
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

# Data Test & Timeout String
${SCROLL_TIMEOUT}                       15s
${NO_PELANGGAN}                         083863767729
${PIN}                                  0103

# Variabel Produk (Ubah nilai di bawah ini untuk memilih produk dan nominal yang akan dibeli)
${KATEGORI_TRANSAKSI}                   SALDO GOPAY    # Pilihan: PULSA, TOKEN LISTRIK, SALDO GOPAY, SHOPEE, SALDO OVO, SALDO DANA, dll
${NOMINAL_PRODUK}                       Gopay 5rb    # Sesuaikan dengan teks unik pada list produk


*** Test Cases ***
Transaksi Pembelian Produk MyBoss
    [Documentation]    Skenario End-to-End pembelian Produk PPOB di aplikasi MyBoss Staging
    Open MyBoss Application
    Tap Menu Transaksi
    Tap Kategori Produk    ${KATEGORI_TRANSAKSI}
    Input Nomor Pelanggan
    Tap Produk    ${NOMINAL_PRODUK}
    Tap Tombol Bayar
    Input PIN Transaksi
    Tap Tombol Konfirmasi
    Verify Hasil Transaksi
    Tap Tombol Tutup
    Handle Pop Up Persetujuan WOI


*** Keywords ***
Open MyBoss Application
    [Documentation]    Membuka aplikasi dengan mode takeover (noReset) dan capabilities penstabil
    Open Application    ${REMOTE_URL}
    ...    platformName=${ANDROID_PLATFORM_NAME}
    ...    automationName=${ANDROID_AUTOMATION_NAME}
    ...    appPackage=${ANDROID_APP_PACKAGE}
    ...    appActivity=${ANDROID_APP_ACTIVITY}
    ...    noReset=${ANDROID_NO_RESET}
    ...    newCommandTimeout=${ANDROID_NEW_COMMAND_TIMEOUT}
    ...    adbExecTimeout=${ANDROID_ADB_EXEC_TIMEOUT}
    ...    disableWindowAnimation=${ANDROID_DISABLE_WINDOW_ANIMATION}
    # Checkpoint: Pastikan halaman Beranda sudah siap
    Wait Until Page Contains Element    accessibility_id=Transaksi    timeout=${SCROLL_TIMEOUT}

Tap Menu Transaksi
    [Documentation]    Klik menu Transaksi di Beranda
    Click Element    accessibility_id=Transaksi
    # Checkpoint: Menunggu halaman Transaksi terbuka sempurna
    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[@hint='Cari kategori transaksi...']
    ...    timeout=${SCROLL_TIMEOUT}

Tap Kategori Produk
    [Documentation]    Klik kategori produk di halaman Transaksi secara dinamis berdasarkan variabel
    [Arguments]    ${kategori}
    Click Element    xpath=//android.view.View[@content-desc='${kategori}']
    # Checkpoint: Menunggu halaman produk terbuka sempurna
    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[@hint='Masukkan nomor pelanggan']
    ...    timeout=${SCROLL_TIMEOUT}

Input Nomor Pelanggan
    [Documentation]    Input nomor pelanggan/HP (Generalisasi untuk Pulsa, E-Wallet, dan Token Listrik)
    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[@hint='Masukkan nomor pelanggan']
    ...    timeout=${SCROLL_TIMEOUT}
    Click Element    xpath=//android.widget.EditText[@hint='Masukkan nomor pelanggan']
    Input Text    xpath=//android.widget.EditText[@hint='Masukkan nomor pelanggan']    ${NO_PELANGGAN}
    Hide Keyboard
    # Checkpoint: Menunggu list produk/nominal muncul
    Wait Until Page Contains Element    accessibility_id=Pilih Nominal    timeout=${SCROLL_TIMEOUT}

Tap Produk
    [Documentation]    Pilih nominal Produk dinamis (Menggunakan 'contains' karena ada newline pada content-desc XML)
    [Arguments]    ${nominal}
    Click Element    xpath=//android.view.View[contains(@content-desc, '${nominal}')]
    # Validasi Status Tombol: Menunggu tombol Bayar aktif/muncul
    Expect Element Enabled    xpath=//android.widget.Button[@content-desc='Bayar']    timeout=${SCROLL_TIMEOUT}

Tap Tombol Bayar
    [Documentation]    Klik tombol Bayar
    Click Element    xpath=//android.widget.Button[@content-desc='Bayar']
    # Checkpoint: Menunggu halaman Konfirmasi Transaksi
    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[@hint='Masukkan PIN']
    ...    timeout=${SCROLL_TIMEOUT}

Input PIN Transaksi
    [Documentation]    Input PIN Transaksi
    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[@hint='Masukkan PIN']
    ...    timeout=${SCROLL_TIMEOUT}
    Click Element    xpath=//android.widget.EditText[@hint='Masukkan PIN']
    Sleep    1s
    Input Text    xpath=//android.widget.EditText[@hint='Masukkan PIN']    ${PIN}
    Hide Keyboard

Tap Tombol Konfirmasi
    [Documentation]    Klik tombol Konfirmasi
    Click Element    xpath=//android.widget.Button[@content-desc='Konfirmasi']

Verify Hasil Transaksi
    [Documentation]    Menunggu hasil transaksi: Bisa masuk ke halaman 'Diproses' atau halaman 'Gagal'
    ${status_diproses}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    accessibility_id=Diproses
    ...    timeout=${SCROLL_TIMEOUT}
    IF    ${status_diproses}
        Log    Transaksi berhasil masuk ke antrian (Diproses)
        Page Should Contain Text    Transaksi sedang diproses.
    ELSE
        Log    Transaksi Gagal / Produk tidak tersedia. Menunggu halaman Gagal...
        Wait Until Page Contains Element
        ...    xpath=//android.view.View[@content-desc='Gagal']
        ...    timeout=${SCROLL_TIMEOUT}
        Page Should Contain Text    Transaksi gagal.
    END

Tap Tombol Tutup
    [Documentation]    Klik tombol Tutup (Locator identik untuk halaman Diproses maupun Gagal)
    Click Element    xpath=//android.widget.Button[@content-desc='Tutup']

Handle Pop Up Persetujuan WOI
    [Documentation]    Mengecek Pop Up Persetujuan WOI (Opsional, max 5 detik). Jika muncul, tekan Back.
    ${popup_wujud}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    accessibility_id=SETUJU
    ...    timeout=5s
    IF    ${popup_wujud}    Press Keycode    4
    # Checkpoint: Pastikan kembali ke Beranda
    Wait Until Page Contains Element    accessibility_id=Transaksi    timeout=${SCROLL_TIMEOUT}

Expect Element Enabled
    [Documentation]    Custom keyword pengganti Wait Until Element Is Enabled
    [Arguments]    ${locator}    ${timeout}=${SCROLL_TIMEOUT}
    Wait Until Page Contains Element    ${locator}    timeout=${timeout}
    Element Should Be Enabled    ${locator}
