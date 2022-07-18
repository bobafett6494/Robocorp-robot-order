*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.RobotLogListener
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             String
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${PATH_ORDERS}          ${OUTPUT_DIR}${/}Orders
${PATH_RECEIPTS}        ${OUTPUT_DIR}${/}Orders${/}receipts
${PATH_SCREENSHOTS}     ${OUTPUT_DIR}${/}Orders${/}screenshots


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    #Test
    ${credentials}=    Get Secret    credentials
    Log    ${credentials}[robot-order-url]
    Setup Directories
    Open website    ${credentials}[robot-order-url]
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Fill the form    ${row}

        ${screenshot}=    Take screenshot of robot    ${row}[Order number]
        Click Order
        ${pdf}=    Save receipt as PDF    ${row}[Order number]
        Embed robot screenshot to receipt PDF file    ${screenshot}    ${pdf}
        Click New Order
    END
    Create ZIP
    Cleanup Directories
    [Teardown]    Close Browser


*** Keywords ***
Setup Directories
    ${directory_exists}=    Does directory exist    ${PATH_ORDERS}
    IF    ${directory_exists}==False    Create directory    ${PATH_ORDERS}
    ${directory_exists}=    Does directory exist    ${PATH_RECEIPTS}
    IF    ${directory_exists}==False    Create directory    ${PATH_RECEIPTS}
    ${directory_exists}=    Does directory exist    ${PATH_SCREENSHOTS}
    IF    ${directory_exists}==False    Create directory    ${PATH_SCREENSHOTS}

Get orders
    ${url}=    Input form dialog
    Download
    ...    ${url}
    ...    overwrite=True
    ...    target_file=${PATH_ORDERS}${/}orders.csv
    ${orders}=    Read table from CSV    ${PATH_ORDERS}${/}orders.csv    header=True
    Log    Found columns: ${orders.columns}
    Log    ${orders}
    RETURN    ${orders}

Open website
    [Arguments]    ${robot-order-url}
    Open Available Browser    ${robot-order-url}
    Maximize Browser Window
    Wait Until Element Is Visible    class:modal-header
    Click Button    OK

Fill the form
    [Arguments]    ${row}

    Input Text    address    ${row}[Address]
    Select From List By Value    head    ${row}[Head]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    #Input Text    //div[@id="form-group"]//input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    ${rnd}=    Generate Random String    1    123456
    Select Radio Button    body    ${rnd}

Test
    Attach Chrome Browser    9222
    Go To    https://robotsparebinindustries.com/#/robot-order
    ${visible_alert}=    Is Element Visible    class:alert alert-danger
    Log    ${visible_alert}

Save receipt as PDF
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${PATH_RECEIPTS}${/}receipt_${orderNumber}.pdf
    RETURN    ${PATH_RECEIPTS}${/}receipt_${orderNumber}.pdf

Click Order
    Click Button    id:order
    ${visible_order}=    Is Element Visible    id:order
    WHILE    ${visible_order}    limit=10
        Click Button    id:order
        ${visible_order}=    Is Element Visible    id:order
    END

Click New Order
    ${visible_order}=    Is Element Visible    id:order-another
    WHILE    ${visible_order}    limit=10
        Click Button    order-another
        ${visible_order}=    Is Element Visible    id:order-another
    END
    ${res}=    Is Element Visible    class:modal-header
    IF    ${res}    Click Button    OK

Take screenshot of robot
    [Arguments]    ${orderNumber}
    Click Button    preview
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${PATH_SCREENSHOTS}${/}${orderNumber}.png
    RETURN    ${PATH_SCREENSHOTS}${/}${orderNumber}.png

 Embed robot screenshot to receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}    append=${True}
    Close All Pdfs

Create ZIP
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Receipts.zip
    Archive Folder With Zip    ${PATH_RECEIPTS}    ${zip_file_name}

Cleanup Directories
    Remove Directory    ${PATH_ORDERS}    True

Input form dialog
    Add heading    Provide orders URL. Default URL https://robotsparebinindustries.com/orders.csv
    Add submit buttons    buttons=Submit
    Add text input    value    label=URL
    ${url}=    Run dialog
    Log    ${url}
    Log    ${url.value}
    IF    "${url.value}"=="${EMPTY}"
        ${url.value}=    Set Variable    https://robotsparebinindustries.com/orders.csv
    END
    RETURN    ${url.value}
