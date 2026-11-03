# Servidor Webhook e Terminal Receptor para Cadastro PF (Lovable / Windows)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$port = 5000
$prefix = "http://localhost:$port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "[ERRO] Nao foi possivel iniciar na porta $port. Porta ocupada ou sem permissao." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
    exit 1
}

Start-Process "http://localhost:$port/"

Clear-Host
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "     TERMINAL DE CADASTRO PF - INTEGRACAO LOVABLE (WINDOWS)      " -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host (" [OK] Servidor Web ativo em:    " + $prefix) -ForegroundColor Yellow
Write-Host (" [OK] Formulario aberto em:     " + $prefix) -ForegroundColor White
Write-Host (" [OK] Receptor Webhook (POST):  " + $prefix + "api/cadastro") -ForegroundColor Green
Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " Aguardando cadastros... (Deixe esta janela aberta)" -ForegroundColor Gray
Write-Host " Pressione Ctrl+C para finalizar." -ForegroundColor DarkGray
Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan

$contador = 0
$htmlPath = Join-Path $PSScriptRoot "formulario_exemplo_lovable.html"

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

        if ($request.HttpMethod -eq "GET" -and ($request.Url.AbsolutePath -eq "/" -or $request.Url.AbsolutePath -eq "/index.html")) {
            if (Test-Path $htmlPath) {
                $bytes = [System.IO.File]::ReadAllBytes($htmlPath)
                $response.ContentType = "text/html; charset=utf-8"
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 404
            }
            $response.Close()
            continue
        }

        if ($request.HttpMethod -eq "GET" -and $request.Url.AbsolutePath -eq "/health") {
            $response.ContentType = "application/json; charset=utf-8"
            $msg = '{"status":"online"}'
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        if ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/api/cadastro") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
            $body = $reader.ReadToEnd()
            $reader.Close()

            $contador++
            $timestamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

            Write-Host ""
            Write-Host "------------------------------------------------------------------" -ForegroundColor Magenta
            Write-Host " [NOVO CADASTRO RECEBIDO] Protocolo #$contador - $timestamp" -ForegroundColor Yellow
            Write-Host "------------------------------------------------------------------" -ForegroundColor Magenta

            try {
                $dados = $body | ConvertFrom-Json

                if ($dados.nome)           { Write-Host " Nome Completo:   $($dados.nome)" -ForegroundColor White }
                if ($dados.cpf)            { Write-Host " CPF:             $($dados.cpf)" -ForegroundColor Cyan }
                if ($dados.dataNascimento) { Write-Host " Nascimento:      $($dados.dataNascimento)" -ForegroundColor White }
                if ($dados.email)          { Write-Host " E-mail:          $($dados.email)" -ForegroundColor Yellow }
                if ($dados.telefone)       { Write-Host " Telefone:        $($dados.telefone)" -ForegroundColor White }

                $endereco = @()
                if ($dados.logradouro) { $endereco += $dados.logradouro }
                if ($dados.bairro)     { $endereco += $dados.bairro }
                if ($dados.cidade)     { $endereco += $dados.cidade }
                if ($dados.uf)         { $endereco += $dados.uf }
                if ($dados.cep)        { $endereco += "CEP: " + $dados.cep }

                if ($endereco.Count -gt 0) {
                    $endStr = $endereco -join ", "
                    Write-Host " Endereco:        $endStr" -ForegroundColor Gray
                }

                if ($dados.observacoes) {
                    Write-Host " Observacoes:     $($dados.observacoes)" -ForegroundColor DarkYellow
                }

                $logPath = Join-Path $PSScriptRoot "cadastros_recebidos.json"
                $logEntry = [PSCustomObject]@{
                    Protocolo = $contador
                    Data = $timestamp
                    Dados = $dados
                }
                $historico = @()
                if (Test-Path $logPath) {
                    try { $historico = Get-Content $logPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $historico = @() }
                }
                $historico = @($historico) + $logEntry
                $historico | ConvertTo-Json -Depth 5 | Set-Content $logPath -Encoding UTF8
            } catch {
                Write-Host " Erro ao interpretar JSON:" -ForegroundColor Red
                Write-Host " $body" -ForegroundColor DarkRed
            }

            Write-Host "------------------------------------------------------------------" -ForegroundColor Magenta

            $response.ContentType = "application/json; charset=utf-8"
            $response.StatusCode = 200
            $resPayload = [PSCustomObject]@{
                sucesso = $true
                mensagem = "Cadastro recebido com sucesso no Terminal Windows!"
                protocolo = $contador
                recebidoEm = $timestamp
            } | ConvertTo-Json

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($resPayload)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
        } else {
            $response.StatusCode = 404
            $msg = '{"erro":"Rota nao encontrada."}'
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "`n[ENCERRADO] Terminal finalizado." -ForegroundColor Yellow
}
