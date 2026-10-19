<#
.SYNOPSIS
    从课程源仓库的 lesson-NN tag 导出每一课的完整项目快照，生成课程索引。

.DESCRIPTION
    对每个 lesson-NN tag：
      1. 用 git archive 导出该 tag 的完整项目到 <Destination>\lesson-NN；
      2. 把该课讲义（源仓库 docs\第N课-*）复制进 lesson-NN\docs；
      3. 生成 lesson-NN\README.md（课号、tag、提交、运行方式、讲义链接）。
    最后生成根目录 README.md 索引。

.PARAMETER SourceRepo
    课程源仓库路径，默认 D:\javawebframework\javawebframework_new。

.PARAMETER Destination
    快照仓库路径，默认 D:\javawebframework\javawebframework-lessons。

.PARAMETER Lessons
    只导出指定课号，例如 -Lessons 3,4。省略则导出全部 tag。

.PARAMETER Force
    覆盖已存在的 lesson-NN 目录；不加时已存在的课会被跳过。

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\export-lessons.ps1 -Force
#>
[CmdletBinding()]
param(
    [string]$SourceRepo = 'D:\javawebframework\javawebframework_new',
    [string]$Destination = 'D:\javawebframework\javawebframework-lessons',
    [int[]]$Lessons,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Text {
    param([string]$Path, [string]$Text)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

function Invoke-Git {
    param([string]$Repo, [string[]]$GitArgs)
    $out = & git -C $Repo @GitArgs 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') 失败：$out" }
    return $out
}

if (-not (Test-Path (Join-Path $SourceRepo '.git'))) {
    throw "源仓库不存在或不是 git 仓库：$SourceRepo"
}
if (-not (Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$allTags = @(Invoke-Git $SourceRepo @('tag', '-l', 'lesson-*')) |
    Where-Object { $_ -match '^lesson-\d+$' } |
    Sort-Object
if ($Lessons) {
    $allTags = $allTags | Where-Object { $Lessons -contains [int]($_ -replace '\D', '') }
}
if (-not $allTags) { throw '没有找到匹配的 lesson-NN tag。' }

$rows = New-Object System.Collections.Generic.List[string]

foreach ($tag in $allTags) {
    $num = [int]($tag -replace '\D', '')
    $nn = '{0:D2}' -f $num
    $target = Join-Path $Destination "lesson-$nn"

    if ((Test-Path $target) -and -not $Force) {
        Write-Host "SKIP  lesson-$nn"
        continue
    }
    if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }

    # 1) 导出该 tag 的完整项目（zip 能正确处理中文路径，tar 会乱码）
    $tmpZip = Join-Path ([System.IO.Path]::GetTempPath()) "lesson-$nn.zip"
    Invoke-Git $SourceRepo @('archive', '--format=zip', '-o', $tmpZip, $tag) | Out-Null
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Expand-Archive -Path $tmpZip -DestinationPath $target -Force
    Remove-Item $tmpZip -Force
    # tag 里可能残留历史讲义，先清掉，统一成"每课只带本课讲义"
    $staleDocs = Join-Path $target 'docs'
    if (Test-Path $staleDocs) { Remove-Item -Path $staleDocs -Recurse -Force }

    # 2) 该课讲义（源仓库 HEAD 的 docs 下，通常比 tag 里新）
    $docRoot = Join-Path $SourceRepo 'docs'
    $docDir = $null
    if (Test-Path $docRoot) {
        $pattern = "^第${num}课-"
        $docDir = Get-ChildItem -Path $docRoot -Directory |
            Where-Object { $_.Name -match $pattern } |
            Select-Object -First 1
    }
    if ($docDir) {
        $title = $docDir.Name -replace '^第\d+课-', ''
        $docDest = Join-Path $target 'docs'
        New-Item -ItemType Directory -Path $docDest -Force | Out-Null
        $docTarget = Join-Path $docDest $docDir.Name
        if (Test-Path $docTarget) {
            Get-ChildItem -Path $docDir.FullName -File |
                Copy-Item -Destination $docTarget -Force
        } else {
            Copy-Item -Path $docDir.FullName -Destination $docDest -Recurse -Force
        }
    } else {
        $title = "第${num}课"
    }

    # 3) 该课的提交信息
    $meta = @(Invoke-Git $SourceRepo @('log', '-1', '--format=%h%x7C%ad', '--date=short', $tag))
    $parts = $meta[0] -split '\|'
    $commit = $parts[0]
    $date = $parts[1]

    $docLink = if ($docDir) { "[docs/$($docDir.Name)/](docs/$($docDir.Name)/)" } else { '（源仓库未提供该课讲义）' }
    $lessonReadme = @"
# 第${nn}课 · $title

- 源仓库存档点：tag ``$tag`` ｜ 提交 ``$commit`` ｜ $date
- 本课讲义：$docLink

## 运行

``````bash
./mvnw spring-boot:run
``````

默认端口 8080。第 7 课起带 H2 内存库；第 19 课起可用 ``docker compose up`` 一键开店（MySQL + MinIO）。

> 本目录由课程源仓库的 ``$tag`` 标签导出，是可独立打开、独立运行的完整项目。
"@
    Write-Text -Path (Join-Path $target 'README.md') -Text $lessonReadme

    $rows.Add("| $nn | $title | [lesson-$nn](lesson-$nn/) | ``$tag`` | $date |")
    Write-Host "OK    lesson-$nn  $title"
}

# 4) 根索引
$table = ($rows | Sort-Object) -join "`n"
$rootReadme = @"
# 南坡小炒 · 20 课项目全集

《Java Web 框架》课程每一课结束时的**完整可运行项目**，一课一个目录，从第 1 课的 Hello World 一路长到第 20 课的 MCP Server。

- 每一课都是独立可运行的项目（源码 + pom + 配置 + 该课讲义），不是零散代码片段
- 想跟哪一课、想回看哪一步，直接进对应目录
- 想比较两课改了什么：``git diff --no-index lesson-01/src lesson-02/src``

## 课程索引

| 课 | 标题 | 目录 | 存档 tag | 日期 |
|---|---|---|---|---|
$table

## 怎么用

``````bash
cd lesson-09          # 进入想看的课
./mvnw spring-boot:run
``````

然后打开 <http://localhost:8080>。第 7 课起有 H2 控制台（``/h2-console``），第 19 课起可 ``docker compose up`` 一键开店。

## 重新生成

``````powershell
# 全部重新导出（覆盖已有目录）
powershell -ExecutionPolicy Bypass -File .\tools\export-lessons.ps1 -Force

# 只补某一课
powershell -ExecutionPolicy Bypass -File .\tools\export-lessons.ps1 -Lessons 21
``````

脚本从课程源仓库的 ``lesson-NN`` tag 导出快照，并复制对应讲义、重写本索引。

## 说明

- 讲义全文（含全部课程文档）在课程主仓库的 ``docs/`` 下；本仓库每课只带该课的 3 篇讲义。
- 密钥不落盘：``NANPO_AI_KEY``、``NANPO_JWT_SECRET`` 走环境变量，仓库里只有占位默认值。
"@
Write-Text -Path (Join-Path $Destination 'README.md') -Text $rootReadme

Write-Host ''
Write-Host "完成：$Destination"
