#Requires AutoHotkey v2.0

; ==============================================================================
; --- 文案配置区 ---
; ==============================================================================
global TEXT_ADMIN_FAIL := "脚本需要管理员权限才能在某些游戏中正常工作，请在弹出窗口中选择“是”，或手动右键以管理员身份运行该脚本。"
global TEXT_ADMIN_TITLE := "权限请求失败"

global TEXT_GUI_TITLE := "使用说明"
global TEXT_DESC := "
(LTrim
    快捷键说明：
        【F1】：【总开关】
        【F2】：【W 循环】功能开关（向上走 60 秒，停 90 秒）
        【F3】：【1 循环】功能开关（每秒按 1 收升级奖励）

    使用说明：
        1. 进入关卡【模拟室 1】（只有这张图能刷）
        2. 正常升级发育，可参考下面【配装推荐】
        3. 等到 15 分钟 BOSS 登场
        4. 按【F1】打开脚本，之后挂机即可
)"
global TEXT_BTN_REC := "配装推荐"
global TEXT_BTN_OK := "确认"

global TEXT_REC_TITLE := "配装推荐"
global TEXT_REC_CONTENT := "
(LTrim
     核心要义：手越短越好，让掉落物都被 5 级磁铁吸住

     角色：推荐长发（因为手短 + 身板梆硬）
     升级：防御 > 攻击 > 移速 > 发射物速度 > 其他
     EX 升级：模拟室 1 难度不高随便刷，但是不要带【投射体尺寸】

     武器：什么手短选什么
     制导激光（可 EX）、能量场（不要 EX）、飞弹（不要 EX）
     等离子利刃（不要 EX）、能量型利刃、能量机器人、手榴弹

     模组：
     刚需：【信号增强模组（磁铁）】、【快速移动模组（跑鞋）】
     别拿：【发射物尺寸增强模组】（会加手长）
     其他随便抓，推荐抓体力、防御补容错
)"

global TEXT_MASTER_ON := "【总开关】已开启"
global TEXT_MASTER_OFF := "【总开关】已关闭"
global TEXT_NIKKE_NOT_FOUND := "【注意】未找到游戏窗口，请手动切换到游戏窗口"
global TEXT_NEED_MASTER := "请先按 F1 开启【总开关】"

global TEXT_LOGIC1_ON := "【W 循环】已开启"
global TEXT_LOGIC1_OFF := "【W 循环】已关闭"
global TEXT_LOGIC2_ON := "【1 循环】已开启"
global TEXT_LOGIC2_OFF := "【1 循环】已停止"
; ==============================================================================

; --- 管理员权限自动提权 (支持脚本及编译后的 EXE) ---
if !A_IsAdmin {
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '" /restart')
        else
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    } catch {
        MsgBox(TEXT_ADMIN_FAIL, TEXT_ADMIN_TITLE, "Icon!")
    }
    ExitApp()
}

; --- 启动界面 (自定义按钮) ---
StartGui := Gui("+AlwaysOnTop", TEXT_GUI_TITLE)
StartGui.SetFont("s10", "Microsoft YaHei")
StartGui.Add("Text", "w350", TEXT_DESC)

; 添加自定义按钮
BtnRec := StartGui.Add("Button", "w100 h30", TEXT_BTN_REC)
BtnOk := StartGui.Add("Button", "x+10 w100 h30 Default", TEXT_BTN_OK)

; 绑定事件
BtnRec.OnEvent("Click", (*) => (StartGui.Destroy(), MsgBox(TEXT_REC_CONTENT, TEXT_REC_TITLE)))
BtnOk.OnEvent("Click", (*) => StartGui.Destroy())

StartGui.Show()
WinWaitClose(StartGui)

; --- 全局状态变量 ---
global IsMasterEnabled := false
global IsLogic1Running := false
global IsLogic2Running := false

; --- F1 总开关 ---
F1:: {
    global IsMasterEnabled := !IsMasterEnabled
    global IsLogic1Running, IsLogic2Running

    if (IsMasterEnabled) {
        IsLogic1Running := true
        IsLogic2Running := true

        statusMsg := TEXT_MASTER_ON

        if WinExist("ahk_exe nikke.exe") {
            WinActivate("ahk_exe nikke.exe")
        } else {
            statusMsg .= TEXT_NIKKE_NOT_FOUND
        }

        ToolTip(TEXT_NIKKE_NOT_FOUND)
        SetTimer(DoPressW, -1)
        SetTimer(DoPress1, 1000)
    } else {
        ToolTip(TEXT_MASTER_OFF)
        StopLogic1()
        StopLogic2()
    }
    SetTimer(() => ToolTip(), -1500)
}

; --- F2 逻辑 1 开关 ---
F2:: {
    if (!IsMasterEnabled) {
        ToolTip(TEXT_NEED_MASTER)
        SetTimer(() => ToolTip(), -1500)
        return
    }

    global IsLogic1Running := !IsLogic1Running
    if (IsLogic1Running) {
        ToolTip(TEXT_LOGIC1_ON)
        SetTimer(DoPressW, -1)
    } else {
        ToolTip(TEXT_LOGIC1_OFF)
        StopLogic1()
    }
    SetTimer(() => ToolTip(), -1500)
}

; --- F3 逻辑 2 开关 ---
F3:: {
    if (!IsMasterEnabled) {
        ToolTip(TEXT_NEED_MASTER)
        SetTimer(() => ToolTip(), -1500)
        return
    }

    global IsLogic2Running := !IsLogic2Running
    if (IsLogic2Running) {
        ToolTip(TEXT_LOGIC2_ON)
        SetTimer(DoPress1, 1000)
    } else {
        ToolTip(TEXT_LOGIC2_OFF)
        StopLogic2()
    }
    SetTimer(() => ToolTip(), -1500)
}

; --- 核心处理与停止函数 ---

StopLogic1() {
    global IsLogic1Running := false
    SetTimer(DoPressW, 0)
    SetTimer(DoReleaseW, 0)
    Send("{w up}")
}

StopLogic2() {
    global IsLogic2Running := false
    SetTimer(DoPress1, 0)
}

DoPressW() {
    if (!IsMasterEnabled || !IsLogic1Running) {
        return
    }
    Send("{w down}")
    SetTimer(DoReleaseW, -60000)
}

DoReleaseW() {
    if (!IsMasterEnabled || !IsLogic1Running) {
        return
    }
    Send("{w up}")
    SetTimer(DoPressW, -90000)
}

DoPress1() {
    if (!IsMasterEnabled || !IsLogic2Running) {
        return
    }
    Send("1")
}
