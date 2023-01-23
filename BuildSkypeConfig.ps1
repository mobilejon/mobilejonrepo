New-Item C:\temp\SkypeSettings.xml -ItemType File -Force
Set-Content C:\temp\SkypeSettings.xml '<SkypeSettings>
  <AutoScreenShare>1</AutoScreenShare>
  <HideMeetingName>1</HideMeetingName>
  <AutoExitMeetingEnabled>true</AutoExitMeetingEnabled>
  <AudioRenderDefaultDeviceVolume>70</AudioRenderDefaultDeviceVolume>
  <AudioRenderCommunicationDeviceVolume>30</AudioRenderCommunicationDeviceVolume>
  <UserAccount>
    <SkypeSignInAddress></SkypeSignInAddress>
    <ExchangeAddress></ExchangeAddress>
    <Password></Password>
    <ModernAuthEnabled>true</ModernAuthEnabled>
  </UserAccount>
  <TeamsMeetingsEnabled>True</TeamsMeetingsEnabled>
  <SfbMeetingEnabled>False</SfbMeetingEnabled>
  <IsTeamsDefaultClient>true</IsTeamsDefaultClient>
  <WebExMeetingsEnabled>False</WebExMeetingsEnabled>
  <ZoomMeetingsEnabled>true</ZoomMeetingsEnabled>
  <BluetoothAdvertisementEnabled>true</BluetoothAdvertisementEnabled>
  <AutoAcceptProximateMeetingInvitations>false</AutoAcceptProximateMeetingInvitations>
  <CortanaWakewordEnabled>false</CortanaWakewordEnabled>
  <DualScreenMode>0</DualScreenMode>
  <DuplicateIngestDefault>false</DuplicateIngestDefault>
  <DisableTeamsAudioSharing>true</DisableTeamsAudioSharing>
  <SendLogs>
    <EmailAddressForLogsAndFeedback></EmailAddressForLogsAndFeedback>
    <SendLogsAndFeedback>True</SendLogsAndFeedback>
  </SendLogs>
    <Theming>
    <ThemeName>Custom</ThemeName>
    <CustomThemeImageUrl>wallpaper.jpg</CustomThemeImageUrl>
    <CustomThemeColor>
    <RedComponent>1</RedComponent>
    <GreenComponent>120</GreenComponent>
    <BlueComponent>199</BlueComponent>
    </CustomThemeColor>
    </Theming>
</SkypeSettings>
'
$Username = Get-Content C:\Users\Skype\AppData\Local\Packages\Microsoft.SkypeRoomSystem_8wekyb3d8bbwe\LocalCache\Roaming\Microsoft\Teams\desktop-config.json
$JSONObject = ConvertFrom-Json -InputObject $Username
$Username = $JSONObject.upnWindowUserUpn
$Username | Out-File C:\temp\username.txt
$SkypeSettings = Get-Content C:\temp\SkypeSettings.xml
$SkypeSettings = $SkypeSettings -replace "<ExchangeAddress></ExchangeAddress>", ("<ExchangeAddress>" + $Username + "</ExchangeAddress>") -replace "<SkypeSignInAddress></SkypeSignInAddress>", ("<SkypeSignInAddress>" + $Username + "</SkypeSignInAddress>")
$SkypeSettings | Out-File C:\temp\SkypeSettings.xml -Force
