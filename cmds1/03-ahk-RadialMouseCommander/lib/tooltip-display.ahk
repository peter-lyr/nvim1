; 工具提示显示功能

ShowTemporaryMessage(message) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -2000)
}

GenerateRadialMenuDisplay() {
    global g_LeftButtonState, g_MiddleButtonState, g_WheelButtonState
    actionMap := GetCurrentModeActionMap()
    directionLayout := [
        ["", "U", ""],
        ["LU", "", "RU"],
        ["L", "", "R"],
        ["LD", "", "RD"],
        ["", "D", ""]
    ]

    displayGrid := []
    for row in directionLayout {
        newRow := []
        for directionCode in row {
            if (directionCode = "") {
                newRow.Push("")
                continue
            }
            stateKey := g_LeftButtonState "" g_MiddleButtonState "" g_WheelButtonState "" directionCode
            actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
            actionDescription := actionInfo[1]
            directionSymbol := GetDirectionSymbol(directionCode)
            directionName := GetDirectionChineseName(directionCode)
            displayText := directionSymbol " " directionName ":" actionDescription
            newRow.Push(displayText)
        }
        displayGrid.Push(newRow)
    }

    displayText := "模式: " g_CurrentOperationMode " 状态: 左键=" g_LeftButtonState ", 中键=" g_MiddleButtonState ", 滚轮=" g_WheelButtonState "`n`n"
    for row in displayGrid {
        line := ""
        for column in row {
            if (column = "") {
                line .= "        "
            } else {
                targetWidth := 20
                currentWidth := StrLen(column)
                if (currentWidth >= targetWidth) {
                    line .= column
                } else {
                    spacesNeeded := targetWidth - currentWidth
                    leftSpaces := spacesNeeded // 2
                    rightSpaces := spacesNeeded - leftSpaces
                    Loop leftSpaces {
                        line .= " "
                    }
                    line .= column
                    Loop rightSpaces {
                        line .= " "
                    }
                }
            }
        }
        displayText .= line "`n"
    }
    return displayText
}

GenerateCurrentDirectionInfo() {
    directionCode := CalculateCursorDirection()
    directionSymbol := GetDirectionSymbol(directionCode)
    directionName := GetDirectionChineseName(directionCode)
    stateKey := GetCurrentButtonStateAndDirection()
    actionMap := GetCurrentModeActionMap()
    actionInfo := actionMap.Has(stateKey) ? actionMap[stateKey] : ["未定义操作", ""]
    actionDescription := actionInfo[1]
    return "模式: " g_CurrentOperationMode " 方向: " directionSymbol " " directionName "`n操作: " actionDescription
}

UpdateRadialMenuTooltip() {
    global g_LastTooltipContent
    if (IsCursorInsideRadialMenu()) {
        newContent := GenerateRadialMenuDisplay()
    } else {
        newContent := GenerateCurrentDirectionInfo()
    }
    if (newContent != g_LastTooltipContent) {
        ToolTip(newContent)
        g_LastTooltipContent := newContent
    }
}
