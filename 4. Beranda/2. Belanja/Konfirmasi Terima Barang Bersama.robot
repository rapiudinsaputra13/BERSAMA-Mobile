*** Settings ***
Documentation       Skenario Automasi MyBoss - Terima Barang Pesanan Belanja
...                 Alur: Beranda -> Aktivitas Belanja -> Pesanan Belanja -> Scroll SO -> Terima -> Rating -> Konfirmasi -> Kembali ke Beranda
...                 UPDATE: Penanganan Pop Up Banner Sukses dan Pop Up WOI kini bersifat Opsional (Non-Blocking).

Library             AppiumLibrary


*** Variables ***
${REMOTE_URL}           http://127.0.0.1:4723
${PLATFORM_NAME}        Android
${DEVICE_NAME}          Android Device
${APP_PACKAGE}          lpi.myboss.staging
${APP_ACTIVITY}         lpi.myboss.staging.MainActivity
${AUTOMATION_NAME}      UiAutomator2

${KODE_SO}              SO2607000006185868
${TEXT_ULASAN}          Testing Robot Fremwork Appium Library

${WAIT_TIMEOUT}         ${15}
${NEW_CMD_TIMEOUT}      ${600}
${ADB_EXEC_TIMEOUT}     ${120000}
${NO_RESET}             ${TRUE}
${ADB_SWIPE_CMD}        input swipe 360 1200 360 500 300
${ADB_BACK_CMD}         input keyevent 4


*** Test Cases ***
Skenario Terima Barang Pesanan Belanja Hingga Kembali Ke Beranda
    [Tags]    myboss    pesanan_belanja    terima_barang

    Sambung Ke Aplikasi MyBoss
    Buka Menu Aktivitas Belanja
    Buka Menu Pesanan Belanja
    Scroll Dan Klik Terima Pada SO    ${KODE_SO}
    Konfirmasi Terima Barang
    Verifikasi Halaman Nilai Ulasan
    Isi Ulasan Dan Kirim Rating    ${TEXT_ULASAN}
    Konfirmasi Pengiriman Rating
    Kembali Ke Beranda


*** Keywords ***
Sambung Ke Aplikasi MyBoss
    Open Application    ${REMOTE_URL}
    ...    platformName=${PLATFORM_NAME}    deviceName=${DEVICE_NAME}
    ...    appPackage=${APP_PACKAGE}    appActivity=${APP_ACTIVITY}
    ...    automationName=${AUTOMATION_NAME}    noReset=${NO_RESET}
    ...    newCommandTimeout=${NEW_CMD_TIMEOUT}    adbExecTimeout=${ADB_EXEC_TIMEOUT}
    ...    disableWindowAnimation=${TRUE}
    Wait Until Element Is Visible    accessibility_id=Aktivitas    timeout=${WAIT_TIMEOUT}

Buka Menu Aktivitas Belanja
    Click Element    accessibility_id=Aktivitas
    Wait Until Element Is Visible    accessibility_id=Aktivitas Belanja    timeout=${WAIT_TIMEOUT}
    Click Element    accessibility_id=Aktivitas Belanja
    Wait Until Element Is Visible    accessibility_id=Pesanan Belanja    timeout=${WAIT_TIMEOUT}

Buka Menu Pesanan Belanja
    Click Element    accessibility_id=Pesanan Belanja
    Wait Until Element Is Visible    accessibility_id=Profile Icon    timeout=${WAIT_TIMEOUT}

Scroll Dan Klik Terima Pada SO
    [Arguments]    ${kode_so}
    ${xpath_so}=    Set Variable    xpath=//android.view.View[@content-desc='${kode_so}']
    ${xpath_terima}=    Set Variable
    ...    xpath=//android.view.View[@content-desc='${kode_so}']/../android.widget.Button[@content-desc='Terima']

    FOR    ${i}    IN RANGE    5
        ${status}=    Run Keyword And Return Status    Element Should Be Visible    ${xpath_so}
        IF    ${status}    BREAK
        Execute Adb Shell    ${ADB_SWIPE_CMD}
        Sleep    1s
    END

    Wait Until Element Is Visible    ${xpath_so}    timeout=${WAIT_TIMEOUT}
    Click Element    ${xpath_terima}

Konfirmasi Terima Barang
    Wait Until Element Is Visible    accessibility_id=Konfirmasi    timeout=${WAIT_TIMEOUT}
    Click Element    accessibility_id=Ya
    Wait Until Element Is Visible    accessibility_id=Nilai & Ulasan    timeout=${WAIT_TIMEOUT}

Verifikasi Halaman Nilai Ulasan
    Wait Until Element Is Visible    accessibility_id=Nilai & Ulasan    timeout=${WAIT_TIMEOUT}

Isi Ulasan Dan Kirim Rating
    [Arguments]    ${ulasan}
    ${xpath_ulasan}=    Set Variable    xpath=//android.widget.EditText[@hint='Tulis ulasan Anda di sini...']
    Wait Until Element Is Visible    ${xpath_ulasan}    timeout=${WAIT_TIMEOUT}
    Click Element    ${xpath_ulasan}
    Input Text    ${xpath_ulasan}    ${ulasan}
    Hide Keyboard
    Click Element    accessibility_id=Kirim Rating

Konfirmasi Pengiriman Rating
    [Documentation]    Menunggu pop-up konfirmasi ulasan dan menekan tombol Lanjutkan
    Wait Until Element Is Visible    accessibility_id=Konfirmasi    timeout=${WAIT_TIMEOUT}
    Wait Until Element Is Visible    accessibility_id=Lanjutkan    timeout=${WAIT_TIMEOUT}
    Click Element    accessibility_id=Lanjutkan

Kembali Ke Beranda
    [Documentation]    Menangani pop up banner (opsional), menekan tombol back, dan menangani pop up WOI di Beranda.

    # 1. Tutup Pop Up Banner Sukses (Opsional - Tidak membloker jika tidak muncul)
    Tutup Pop Up Banner Sukses

    # 2. Tekan tombol panah kiri (back) untuk kembali ke halaman Beranda.
    ${xpath_back}=    Set Variable    xpath=(//android.widget.Button)[1]
    Wait Until Element Is Visible    ${xpath_back}    timeout=${WAIT_TIMEOUT}
    Click Element    ${xpath_back}

    # 3. Handle Pop Up WOI di Beranda (Opsional)
    Handle Pop Up Aktivasi WOI

    # 4. Verifikasi (Checkpoint) bahwa halaman Beranda telah berhasil terbuka kembali
    Wait Until Element Is Visible    accessibility_id=Beranda    timeout=${WAIT_TIMEOUT}

Tutup Pop Up Banner Sukses
    [Documentation]    Mengecek keberadaan banner sukses. Jika ada, tekan tombol close (X). Bersifat opsional dan tidak membloker.
    Sleep    1s
    ${is_banner_present}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible
    ...    xpath=//android.view.View[contains(@content-desc, 'Dear merchant Bersama')]
    ...    timeout=2s
    IF    ${is_banner_present} == ${TRUE}
        Log    Banner sukses terdeteksi, menekan tombol close (X).
        Run Keyword And Ignore Error
        ...    Click Element
        ...    xpath=//android.view.View[contains(@content-desc, 'Dear merchant Bersama')]/android.view.View
        Sleep    1s
    ELSE
        Log    Banner sukses tidak muncul, melanjutkan proses.
    END

Handle Pop Up Aktivasi WOI
    [Documentation]    Mengecek dan menutup pop up Aktivasi WOI dengan tombol Back Android jika muncul di Beranda. Bersifat opsional.
    Sleep    1s
    ${is_popup_present}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible
    ...    xpath=//android.view.View[@content-desc='Tutup']
    ...    timeout=2s
    IF    ${is_popup_present} == ${TRUE}
        Log    Pop-up WOI terdeteksi, melakukan Back.
        Execute Adb Shell    ${ADB_BACK_CMD}
        Sleep    1s
    ELSE
        Log    Pop-up WOI tidak muncul, melanjutkan proses.
    END
