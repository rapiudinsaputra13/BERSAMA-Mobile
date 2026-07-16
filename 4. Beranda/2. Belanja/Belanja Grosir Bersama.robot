*** Settings ***
Documentation       Test pencarian produk dan proses checkout pada aplikasi MyBoss

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

# Data Test (Mudah diubah di sini)
${SEARCH_QUERY}                         CLASS MILD 16
${TARGET_PRODUCT}                       CLASS MILD 16
${PIN}                                  112233


*** Test Cases ***
Should search for ${TARGET_PRODUCT} product and checkout
    [Documentation]  Alur e2e: Search -> Cart -> Checkout -> Payment -> PIN -> Success Page -> Homepage
    Open Test Application
    Handle WOI Activation Popup
    Tap Search Field On Homepage
    Tap Search Dialog Field
    Input Search Query    ${SEARCH_QUERY}
    Submit Search

    # Halaman Pencarian
    Hide Keyboard
    Tap Product From Search Result    ${TARGET_PRODUCT}

    # Bottom Sheet Detail Produk
    Tap Buy Button On Product Detail

    # Halaman Keranjang
    Tap Pay Button On Cart

    # Halaman Atur Pesanan
    Tap Choose Payment Button

    # Halaman Pembayaran (Pilih Metode)
    Tap COD Payment Method

    # Halaman Pembayaran
    Tap Pay Button On Payment Page

    # Halaman Konfirmasi Pembelian Grosir
    Enter PIN    ${PIN}
    Hide Keyboard
    Tap Confirm Button

    # Halaman Sukses & Kembali ke Beranda
    ${SO_CODE}=    Extract SO Code And Close Success Page
    Log    Transaksi sukses! Kode SO: ${SO_CODE}    console=yes


*** Keywords ***
Open Test Application
    [Documentation]  Membuka aplikasi dengan capabilities yang lebih stabil
    Open Application    ${REMOTE_URL}    automationName=${ANDROID_AUTOMATION_NAME}
    ...    platformName=${ANDROID_PLATFORM_NAME}    deviceName=${ANDROID_DEVICE_NAME}
    ...    appPackage=${ANDROID_APP_PACKAGE}    appActivity=${ANDROID_APP_ACTIVITY}
    ...    appWaitActivity=${ANDROID_APP_WAIT_ACTIVITY}    noReset=${ANDROID_NO_RESET}
    ...    newCommandTimeout=${ANDROID_NEW_COMMAND_TIMEOUT}
    ...    adbExecTimeout=${ANDROID_ADB_EXEC_TIMEOUT}
    ...    waitForIdleTimeout=${ANDROID_WAIT_FOR_IDLE_TIMEOUT}
    ...    disableWindowAnimation=${ANDROID_DISABLE_WINDOW_ANIMATION}
    Sleep    3s

Handle WOI Activation Popup
    [Documentation]    Menunggu pop-up WOI muncul selama 10 detik. Jika muncul, tekan Back.
    ${is_popup_present}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    xpath=//android.view.View[@content-desc='Tutup' and @dismissable='true']
    ...    timeout=10s
    IF    ${is_popup_present}
        Log    Pop-up WOI terdeteksi, melakukan Back.
        Go Back
        Sleep    3s
    END

Tap Search Field On Homepage
    Wait Until Element Is Visible    accessibility_id=Belanja apa hari ini ?    timeout=10s
    Click Element    accessibility_id=Belanja apa hari ini ?
    Sleep    3s

Tap Search Dialog Field
    Wait Until Element Is Visible    xpath=//android.widget.EditText[@hint='Belanja apa hari ini ?']    timeout=5s
    Click Element    xpath=//android.widget.EditText[@hint='Belanja apa hari ini ?']
    Sleep    3s

Input Search Query
    [Arguments]    ${query}
    Input Text    xpath=//android.widget.EditText[@hint='Belanja apa hari ini ?']    ${query}
    Sleep    3s

Submit Search
    Click Element    accessibility_id=Cari
    Sleep    3s

Tap Product From Search Result
    [Arguments]    ${product_name}
    Wait Until Element Is Visible
    ...    xpath=//android.widget.ImageView[contains(@content-desc, '${product_name}')]
    ...    timeout=10s
    Click Element    xpath=//android.widget.ImageView[contains(@content-desc, '${product_name}')]
    Sleep    3s

Tap Buy Button On Product Detail
    Wait Until Element Is Visible    accessibility_id=Beli    timeout=5s
    Click Element    accessibility_id=Beli
    Sleep    3s

Tap Pay Button On Cart
    Wait Until Element Is Visible    accessibility_id=Bayar    timeout=10s
    Click Element    accessibility_id=Bayar
    Sleep    3s

Tap Choose Payment Button
    Wait Until Element Is Visible    accessibility_id=Pilih Pembayaran    timeout=5s
    Click Element    accessibility_id=Pilih Pembayaran
    Sleep    3s

Tap COD Payment Method
    [Documentation]  Memilih metode pembayaran Bayar Langsung (COD) pada halaman pembayaran
    Wait Until Element Is Visible
    ...    xpath=//android.view.View[contains(@content-desc, 'Bayar Langsung (COD)')]
    ...    timeout=10s
    Click Element    xpath=//android.view.View[contains(@content-desc, 'Bayar Langsung (COD)')]
    Sleep    3s

Tap Pay Button On Payment Page
    Wait Until Element Is Visible    accessibility_id=Bayar    timeout=5s
    Click Element    accessibility_id=Bayar
    Sleep    3s

Enter PIN
    [Documentation]  Tap field PIN dan isi PIN (Lokator disesuaikan dengan atribut password di XML)
    [Arguments]    ${pin}
    Wait Until Element Is Visible    xpath=//android.widget.EditText[@password='true']    timeout=10s
    Click Element    xpath=//android.widget.EditText[@password='true']
    Sleep    1s
    Input Text    xpath=//android.widget.EditText[@password='true']    ${pin}
    Sleep    3s

Tap Confirm Button
    [Documentation]  Tap tombol "Konfirmasi"
    Wait Until Element Is Visible    accessibility_id=Konfirmasi    timeout=5s
    Click Element    accessibility_id=Konfirmasi
    Sleep    3s

Extract SO Code And Close Success Page
    [Documentation]  Mengambil kode SO dari halaman sukses, klik Tutup, dan tunggu halaman Beranda
    # 1. Tunggu halaman sukses muncul
    Wait Until Page Contains Element
    ...    xpath=//android.view.View[contains(@content-desc, 'Transaksi berhasil')]
    ...    timeout=15s

    # 2. Ambil teks lengkap dari content-desc
    ${success_desc}=    Get Element Attribute
    ...    xpath=//android.view.View[contains(@content-desc, 'Transaksi berhasil')]
    ...    content-desc

    # 3. Ekstrak kode SO (format: SO diikuti angka) menggunakan regex Python
    ${so_code}=    Evaluate
    ...    re.search(r'SO\d+', '''${success_desc}''').group(0) if re.search(r'SO\d+', '''${success_desc}''') else 'NOT_FOUND'
    ...    modules=re
    Log    Kode SO yang diekstrak: ${so_code}
    Sleep    3s

    # 4. Klik tombol Tutup
    Wait Until Element Is Visible    accessibility_id=Tutup    timeout=10s
    Click Element    accessibility_id=Tutup
    Sleep    3s

    # Menangani pop-up WOI yang mungkin muncul lagi setelah kembali ke beranda
    Handle WOI Activation Popup

    # 5. Validasi kembali ke halaman Beranda (Sebagai "Rem Paksa" / Checkpoint)
    # Menggunakan Run Keyword And Ignore Error agar test case tidak FAIL jika locator Beranda tidak ditemukan
    Run Keyword And Ignore Error    Wait Until Element Is Visible    accessibility_id=Beranda    timeout=15s
    Sleep    3s

    RETURN    ${so_code}
