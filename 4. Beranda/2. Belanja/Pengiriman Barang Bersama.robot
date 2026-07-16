*** Settings ***
Documentation       Skenario Automasi MyBoss - ADB Swipe dengan Checkpoint Ketat
...                 Mencegah swipe salah tempat dengan menunggu elemen unik halaman muncul.
...                 UPDATE 1: Checkpoint halaman pengiriman barang kini menggunakan Kode DL, bukan kata 'GROSIR'.
...                 UPDATE 2: Penanganan Pop Up Aktivasi WOI yang mungkin muncul di halaman Beranda.
...                 FIX: Perbaikan unpacking variable pada Run Keyword And Return Status.

Library             AppiumLibrary
Library             Collections


*** Variables ***
${REMOTE_URL}           http://127.0.0.1:4723
${PLATFORM_NAME}        Android
${DEVICE_NAME}          Android Device
${APP_PACKAGE}          lpi.myboss.staging
${APP_ACTIVITY}         lpi.myboss.staging.MainActivity
${AUTOMATION_NAME}      UiAutomator2

${DL_CODE}              DL2607000001899918
${ALASAN_SELESAI}       The store is closed.

${WAIT_TIMEOUT}         ${15}
${NEW_CMD_TIMEOUT}      ${600}
${ADB_EXEC_TIMEOUT}     ${120000}
${BOOLEAN_TRUE}         ${TRUE}
${NO_RESET}             ${TRUE}

# Perintah ADB Swipe (X: Tengah, Y: Bawah ke Atas, Durasi: 300ms)
${ADB_SWIPE_CMD}        input swipe 360 1200 360 500 300
# Perintah ADB Back (Keyevent 4 untuk menutup pop up)
${ADB_BACK_CMD}         input keyevent 4


*** Test Cases ***
Skenario Pengiriman Barang Dari Beranda Hingga Selesai
    [Tags]    myboss    pengiriman    adb_strict_checkpoint

    Sambung Ke Aplikasi MyBoss
    Pilih Menu Aktivitas Belanja
    Masuk Ke Menu Pengiriman Barang    ${DL_CODE}
    Pilih Dokumen Pengiriman Berdasarkan Kode DL    ${DL_CODE}
    Konfirmasi Dan Mulai Pengiriman
    Selesaikan Pengiriman Dan Pilih Alasan    ${ALASAN_SELESAI}
    Verifikasi Pop Up Sukses
    Kembali Ke Beranda


*** Keywords ***
Sambung Ke Aplikasi MyBoss
    Open Application    ${REMOTE_URL}
    ...    platformName=${PLATFORM_NAME}    deviceName=${DEVICE_NAME}
    ...    appPackage=${APP_PACKAGE}    appActivity=${APP_ACTIVITY}
    ...    automationName=${AUTOMATION_NAME}    noReset=${NO_RESET}
    ...    newCommandTimeout=${NEW_CMD_TIMEOUT}    adbExecTimeout=${ADB_EXEC_TIMEOUT}
    ...    disableWindowAnimation=${BOOLEAN_TRUE}
    Wait Until Element Is Visible    accessibility_id=Aktivitas    timeout=${WAIT_TIMEOUT}

Pilih Menu Aktivitas Belanja
    Click Element    accessibility_id=Aktivitas
    Wait Until Element Is Visible    accessibility_id=Aktivitas Belanja    timeout=${WAIT_TIMEOUT}
    Click Element    accessibility_id=Aktivitas Belanja
    Wait Until Element Is Visible    accessibility_id=Pengiriman Barang    timeout=${WAIT_TIMEOUT}

Masuk Ke Menu Pengiriman Barang
    [Arguments]    ${kode_dl}
    Click Element    accessibility_id=Pengiriman Barang

    # 🛑 CHECKPOINT (DIPERBARUI): Menunggu elemen Kode DL muncul di halaman.
    # Menggantikan pencarian kata 'GROSIR' karena nama grosir (seperti CVS PESONA BANTEN)
    # terkadang tidak mengandung kata "GROSIR".
    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, '${kode_dl}')]
    ...    timeout=${WAIT_TIMEOUT}

Pilih Dokumen Pengiriman Berdasarkan Kode DL
    [Arguments]    ${kode_dl}
    # Proses Tap / Click tetap menggunakan Kode DL untuk memastikan elemen yang dipilih akurat
    ${locator_dl}=    Set Variable    xpath=//android.view.View[contains(@content-desc, '${kode_dl}')]
    Wait Until Element Is Visible    ${locator_dl}    timeout=${WAIT_TIMEOUT}
    Click Element    ${locator_dl}
    Wait Until Element Is Visible    accessibility_id=Mulai Pengiriman    timeout=${WAIT_TIMEOUT}

Konfirmasi Dan Mulai Pengiriman
    Click Element    accessibility_id=Mulai Pengiriman
    Wait Until Element Is Visible    accessibility_id=Lanjutkan    timeout=${WAIT_TIMEOUT}
    Click Element    accessibility_id=Lanjutkan

    # 🛑 CHECKPOINT 1: Memastikan kita SUDAH di halaman Detail Pengiriman
    # Menunggu teks unik "Berikut daftar produk" dari XML sebelum mengizinkan swipe
    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, 'Berikut daftar produk')]
    ...    timeout=${WAIT_TIMEOUT}

    # 🚀 ADB SWIPE (Scroll Down ke CheckBox)
    Execute Adb Shell    ${ADB_SWIPE_CMD}
    Sleep    1s

    Wait Until Element Is Visible    xpath=//android.widget.CheckBox    timeout=${WAIT_TIMEOUT}
    Click Element    xpath=//android.widget.CheckBox

    Expect Element    accessibility_id=Mulai Pengiriman    enabled    timeout=15s
    Click Element    accessibility_id=Mulai Pengiriman
    Wait Until Element Is Visible    accessibility_id=Selesaikan Pengiriman    timeout=${WAIT_TIMEOUT}

Selesaikan Pengiriman Dan Pilih Alasan
    [Arguments]    ${alasan}
    Click Element    accessibility_id=Selesaikan Pengiriman
    Wait Until Element Is Visible    accessibility_id=Lanjutkan    timeout=${WAIT_TIMEOUT}
    Click Element    accessibility_id=Lanjutkan

    # 🛑 CHECKPOINT 2: Memastikan kita SUDAH di halaman Konfirmasi Alasan
    # Menunggu kolom "Masukan Alasan Lainnya" dari XML agar swipe tidak bounce/salah tempat
    Wait Until Page Contains Element
    ...    xpath=//android.widget.EditText[@hint='Masukan Alasan Lainnya']
    ...    timeout=${WAIT_TIMEOUT}

    # Pilih Alasan SO Pertama
    ${locator_alasan}=    Set Variable    xpath=//android.view.View[@content-desc='${alasan}']
    Wait Until Element Is Visible    ${locator_alasan}    timeout=${WAIT_TIMEOUT}
    Click Element    ${locator_alasan}

    # 🚀 ADB SWIPE (Scroll Down untuk SO kedua dan Tombol Konfirmasi)
    Execute Adb Shell    ${ADB_SWIPE_CMD}
    Sleep    1s

    Run Keyword And Ignore Error    Click Element    ${locator_alasan}

    # Swipe sekali lagi jika tombol konfirmasi masih tertutup
    Execute Adb Shell    ${ADB_SWIPE_CMD}
    Sleep    1s

    ${btn_konfirmasi}=    Set Variable
    ...    xpath=//android.widget.Button[@content-desc='Konfirmasi Selesaikan Pengiriman']
    Wait Until Element Is Visible    ${btn_konfirmasi}    timeout=${WAIT_TIMEOUT}
    Click Element    ${btn_konfirmasi}

Verifikasi Pop Up Sukses
    ${btn_ok}=    Set Variable    xpath=//android.widget.Button[@content-desc='OK']
    Wait Until Element Is Visible    ${btn_ok}    timeout=${WAIT_TIMEOUT}
    Click Element    ${btn_ok}
    Sleep    2s

Kembali Ke Beranda
    # 1. Kembali dari halaman Pengiriman Barang ke Aktivitas Belanja
    Wait Until Element Is Visible    accessibility_id=Pengiriman Barang    timeout=${WAIT_TIMEOUT}
    # Menggunakan XPath untuk tombol Button pertama (Panah Kiri/Back) yang berada di header kiri atas
    Click Element    xpath=(//android.widget.Button)[1]

    # 2. Kembali dari halaman Aktivitas Belanja ke Aktivitas
    Wait Until Element Is Visible    accessibility_id=Aktivitas Belanja    timeout=${WAIT_TIMEOUT}
    Click Element    xpath=(//android.widget.Button)[1]

    # 3. Kembali dari halaman Aktivitas ke Beranda
    Wait Until Element Is Visible    accessibility_id=Aktivitas    timeout=${WAIT_TIMEOUT}
    Click Element    xpath=(//android.widget.Button)[1]

    # 4. Validasi dan Handle Pop Up Aktivasi WOI (Jika Muncul di Beranda)
    Handle Pop Up Aktivasi WOI

    # 5. Validasi akhir bahwa bot sudah mendarat di halaman Beranda yang bersih dari pop up
    Wait Until Element Is Visible    accessibility_id=Beranda    timeout=${WAIT_TIMEOUT}

Handle Pop Up Aktivasi WOI
    [Documentation]    Mengecek dan menutup pop up Aktivasi WOI dengan tombol Back Android jika muncul di Beranda.
    Sleep    1s
    # 🛠️ FIX: Run Keyword And Return Status hanya mengembalikan 1 nilai boolean, bukan tuple
    ${is_popup_present}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible
    ...    xpath=//android.view.View[@content-desc='Tutup']
    ...    timeout=3s
    IF    ${is_popup_present} == ${TRUE}    Tekan Back Android

Tekan Back Android
    [Documentation]    Menjalankan perintah ADB untuk menekan tombol Back pada perangkat Android.
    Execute Adb Shell    ${ADB_BACK_CMD}
    Sleep    1s
