*** Settings ***
Documentation       Test Login E2E pada aplikasi Bersama (MyBoss Staging)
...                 Alur: Buka Aplikasi → Handle Dialog Update → Permission → Login → Handle Post-Login Pop Ups → Beranda
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

# Timeout String
${SCROLL_TIMEOUT}                       15s
${SHORT_TIMEOUT}                        5s
${PERMISSION_TIMEOUT}                   3s

# Data Login (Sesuaikan dengan akun staging yang aktif)
${NO_HP}                                081398277390
${KATA_SANDI}                           Passw0rd

# Locators Halaman Login
${FIELD_NO_HP}                          xpath=//android.widget.EditText[@hint='Isi Nomor Handphone']
${FIELD_KATA_SANDI}                     xpath=//android.widget.EditText[@hint='Masukkan Kata Sandi']
${CHECKBOX_INGAT}                       xpath=//android.widget.CheckBox
${BTN_MASUK}                            accessibility_id=M A S U K

# Locators System Permissions (Package com.google.android.permissioncontroller)
${SYS_BTN_ALLOW_NOTIFICATION}           xpath=//android.widget.Button[@resource-id='com.android.permissioncontroller:id/permission_allow_button']
${SYS_BTN_ALLOW_GPS_FOREGROUND}         xpath=//android.widget.Button[@resource-id='com.android.permissioncontroller:id/permission_allow_foreground_only_button']
${SYS_BTN_ALLOW_GPS_ONE_TIME}           xpath=//android.widget.Button[@resource-id='com.android.permissioncontroller:id/permission_allow_one_time_button']
${SYS_BTN_ALLOW_ANY}                    xpath=//android.widget.Button[@resource-id='com.android.permissioncontroller:id/permission_allow_button' or @resource-id='com.android.permissioncontroller:id/permission_allow_foreground_only_button' or @resource-id='com.android.permissioncontroller:id/permission_allow_one_time_button']

# Locators Post-Login Pop Ups
${BTN_SETUJU_WOI}                       accessibility_id=SETUJU


*** Test Cases ***
Login E2E Bersama Hingga Beranda
    [Documentation]    Skenario End-to-End: Dari buka aplikasi → handle dialog → login → handle pop-up → verifikasi Beranda
    Open MyBoss Application
    Handle Dialog Pembaruan Tersedia
    Handle System Permissions
    Verify Halaman Login Terbuka
    Input Nomor Handphone    ${NO_HP}
    Input Kata Sandi    ${KATA_SANDI}
    Centang Ingat Saya
    Tap Tombol Masuk
    Handle Popup Ayo Aktivasi Sekarang
    Handle Popup Persetujuan WOI
    Verify Login Berhasil Di Beranda


*** Keywords ***
Open MyBoss Application
    [Documentation]    Membuka aplikasi dengan mode takeover (noReset) dan capabilities penstabil
    Open Application    ${REMOTE_URL}
    ...    platformName=${ANDROID_PLATFORM_NAME}
    ...    deviceName=${ANDROID_DEVICE_NAME}
    ...    appPackage=${ANDROID_APP_PACKAGE}
    ...    appActivity=${ANDROID_APP_ACTIVITY}
    ...    automationName=${ANDROID_AUTOMATION_NAME}
    ...    noReset=${ANDROID_NO_RESET}
    ...    newCommandTimeout=${ANDROID_NEW_COMMAND_TIMEOUT}
    ...    adbExecTimeout=${ANDROID_ADB_EXEC_TIMEOUT}
    ...    waitForIdleTimeout=${ANDROID_WAIT_FOR_IDLE_TIMEOUT}
    ...    disableWindowAnimation=${ANDROID_DISABLE_WINDOW_ANIMATION}

Handle Dialog Pembaruan Tersedia
    [Documentation]    Handle Dialog "Pembaruan Tersedia" yang muncul saat pertama buka aplikasi.
    ...                Tekan tombol Back Android (keycode 4) untuk melewati tanpa update.
    ...                Tombol X close: Button tanpa content-desc di bounds [615,108][705,198].
    ${is_update}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    accessibility_id=Pembaruan Tersedia
    ...    timeout=${SHORT_TIMEOUT}
    IF    ${is_update}
        Sleep    1s
        Press Keycode    4
        Sleep    2s
    END

Handle System Permissions
    [Documentation]    Loop untuk handle pop-up permission bawaan Android (Notifikasi, GPS, dll).
    ...                Menggunakan locator resource-id dari com.android.permissioncontroller.
    FOR    ${i}    IN RANGE    5
        ${is_perm}=    Run Keyword And Return Status
        ...    Wait Until Page Contains Element
        ...    ${SYS_BTN_ALLOW_ANY}
        ...    timeout=${PERMISSION_TIMEOUT}
        IF    ${is_perm}
            Click Element    ${SYS_BTN_ALLOW_ANY}
            Sleep    1s
        END
    END

Verify Halaman Login Terbuka
    [Documentation]    Checkpoint: Memastikan halaman Login telah terbuka sempurna.
    ...                Indikator: Tombol "M A S U K" dan field Nomor Handphone terlihat.
    Wait Until Page Contains Element    ${BTN_MASUK}    timeout=${SCROLL_TIMEOUT}
    Wait Until Page Contains Element    ${FIELD_NO_HP}    timeout=${SCROLL_TIMEOUT}

Input Nomor Handphone
    [Documentation]    Klik dan isi field Nomor Handphone.
    ...                Locator: EditText dengan hint='Isi Nomor Handphone'.
    [Arguments]    ${nomor}
    Click Element    ${FIELD_NO_HP}
    Input Text    ${FIELD_NO_HP}    ${nomor}
    Hide Keyboard

Input Kata Sandi
    [Documentation]    Klik dan isi field Kata Sandi (password="true").
    ...                Locator: EditText dengan hint='Masukkan Kata Sandi'.
    [Arguments]    ${sandi}
    Click Element    ${FIELD_KATA_SANDI}
    Sleep    1s
    Input Text    ${FIELD_KATA_SANDI}    ${sandi}

Centang Ingat Saya
    [Documentation]    Centang CheckBox "Ingat saya" agar session login persist.
    ...                Locator: CheckBox class (tanpa content-desc).
    Click Element    ${CHECKBOX_INGAT}
    Hide Keyboard

Tap Tombol Masuk
    [Documentation]    Tap tombol "M A S U K" untuk submit form login.
    ...                WAJIB Hide Keyboard terlebih dahulu agar tombol tidak tertutup.
    Hide Keyboard
    Click Element    ${BTN_MASUK}
    Sleep    3s

Handle Popup Ayo Aktivasi Sekarang
    [Documentation]    Handle popup "Ayo Aktivasi Sekarang" yang muncul setelah login.
    ...                Popup ini berupa ImageView full-screen tanpa content-desc.
    ...                Tombol X (close) ada di pojok kanan atas bounds [608,79][690,162].
    ...                Karena tidak ada locator, gunakan ADB Shell input tap di koordinat tengah.
    ...                Checkpoint: Jika sudah di Beranda (Transaksi terlihat), popup ini tidak muncul.
    ${sudah_beranda}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    accessibility_id=Transaksi
    ...    timeout=${SHORT_TIMEOUT}
    IF    not ${sudah_beranda}
        Sleep    2s
        Execute Adb Shell    input tap 649 120
        Sleep    2s
    END

Handle Popup Persetujuan WOI
    [Documentation]    Handle popup "Hai Mitra Warung & Grosir Bersama" tentang persetujuan WOI.
    ...                Tekan tombol "SETUJU" jika pop-up muncul.
    ${popup_wujud}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    ${BTN_SETUJU_WOI}
    ...    timeout=${SHORT_TIMEOUT}
    IF    ${popup_wujud}
        Click Element    ${BTN_SETUJU_WOI}
        Sleep    2s
    END

Verify Login Berhasil Di Beranda
    [Documentation]    Checkpoint akhir: Memastikan Beranda Bersama telah terbuka.
    ...                Verifikasi: Elemen "Transaksi" (menu utama) dan nama user terlihat.
    Wait Until Page Contains Element    accessibility_id=Transaksi    timeout=${SCROLL_TIMEOUT}
    Page Should Contain Element    accessibility_id=Belanja apa hari ini ?
