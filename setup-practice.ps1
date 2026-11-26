# 실습 환경 만들기 (이 저장소를 내려받은 폴더에서 실행)
# 사용법 (PowerShell):
#   powershell -ExecutionPolicy Bypass -File .\setup-practice.ps1
#   powershell -ExecutionPolicy Bypass -File .\setup-practice.ps1 -Target C:\orca-gemini-practice
# 하는 일: 01-시작 ~ 09-자동화 폴더를 Target 아래로 복사하고, 폴더마다 git 저장소(첫 저장 지점)를 만든다.
#          Orca 워크트리는 git 저장소에서 동작한다.

param(
    [string]$Target = "D:\orca-gemini-practice",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "git 이 없습니다. Git for Windows 를 먼저 설치하세요: https://git-scm.com/download/win" -ForegroundColor Red
    exit 1
}

function Invoke-Git([string]$Dir, [string[]]$GitArgs) {
    & git -C $Dir -c user.name="orca-practice" -c user.email="practice@example.invalid" -c core.autocrlf=false -c core.safecrlf=false @GitArgs | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') 실패: $Dir" }
}

New-Item -ItemType Directory -Force -Path $Target | Out-Null
$folders = Get-ChildItem -LiteralPath $PSScriptRoot -Directory | Where-Object { $_.Name -match '^\d\d-' } | Sort-Object Name

foreach ($f in $folders) {
    $repo = Join-Path $Target $f.Name
    if (Test-Path $repo) {
        if (-not $Force) {
            Write-Host "[건너뜀] $repo 가 이미 있습니다. 처음 상태로 다시 만들려면 -Force" -ForegroundColor Yellow
            continue
        }
        $keep = Join-Path $repo ".env"
        $saved = if (Test-Path $keep) { Get-Content -Raw -LiteralPath $keep } else { $null }
        Remove-Item -Recurse -Force $repo
    } else { $saved = $null }
    Copy-Item -LiteralPath $f.FullName -Destination $repo -Recurse -Force
    if ($saved) { Set-Content -Path (Join-Path $repo ".env") -Encoding UTF8 -NoNewline -Value $saved }
    Invoke-Git $repo @("init", "-b", "main")
    Invoke-Git $repo @("add", ".")
    Invoke-Git $repo @("commit", "-m", "실습 파일 준비")
    Write-Host "[완료] $repo" -ForegroundColor Green
}

Write-Host ""
Write-Host "실습 환경 준비 끝: $Target" -ForegroundColor Cyan
Write-Host "Orca 에서 각 폴더(예: 01-시작)를 프로젝트로 열어 실습하세요."
