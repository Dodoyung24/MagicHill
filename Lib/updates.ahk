﻿#Include %A_ScriptDir%\Lib\gui.ahk

global repoOwner := "Dodoyung24"
global repoName := "Magic-hill"
global currentVersion := "v1.0"

CheckForUpdates() {
    url := "https://api.github.com/repos/" repoOwner "/" repoName "/releases/latest"
    http := ComObject("MSXML2.XMLHTTP")
    http.Open("GET", url, false)
    http.Send()

    if (http.Status != 200) {
        AddToLog("Failed to check for updates.")
        return
    }

    response := http.responseText
    latestVersion := JSON.parse(response).Get("tag_name")

    autoUpdateEnabled :=  1

    if (latestVersion != currentVersion) {
        AddToLog("A new version is available! Current version: " currentVersion "nLatest version: " latestVersion)
        if (autoUpdateEnabled) {
            DownloadAndUpdateRepo()
        }
    } else {
        AddToLog("You are using the latest version.")
    }
}

DownloadAndUpdateRepo() {
    if (IsProcessElevated(DllCall("GetCurrentProcessId")) != 1) {
        AddToLog("Failed to update to latest version, make sure macro is running with admin rights.")
        return
    }

    zipUrl := "https://github.com/" repoOwner "/" repoName "/archive/refs/heads/main.zip"

    zipFilePath := A_ScriptDir "\repo.zip"

    Download(zipUrl, zipFilePath)

    ExtractZIP(zipFilePath, A_ScriptDir)

    FileDelete(zipFilePath)

    extractedFolderPath := A_ScriptDir . "" . "Magic Hill"
    if !DirExist(extractedFolderPath) {
      
        return
    }

    ErrorCount := CopyFilesAndFolders(extractedFolderPath . "*", A_ScriptDir, "1")
    if ErrorCount != 0 {
        AddToLog(ErrorCount " files/folders could not be copied.")
        return
    }

    AddToLog("Updated! Restarting script")
    RestartScript()
}

ExtractZIP(zipFilePath, targetDir) {
    ; Run the PowerShell command to extract the ZIP file
    RunWait("powershell -Command Expand-Archive -Path '" zipFilePath "' -DestinationPath '" targetDir "'", "", "Hide")

    ; Check if the extraction was successful
    extractedFolderPath := targetDir . "\MagicHill-main"
    if (!DirExist(extractedFolderPath)) {
        AddToLog("Something went wrong while extracting. Please check if the ZIP file is valid and accessible." 
            . "nError Details:" 
            . "nZIP File Path: " zipFilePath 
            . "nTarget Directory: " targetDir)
        return
    }

    ; Log successful extraction
    AddToLog("Extraction successful to: " extractedFolderPath)
}

CopyFilesAndFolders(SourcePattern, DestinationFolder, DoOverwrite := false) {
    ErrorCount := 0
    try
        FileCopy SourcePattern, DestinationFolder, DoOverwrite
    catch as Err
        ErrorCount := Err.Extra
    Loop Files, SourcePattern, "D"
    {
        try
            DirCopy A_LoopFilePath, DestinationFolder "" A_LoopFileName, DoOverwrite
        catch
        {
            ErrorCount += 1
        }
    }
    return ErrorCount
}

RestartScript() {
    Run(A_ScriptFullPath)
    ExitApp
}
