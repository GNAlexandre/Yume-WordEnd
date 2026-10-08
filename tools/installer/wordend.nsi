; Installateur Windows de WordEnd (bureau, docs/bureau.md) : NSIS 3, en français, par
; utilisateur et sans droits d'administrateur (%LOCALAPPDATA%\Programs\WordEnd), raccourcis du
; menu Démarrer et du Bureau, désinstalleur inscrit dans « Applications et fonctionnalités », qui
; propose de garder les sauvegardes (%APPDATA%\WordEnd, application/config/custom_user_dir_name).
;
; Construit par tools/build_desktop.sh, qui lit la version dans project.godot
; (application/config/version, seule source de la version) :
;   makensis -INPUTCHARSET UTF8 -DVERSION=0.3.0 -DEXE=<chemin de WordEnd.exe> \
;            -DOUTFILE=<chemin de WordEnd-Setup-0.3.0.exe> tools/installer/wordend.nsi
; Les chemins relatifs (wordend.ico, welcome.bmp : python3 tools/installer/make_installer_art.py)
; partent de ce dossier : makensis s'y place. Avertissements = erreurs (makensis -WX).
; Installateur 64 bits (le jeu est x86_64) ; aucune signature de code : Windows SmartScreen
; avertit au premier lancement (docs/bureau.md, « Windows a protégé votre ordinateur »).

Unicode true
Target amd64-unicode
ManifestDPIAware true
SetCompressor /SOLID lzma

!ifndef VERSION
  !error "VERSION manquante : passe par tools/build_desktop.sh (makensis -DVERSION=X.Y.Z)"
!endif
!ifndef EXE
  !error "EXE manquant : chemin de WordEnd.exe (tools/build_desktop.sh)"
!endif
!ifndef OUTFILE
  !define OUTFILE "WordEnd-Setup-${VERSION}.exe"
!endif

!define APP_NAME "WordEnd"
!define PUBLISHER "Yume Novel"
!define APP_URL "https://jeu.yumenovel.fr/"
!define APP_EXE "WordEnd.exe"
!define UNINSTALLER "uninstall.exe"
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\WordEnd"
; Dossier des sauvegardes et réglages du jeu (user:// sous Windows).
!define SAVE_DIR "$APPDATA\WordEnd"

!include "MUI2.nsh"
!include "FileFunc.nsh"

Name "${APP_NAME}"
Caption "Installation de ${APP_NAME} ${VERSION}"
UninstallCaption "Désinstallation de ${APP_NAME} ${VERSION}"
BrandingText "${APP_NAME} ${VERSION} — ${PUBLISHER}"
OutFile "${OUTFILE}"
InstallDir "$LOCALAPPDATA\Programs\WordEnd"
InstallDirRegKey HKCU "${UNINSTALL_KEY}" "InstallLocation"
RequestExecutionLevel user
ShowInstDetails nevershow
ShowUninstDetails nevershow

!define MUI_ICON "wordend.ico"
!define MUI_UNICON "wordend.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Bienvenue dans l'installation de ${APP_NAME} ${VERSION}"
!define MUI_WELCOMEPAGE_TEXT "WordEnd, l'action-aventure en HD-2D de ${PUBLISHER} : Chtholly et son épée contre les Timeres.$\r$\n$\r$\nLe jeu s'installe pour toi seul, dans ton dossier personnel, sans droits d'administrateur. Tes sauvegardes restent dans $\"${SAVE_DIR}$\".$\r$\n$\r$\nVersion ${VERSION}, publiée par ${PUBLISHER}."
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Lancer ${APP_NAME}"
!define MUI_FINISHPAGE_LINK "${APP_URL}"
!define MUI_FINISHPAGE_LINK_LOCATION "${APP_URL}"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "French"

; Propriétés de l'installateur lui-même (Explorateur → Propriétés → Détails).
VIProductVersion "${VERSION}.0"
VIFileVersion "${VERSION}.0"
VIAddVersionKey /LANG=${LANG_FRENCH} "ProductName" "${APP_NAME}"
VIAddVersionKey /LANG=${LANG_FRENCH} "ProductVersion" "${VERSION}"
VIAddVersionKey /LANG=${LANG_FRENCH} "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=${LANG_FRENCH} "CompanyName" "${PUBLISHER}"
VIAddVersionKey /LANG=${LANG_FRENCH} "FileDescription" "Installation de ${APP_NAME} ${VERSION}"
VIAddVersionKey /LANG=${LANG_FRENCH} "LegalCopyright" "© 2026 ${PUBLISHER}"

Section "WordEnd" SecMain
  SetShellVarContext current
  SetOutPath "$INSTDIR"
  File "/oname=${APP_EXE}" "${EXE}"
  File "wordend.ico"
  WriteUninstaller "$INSTDIR\${UNINSTALLER}"

  CreateShortcut "$SMPROGRAMS\WordEnd.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\wordend.ico" 0
  CreateShortcut "$DESKTOP\WordEnd.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\wordend.ico" 0

  ; « Applications et fonctionnalités » (et l'ancien « Ajout/Suppression de programmes »).
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\wordend.ico"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "URLInfoAbout" "${APP_URL}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\${UNINSTALLER}"'
  WriteRegStr HKCU "${UNINSTALL_KEY}" "QuietUninstallString" '"$INSTDIR\${UNINSTALLER}" /S'
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "EstimatedSize" "$0"
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  Delete "$INSTDIR\${APP_EXE}"
  Delete "$INSTDIR\wordend.ico"
  Delete "$INSTDIR\${UNINSTALLER}"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\WordEnd.lnk"
  Delete "$DESKTOP\WordEnd.lnk"
  DeleteRegKey HKCU "${UNINSTALL_KEY}"

  ; Sauvegardes et réglages : gardés par défaut (et en désinstallation silencieuse, /S).
  IfFileExists "${SAVE_DIR}\*.*" 0 saves_done
  MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON1 "Garder tes sauvegardes et tes réglages de WordEnd ?$\r$\n$\r$\nOui : ils restent dans $\"${SAVE_DIR}$\" et une prochaine installation reprendra ta partie.$\r$\nNon : ils sont supprimés." /SD IDYES IDYES saves_done
  RMDir /r "${SAVE_DIR}"
  saves_done:
SectionEnd
