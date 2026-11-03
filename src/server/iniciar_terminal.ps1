# Servidor Webhook e Engine da Corrida dos Bots (Autódromo)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$port = 5000
$prefix = "http://localhost:$port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "[ERRO] Não foi possível iniciar na porta $port." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
    exit 1
}

$rootPath = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$clientPath = Join-Path $rootPath "src\client\index.html"

Start-Process "http://localhost:$port/"

Clear-Host
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "       AUTODROMO BOT RACE - TERMINAL EM CAMADAS (PF LOVABLE)     " -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host (" [OK] Web App & Autodromo:   " + $prefix) -ForegroundColor Yellow
Write-Host (" [OK] Endpoint API POST:     " + $prefix + "api/cadastro") -ForegroundColor Green
Write-Host (" [OK] Endpoint Corrida GET:  " + $prefix + "api/corrida/status") -ForegroundColor White
Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " Limite por rodada: 3 Pilotos (Bots). Aguardando cadastros..." -ForegroundColor Gray
Write-Host " Pressione Ctrl+C para encerrar." -ForegroundColor DarkGray
Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan

$pilotos = [System.Collections.Generic.List[PSCustomObject]]::new()
$coresBots = @("Vermelho Turbo (#ef4444)", "Azul Relampago (#3b82f6)", "Amarelo Trovao (#eab308)")
$corridasHistorico = [System.Collections.Generic.List[PSCustomObject]]::new()

function Executar-Corrida-Terminal($participantes) {
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Yellow
    Write-Host "     🏁 LUZ VERDE! INICIANDO CORRIDA DOS BOTS NO AUTODROMO 🏁   " -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Yellow

    $bots = @()
    for ($i = 0; $i -lt $participantes.Count; $i++) {
        $bots += [PSCustomObject]@{
            Id = $i + 1
            Nome = $participantes[$i].nome
            Cpf = $participantes[$i].cpf
            Carro = $coresBots[$i]
            Distancia = 0
            Velocidade = 0
            Tempo = 0
        }
    }

    $distanciaPista = 100
    $vencedor = $null
    $rodada = 1

    while (-not $vencedor) {
        Start-Sleep -Milliseconds 450
        Write-Host ("`n--- Volta $rodada do Autodromo ---") -ForegroundColor DarkGray
        
        foreach ($b in $bots) {
            $aceleracao = Get-Random -Minimum 12 -Maximum 28
            $b.Distancia += $aceleracao
            $barra = [Math]::Min(30, [int]($b.Distancia * 30 / $distanciaPista))
            $trilha = ("=" * $barra) + ">"
            
            Write-Host ("🏎️  Bot #{0} [{1}]: {2} ({3}m)" -f $b.Id, $b.Nome, $trilha, $b.Distancia) -ForegroundColor White

            if ($b.Distancia -ge $distanciaPista -and -not $vencedor) {
                $vencedor = $b
            }
        }
        $rodada++
    }

    Write-Host ""
    Write-Host "🏆 ============================================================== 🏆" -ForegroundColor Yellow
    Write-Host ("   CAMPEAO DO GP: Bot #{0} - {1} ({2})!" -f $vencedor.Id, $vencedor.Nome, $vencedor.Carro) -ForegroundColor Green
    Write-Host "🏆 ============================================================== 🏆" -ForegroundColor Yellow
    Write-Host ""
    
    return $vencedor
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        # Servir Frontend
        if ($request.HttpMethod -eq "GET" -and ($request.Url.AbsolutePath -eq "/" -or $request.Url.AbsolutePath -eq "/index.html")) {
            if (Test-Path $clientPath) {
                $bytes = [System.IO.File]::ReadAllBytes($clientPath)
                $response.ContentType = "text/html; charset=utf-8"
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 404
            }
            $response.Close()
            continue
        }

        # Status da Corrida / Pilotos
        if ($request.HttpMethod -eq "GET" -and $request.Url.AbsolutePath -eq "/api/corrida/status") {
            $response.ContentType = "application/json; charset=utf-8"
            $statusObj = [PSCustomObject]@{
                pilotosCadastrados = $pilotos.Count
                limite = 3
                pilotos = $pilotos
                prontoParaCorrida = ($pilotos.Count -eq 3)
            } | ConvertTo-Json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($statusObj)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        # Resetar Grid
        if ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/api/corrida/reset") {
            $pilotos.Clear()
            $response.ContentType = "application/json; charset=utf-8"
            $msg = '{"status":"Grid resetado com sucesso! Pronto para nova rodada de 3 pilotos."}'
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            Write-Host "`n[GRID REINICIADO] O Autodromo esta livre para mais 3 pessoas." -ForegroundColor Cyan
            continue
        }

        # Cadastro PF
        if ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/api/cadastro") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
            $body = $reader.ReadToEnd()
            $reader.Close()

            $timestamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

            if ($pilotos.Count -ge 3) {
                $response.StatusCode = 400
                $response.ContentType = "application/json; charset=utf-8"
                $errPayload = [PSCustomObject]@{
                    sucesso = $false
                    mensagem = "Grid completo! Limite maximo de 3 pilotos atingido. Faca o reset da corrida para nova rodada."
                } | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($errPayload)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.Close()
                continue
            }

            try {
                $dados = $body | ConvertFrom-Json
                $botNumero = $pilotos.Count + 1
                $dados | Add-Member -MemberType NoteProperty -Name "botId" -Value $botNumero -Force
                $dados | Add-Member -MemberType NoteProperty -Name "botCarro" -Value $coresBots[$botNumero - 1] -Force
                $dados | Add-Member -MemberType NoteProperty -Name "dataRegistro" -Value $timestamp -Force

                $pilotos.Add($dados)

                Write-Host ""
                Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
                Write-Host (" [PILOTO INSCRITO #{0}/3] {1}" -f $botNumero, $dados.nome) -ForegroundColor Yellow
                Write-Host (" Bot Atribuido: {0}" -f $coresBots[$botNumero - 1]) -ForegroundColor Green
                Write-Host (" CPF:           {0}" -f $dados.cpf) -ForegroundColor White
                Write-Host (" E-mail:        {0}" -f $dados.email) -ForegroundColor White
                Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan

                $corridaDisparada = $false
                $vencedorBot = $null

                # Se completou 3 pilotos, dispara a corrida dos bots!
                if ($pilotos.Count -eq 3) {
                    Write-Host "`n🚀 3 PILOTOS REGISTRADOS! O GRID ESTA COMPLETO!" -ForegroundColor Green
                    $vencedorBot = Executar-Corrida-Terminal ($pilotos.ToArray())
                    $corridaDisparada = $true
                }

                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 200
                $resPayload = [PSCustomObject]@{
                    sucesso = $true
                    mensagem = "Piloto $botNumero/3 registrado com sucesso!"
                    pilotoNumero = $botNumero
                    restantes = (3 - $botNumero)
                    corridaIniciada = $corridaDisparada
                    vencedor = $vencedorBot
                } | ConvertTo-Json

                $buffer = [System.Text.Encoding]::UTF8.GetBytes($resPayload)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.Close()

            } catch {
                Write-Host " Erro ao processar cadastro:" -ForegroundColor Red
                Write-Host " $body" -ForegroundColor DarkRed
                $response.StatusCode = 500
                $response.Close()
            }
        }
        else {
            $response.StatusCode = 404
            $response.Close()
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "`n[ENCERRADO] Terminal finalizado." -ForegroundColor Yellow
}
