FROM microsoft/windowsservercore

# $ProgressPreference: https://github.com/PowerShell/PowerShell/issues/2138#issuecomment-251261324
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN $newPath = ('C:\telegraf;{0}' -f $env:PATH); \
    Write-Host ('Updating PATH: {0}' -f $newPath); \
    [Environment]::SetEnvironmentVariable('PATH', $newPath, [EnvironmentVariableTarget]::Machine);

ENV TELEGRAF_VERSION 1.4.0
RUN $url = ('https://dl.influxdata.com/telegraf/releases/telegraf-{0}_windows_amd64.zip' -f $env:TELEGRAF_VERSION); \
    Write-Host ('Downloading {0} ...' -f $url); \
    Invoke-WebRequest -Uri $url -OutFile 'telegraf.zip'; \
    $sha256 = 'f23501f430c6beb957266cc7e331fe3f45bc9bf0311176c6646c8e01b900d9db'; \
    Write-Host ('Verifying sha256 ({0}) ...' -f $md5); \
    if ((Get-FileHash telegraf.zip -Algorithm sha256).Hash -ne $md5) { \
        Write-Host 'FAILED!'; \
        exit 1; \
    }; \
    Write-Host 'Expanding ...'; \
    Expand-Archive telegraf.zip -DestinationPath C:\; \
    Write-Host 'Removing ...'; \
    Remove-Item telegraf.zip -Force; \
    Write-Host 'Complete.';

COPY entrypoint.ps1 C:\telegraf/entrypoint.ps1
WORKDIR C:\telegraf
ENTRYPOINT ["telegraf.exe"]
