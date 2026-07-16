*** Settings ***
Documentation       Test pembelian Pulsa dan proses checkout pada aplikasi MyBoss
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

# Locators Onboarding & Setup (Berdasarkan XML yang dilampirkan)
${BTN_UPDATE_LATER}                     xpath=//android.widget.Button[@content-desc='Lain kali' or @text='Lain kali']
${BTN_ALLOW_ALL_PERMISSIONS}            accessibility_id=Izinkan Semua
${BTN_CONTINUE_SETUP}                   accessibility_id=Lanjutkan
${BTN_SKIP_INTRO}                       accessibility_id=Skip
${BTN_NEXT_INTRO}                       accessibility_id=Lanjutkan
${BTN_LOGIN}                            accessibility_id=Masuk

# System Permissions (Package com.google.android.permissioncontroller / com.google.android.gms)
${SYS_BTN_ALLOW}                        xpath=//android.widget.Button[@resource-id='com.android.permissioncontroller:id/permission_allow_button' or @resource-id='com.android.permissioncontroller:id/permission_allow_foreground_only_button' or @resource-id='com.android.permissioncontroller:id/permission_allow_one_time_button']
${SYS_BTN_GMS_ACTIVATE}                 xpath=//android.widget.Button[@resource-id='android:id/button1' and @text='Aktifkan']


*** Test Cases ***
Setup Aplikasi dan Handle Permission
    [Documentation]    Membuka aplikasi, handle dialog update, setting awal, dan permission
    Open MyBoss Application
    Handle Update Dialog
    Handle Initial Setup
    Handle System Permissions
    Handle Intro Screens

    # ==========================================================
    # ⚠️ DI SINI KITA BUTUH XML HALAMAN LOGIN & PULSA
    # Silakan balas pesan ini dengan XML untuk:
    # 1. Halaman Login / OTP
    # 2. Dashboard & Menu Pulsa
    # 3. Halaman Checkout
    # ==========================================================


*** Keywords ***
Open MyBoss Application
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

Handle Update Dialog
    [Documentation]    Handle Dialog "Pembaruan Tersedia" (Button Sheep) jika muncul
    ${is_update}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    ${BTN_UPDATE_LATER}
    ...    timeout=5s
    IF    ${is_update}    Click Element    ${BTN_UPDATE_LATER}

Handle Initial Setup
    [Documentation]    Handle "Pengaturan Awal" (Persetujuan Aplikasi)
    ${is_setup}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    ${BTN_ALLOW_ALL_PERMISSIONS}
    ...    timeout=5s
    IF    ${is_setup}
        Click Element    ${BTN_ALLOW_ALL_PERMISSIONS}
        # Menunggu tombol Lanjutkan aktif (Best Practice: Validasi Status Tombol)
        Wait Until Element Is Enabled    ${BTN_CONTINUE_SETUP}    timeout=15s
        Click Element    ${BTN_CONTINUE_SETUP}
    END

Handle System Permissions
    [Documentation]    Loop untuk handle pop-up permission bawaan Android (Notifikasi, GPS, Kamera, dll)
    FOR    ${i}    IN RANGE    6
        ${is_perm}=    Run Keyword And Return Status
        ...    Wait Until Page Contains Element
        ...    ${SYS_BTN_ALLOW}
        ...    timeout=3s
        IF    ${is_perm}
            Click Element    ${SYS_BTN_ALLOW}
        ELSE
            ${is_gms}=    Run Keyword And Return Status
            ...    Wait Until Page Contains Element
            ...    ${SYS_BTN_GMS_ACTIVATE}
            ...    timeout=2s
            IF    ${is_gms}    Click Element    ${SYS_BTN_GMS_ACTIVATE}
        END
    END

Handle Intro Screens
    [Documentation]    Handle 6 Halaman Intro.
    ${is_intro}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    ${BTN_SKIP_INTRO}
    ...    timeout=5s
    IF    ${is_intro}
        Click Element    ${BTN_SKIP_INTRO}
    ELSE
        # Fallback jika tidak ada skip, klik lanjutkan terus
        FOR    ${i}    IN RANGE    6
            ${has_next}=    Run Keyword And Return Status
            ...    Wait Until Page Contains Element
            ...    ${BTN_NEXT_INTRO}
            ...    timeout=3s
            IF    ${has_next}    Click Element    ${BTN_NEXT_INTRO}
        END
    END

    # Rem paksa (Checkpoint) sebelum masuk ke halaman Login
    Wait Until Page Contains Element    ${BTN_LOGIN}    timeout=15s
